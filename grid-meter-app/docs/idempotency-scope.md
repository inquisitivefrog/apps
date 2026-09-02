# grid-meter-app — Idempotency scope: `POST /api/v1/readings`

**Status (2026-09-02): implemented and live-verified. Companion work was
declared closed twice, and was wrong both times** — see "Implementation
results" near the end of this doc for the full account, including two
unrelated regressions found and fixed along the way. Built exactly as
designed below — required `Idempotency-Key` header, Redis fast path, DB
constraint as the real guarantee — with 70/70 tests green and live
confirmation against the real running stack that the two layers divide
labor correctly (Redis caught the one live duplicate test before Kafka
ever saw it). JMeter's 5 load-test plans plus the shared `warmup.jmx`
fragment got `${__UUID()}` added to their `HeaderManager`s and were
live-verified via `smoke-test.sh` at 0.00% errors. **That first
closure note was itself wrong**: it covered JMeter and Bruno — the two
clients this doc's own design section named explicitly — but missed 6
more shell scripts across `load-tests/` and `scripts/` that also POST
directly to `/readings` and were never tracked as "clients of this
endpoint" the way JMeter/Bruno were. Found only because actually
running one of them (`load-tests/kafka-ha-demo.sh`, for an unrelated
Kafka RTO fix) hit the `400` directly. All 6 are now fixed too — see
"Implementation results" for the specific list and the general lesson
this is worth taking away.

**Earlier status, preserved for the record**: the motivating gap was
independently reconfirmed before this was built. A Postgres Stage 7
re-run (executed after unrelated Patroni bootstrap-hook work,
specifically to confirm that work hadn't regressed anything) reproduced
the identical phantom-success pattern a second time, on a fresh run —
26 client-reported successes against 27 real database rows. This wasn't
a repeat report of the same original finding; it confirmed the gap was
still live and current, not something the intervening Postgres work
happened to fix as a side effect. See `docs/postgres-ha-scope.md`'s
"Stage 7 re-verification" section for the full account.

## Why this doc exists

Found during Postgres HA Stage 7's application-level primary-kill
re-test (`docs/postgres-ha-scope.md`), not invented speculatively: one
run showed a write that committed on the server while its response
never reached the client (the database ended up with one more row than
the client counted as a successful write — almost certainly the
connection being severed mid-response by the container being stopped).
That finding was deliberately **not fixed inside the Postgres HA
pass** — it's a real API-design gap, not an HA-specific one (any
transient network interruption between client and API could produce the
identical ambiguity, HA or not), and belongs in this endpoint's own
contract rather than absorbed into an already-large HA doc. This is that
decision, following the same "check in on structural choices before
committing to them" convention `CLAUDE.md` already asks for.

## The actual risk, stated precisely

`POST /api/v1/readings` has no way for a client to distinguish "my
request never reached the server" from "my request succeeded but the
response was lost." A client that blindly retries on any error/timeout
therefore risks creating a duplicate reading for an event that already
landed — not a data-loss risk (the opposite: a data-*inflation* risk).
Readings are already immutable by design (no `PUT /readings/{id}`,
per `api-and-data-model.md`), which is exactly the situation an
idempotency key exists to protect: a client should be able to safely
retry the identical logical event any number of times and have it count
once.

**Worth weighing honestly against this project's own minimal-scope
ethos, the same way `resilience-scope.md`'s outbox pattern was
weighed and ultimately retired** — is this worth building for an app
whose readings are synthetic, with no billing or downstream consumer?
The two cases are not the same shape, though, and the difference is
why this one gets built where the outbox didn't:

- The outbox protected against **data loss** during a rare, bounded
  outage window (exceeding `delivery.timeout.ms`) — retired because
  losing a synthetic reading has no real consequence, and a notice/alert
  already records that it happened.
- This protects against **silent duplication** from an ordinary
  transient network hiccup — a far more common trigger than a full
  outage, and one that visibly corrupts search results, counts, and
  any future aggregation, rather than quietly doing nothing. It's also
  a basic correctness property any real interviewer would reasonably
  expect from an ingestion API, not HA-specific machinery.

**Decision: build it, but keep it minimal** — a client-supplied key and
a single unique constraint, not a general-purpose exactly-once
processing framework.

## Design decision: enforcement point, given the async write path

`architecture.md`'s data flow means `POST /readings` doesn't write to
Postgres synchronously — Controller → Service publishes to Kafka, and a
separate consumer performs the actual Postgres insert (and the Redis
cache write). That gives two different points where a duplicate could
be caught, and the design has to be explicit about which one is doing
the real work:

- **(a) A Redis fast-path check before publishing to Kafka** — cheap,
  avoids republishing a duplicate event to Kafka at all, and returns a
  fast, cache-backed answer to a resubmission. Not sufficient alone: a
  narrow race (two retries arriving close enough together) or a Redis
  outage window could let a duplicate event through to Kafka regardless.
- **(b) A unique constraint on the actual Postgres insert**, enforced by
  the async consumer — the only point that can *guarantee* a second row
  never exists, independent of timing, Redis availability, or how close
  together two retries land.

**Decision: build both, but understand them as different jobs, not two
attempts at the same guarantee.** (b) is the real correctness property
and the one this doc actually requires. (a) is a latency/Kafka-noise
optimization on top of it — skip it if it fails, don't route around
(b)'s constraint if it disagrees, and don't spend time perfecting (a) at
the expense of shipping (b).

## Concrete design

**Key transport: `Idempotency-Key` HTTP header, not a body field.**
Matches the widely-recognized Stripe/PayPal-style convention, keeps a
transport/retry-safety concern out of the `Reading` domain model (same
reasoning that already keeps JWT auth header-based rather than a body
field), and requires no change to the `Reading` entity's own shape.
Client-generated (a UUID is the expected value, but the server doesn't
need to parse or validate its format beyond "non-empty string, under a
sane length").

**Required, not optional.** An optional header just reintroduces the
exact ambiguity this doc exists to close for any client that doesn't
bother sending it. Missing header → `400`, before touching Kafka or
Redis. This is a breaking API change — `docs/api-and-data-model.md`'s
own contract needs updating (see "API contract change" below), and so
does every client: JMeter's load-test plans, the Bruno collection, and
the frontend (though the frontend never writes readings directly per
`architecture.md`'s "read-only Readings page" note — ingestion is
API/JMeter-only, so this is really just JMeter and Bruno in practice).

**(b) — the real guarantee.** New column `idempotency_key` on
`readings` (`VARCHAR`, not nullable once this ships), unique index,
added via `V7__add_idempotency_key_to_readings.sql` — confirmed against
the real migration directory, not assumed: `V1`–`V4` are the original
meters/readings/users/customers tables, `V5` and `V6` are the outbox
pattern's own full lifecycle (`create_reading_outbox_table` then
`drop_reading_outbox_table`, matching `resilience-scope.md`'s account of
building it, measuring it, and retiring it), leaving `V7` as the
genuinely next-free version as of this doc. Still worth re-confirming
against the real directory at implementation time if anything else
lands in between. The idempotency key travels with
the event through Kafka (part of the published message, not looked up
separately) so the consumer has it at insert time. On a unique-
constraint violation during insert: log it and discard — this is an
already-processed duplicate, not an error, and must never crash the
consumer or dead-letter the message.

**(a) — the fast path.** Before publishing to Kafka, the Service layer
issues `SET idempotency:{key} 1 NX EX 86400` against Redis (a 24-hour
TTL, matching typical Stripe-style windows — no session-length
justification needed here, just "long enough that a client's own retry
logic has certainly given up by then").

- `SETNX` succeeds → new request, publish to Kafka normally, return
  `201` with the submitted reading's data (same as today's behavior;
  this doc doesn't change what a first-time success looks like).
- `SETNX` fails (key already seen) → **do not republish to Kafka.**
  Return `201` with the same echoed reading data (`meterId`,
  `readingTimestamp`, `value`) the client originally submitted. This
  doc does **not** attempt to replay the exact original response
  byte-for-byte (e.g. re-querying Postgres for the real persisted `id`)
  — the guarantee that matters is "no second row," which (b) already
  provides regardless of what this fast path does. Byte-identical
  response replay is a real future hardening step, explicitly deferred
  below, not required for this pass.
- **Redis unavailable at ingest time → fail open, not closed.** Skip the
  fast-path check entirely and publish to Kafka as normal. This matches
  this project's existing Redis-independent write-path architecture
  (Postgres/Kafka durability was never conditioned on Redis being up)
  and the same redo-path reasoning already applied to the outbox
  decision: temporarily losing the fast-path optimization during a
  Redis outage is an acceptable, bounded cost; blocking ingestion on
  Redis's availability would not be.

## API contract change — `docs/api-and-data-model.md`

Add to the `POST /readings` row's Notes and to a new subsection near the
existing Auth section:

```markdown
### Idempotency

`POST /readings` requires an `Idempotency-Key` header (client-generated,
a UUID is recommended but not enforced beyond non-empty). A request
missing this header is rejected with `400` before any other processing.

Resubmitting the same key returns the original `201` response without
creating a second reading — safe to retry on any ambiguous failure
(timeout, connection reset, 5xx) using the same key. A different key
is always treated as a new, distinct reading, even if the body is
identical to a prior request.
```

## Testing implications

Following `testing-strategy.md`'s existing layering — each layer earns
its keep by testing something the layer below it can't:

**Unit (Service layer, mocked Kafka producer + Redis client):**
- New key, `SETNX` succeeds → producer is called once, `201` returned.
- Duplicate key, `SETNX` fails → producer is **not** called again;
  `201` returned with the echoed request data.
- Missing `Idempotency-Key` header → `400`, producer and Redis client
  both never invoked.
- Redis client throws/times out on `SETNX` → producer is still called
  (fail-open behavior) — this is the test that actually proves the
  degradation mode works, not just that it's coded.

**Component (real Postgres/Kafka/Redis via Testcontainers):**
- Two identical `POST` requests, same key, sent back-to-back → after
  both requests and the async consumer settle (poll via Awaitility,
  never a fixed sleep, per this project's own standing lesson), exactly
  one row exists in `readings`.
- Two requests with the **same key but a different body** (e.g.
  different `value`) — decide and test the defined behavior explicitly
  rather than leave it implicit. **Recommendation for this pass: return
  the original result regardless of body mismatch** (matches Stripe's
  own behavior; a stricter "reject with `409` if the replayed body
  doesn't match the first request's body" is real, well-known hardening
  but explicitly deferred below, not required now).
- **Concurrent identical requests** (two threads/connections submit the
  same key at the same instant) → confirms (b)'s DB-level constraint is
  the actual backstop, independent of whatever (a)'s Redis check did
  under the race — this is the test that validates the two-layer design
  is layered correctly, not just that each layer works in isolation.
- **Redis stopped mid-test** (via Testcontainers) → ingestion still
  succeeds during the outage (fail-open), and a genuine retry with the
  same key *during* that outage window still produces only one row once
  Redis comes back and the consumer processes both Kafka messages —
  proving (b) alone is sufficient even with (a) completely unavailable.

**API (REST Assured / Bruno):**
- Black-box: `POST /readings` twice with the same `Idempotency-Key` and
  body → both return `201`; a follow-up `GET /readings?meterId=X` shows
  exactly one row.
- `POST /readings` with no `Idempotency-Key` header → `400` with a
  clear message, matching the existing `ApiError` shape.

**Load (JMeter) — the test that actually matters most, given where this
gap was found:**
- Extend `load-tests/`'s existing plans (or add a new one) with a
  configurable percentage of "retried" requests — same
  `Idempotency-Key`, sent twice, simulating a client that times out and
  retries — and assert final row count matches the count of logically
  distinct readings sent, not the raw request count.
- **Directly tie this back to Postgres Stage 7's own primary-kill test
  script.** That script already generates real load against
  `POST /readings` while killing the primary; extending it to send an
  `Idempotency-Key` and automatically retry with the *same* key on any
  client-observed failure would turn that exact chaos scenario into the
  real proof this fix closes the gap it was found by — the same test
  that discovered the problem becomes the test that confirms it's
  fixed, rather than a new, separately-argued test standing in for it.

## Implementation results (2026-09-02): built and live-verified, matching the design as written

Built exactly as specified above — required `Idempotency-Key` header,
Redis `SETNX` fast path (fail-open on Redis errors), the unique DB
constraint as the actual guarantee, duplicate inserts discarded without
crashing the Kafka consumer.

**Test results, reported by layer per this doc's own testing section
above, not as one undifferentiated "tests pass":**

- **Unit** (`ReadingServiceIdempotencyTest`, 3 tests): new-key publishes
  normally; duplicate-key skips republishing to Kafka; Redis throwing
  on the `SETNX` call still results in the event being published
  (fail-open confirmed, not just coded).
- **Component** (`ReadingIdempotencyComponentTest`, real
  Postgres/Kafka/Redis via Testcontainers, 2 tests): a duplicate request
  produces exactly one row; concurrent identical requests confirm the
  DB constraint — not the Redis check — is the actual backstop, per this
  doc's own emphasis on testing that the two layers are doing different
  jobs, not redundant copies of the same one.
- **Black-box** (`ReadingApiTestBase`, 2 new tests): missing header →
  `400`; duplicate key → both requests `201`, one row.
- **Full suite, after fixing the unrelated regression below**: 70/70
  green — not just the new tests passing in isolation.

**Live-verified against the real running stack** (Patroni cluster,
Kafka cluster, Sentinel-backed Redis — not a test double for any of
them): `V7` migration applied cleanly; missing header correctly returns
`400`; a genuine duplicate submission returns `201` twice with exactly
one row in Postgres; and the application log confirms the **Redis fast
path caught the duplicate before it ever reached Kafka** — the DB
constraint never had to fire, which is exactly the intended division of
labor between the two layers, observed actually happening rather than
assumed from the design doc.

**A pre-existing, unrelated regression found and fixed along the way,
flagged and confirmed before fixing rather than silently patched**:
Redis's own Stage 6 cutover (`docs/redis-ha-scope.md`, commit `1cbf040`,
"Cut app over to Sentinel-aware Redis client") had silently broken every
component test's Redis connectivity. Root cause: once
`spring.data.redis.sentinel.master` is non-null, Spring Boot's
autoconfiguration always builds a Sentinel-mode connection, ignoring
`ComponentTestSupport`'s attempt to override `spring.data.redis.host`/
`port` toward the test's standalone Testcontainers Redis — so every
component test's Redis write had been trying, and failing, to reach a
Sentinel at `localhost:26379`, which doesn't exist in the test
environment. **This had gone unnoticed since that commit landed** —
exactly the shape of gap `docs/ha-scope.md`'s standing lesson already
tracks (a change made for one purpose silently breaking something else
with no visibility into the dependency), just surfacing in the test
suite this time rather than production traffic. Fixed via a
`!test`-profile gate in `application.yml`, then **confirmed live
afterward that production Sentinel behavior was completely
undisturbed** by the fix — the right verification step, since a
test-scoped fix that leaks into production behavior would be a worse
outcome than the regression it was fixing.

**Companion work, per this doc's own "required companion work" note**:
`docs/api-and-data-model.md` updated with the new Idempotency section
(matching the contract block specified above), and Bruno's
`ingest-reading.bru` updated to generate a per-run unique key (matching
its existing `serialNumber` pattern) — full collection re-verified
clean (15/15 requests, 27/27 assertions) against the live stack.

~~**Explicitly deferred, by deliberate choice, not oversight**: JMeter's
8 load-test plans (steady-state, ramp-up, both spike variants, soak,
provisioning) all still POST to `/readings` without the new header and
will now fail with `400`. Fixing them requires per-request unique-key
generation, not a static header value — real, non-trivial work, checked
in on explicitly before deferring rather than left as a silent gap. This
is the one piece of "required companion work" not yet done; the load
tests should not be assumed runnable until this lands.~~

**Resolved (2026-09-02).** `${__UUID()}` added to the shared
`HeaderManager` in all 7 affected files (steady-state, ramp-up,
rapid-spike, gentle-spike, soak, `misconfigured-burst.jmx`, and the
shared `warmup.jmx` fragment — `provision-meters.jmx` needed no change,
since it only ever `POST`s to `/meters`). **Confirmed to re-evaluate per
request, not once per thread** — the detail that actually mattered here,
since a thread-scoped or static key would have silently defeated the
fix by producing colliding keys across a thread's own repeated requests
(or across threads, in the static case), matching how `${__Random}`/
`${__time}` already behave in the same sampler bodies rather than
introducing a new evaluation pattern. Live-verified via
`smoke-test.sh`: all 5 named profiles clean at `0.00%` errors, plus a
direct run of `misconfigured-burst.jmx` (which has its own
self-contained `setUp` — login + provisioning — separate from the
shared profiles) also clean. `load-tests/README.md` updated to document
the new required header.

~~**No companion work remains outstanding from this doc's scope.**~~

**Wrong (2026-09-02) — a second, larger gap in the same shape, found
after this doc had already declared companion work closed twice.**
While validating an unrelated Kafka RTO fix, running
`load-tests/kafka-ha-demo.sh` hit an immediate `400` on its very first
`POST /readings` call. A repo-wide `grep -rl "readings"` (not scoped to
`load-tests/`, per a Chat review that asked directly whether the first,
`load-tests/`-scoped sweep had actually been exhaustive) found **6 more
scripts** that POST directly to `/readings` and had never been touched:
`load-tests/kafka-ha-demo.sh`, `load-tests/kafka-acks-gap-repro.sh`,
`load-tests/kafka-leader-failover-rto.sh`,
`load-tests/postgres-app-primary-failure-test.sh`,
`load-tests/redis-app-primary-failure-test.sh`, and
`scripts/verify-bruno-collection.sh`. All 6 fixed the same way (a fresh
`Idempotency-Key: $(python3 -c 'import uuid; print(uuid.uuid4())')`
header per call site, matching Bruno's own pattern) and reconfirmed live
— `kafka-ha-demo.sh` run twice end to end (all 3 scenarios, exit 0 both
times) and `verify-bruno-collection.sh` run to a clean "All checks
passed."

**Worth naming precisely why this survived one whole closure pass
already, since it's a real, generalizable gap-shape and not just a
missed script**: the original companion-work sweep was scoped to
*known, documented API clients* — JMeter and Bruno, the two named
explicitly in this doc's own "Required, not optional" section above and
in `load-tests/README.md`. These 6 scripts are ad hoc chaos/investigation
tooling that accumulated across this project's whole HA testing effort
without ever being tracked as "a client of `POST /readings`" in that
same sense — nobody was maintaining a list they'd have been checked
against. **A breaking API change's companion-work audit needs to be
scoped to "everything in the repo that actually calls this endpoint"
(a grep), not to "the clients we remember/have documented as clients"
— those are different sets, and the gap between them is exactly where
this hid, twice.** This is close kin to
`docs/cross-project-lessons.md`'s existing entry about checking
cross-pass references before retiring shared infrastructure (a change
in one place, silent blast radius across scripts nobody was tracking as
dependents) — same shape, a breaking API change instead of a retired
container this time.

**A second, unrelated bug caught fixing the first**:
`scripts/verify-bruno-collection.sh`'s own `readings/Get Reading` check
had no wait for the async Kafka→Postgres write before asserting —
pre-existing, not something today's fix introduced, just surfaced by
actually running the script rather than trusting the diff. Fixed with a
poll loop (up to 20 × 0.5s) for the real condition, matching this
project's own standing "poll for the actual readiness condition, don't
assume a fixed delay" lesson (`docs/testing-strategy.md`).

## Explicitly deferred

- **Byte-identical response replay** (returning the exact original
  `id`/timestamps on a duplicate-key hit, not just echoed request data)
  — real hardening, not needed for this app's actual scope; note if
  revisited.
- **Strict body-match enforcement on key reuse** (`409` if a resubmitted
  key's body differs from the first request associated with it) — a
  well-known stricter variant of this pattern; deferred in favor of the
  looser "always return the original result" behavior for this pass.
- **Idempotency keys on other mutating endpoints** (`POST`/`PUT
  /meters`) — this doc is scoped to the endpoint the actual finding
  came from; meters CRUD wasn't implicated and shouldn't be bundled in
  speculatively, matching this project's own habit of tackling one gap
  at a time rather than generalizing ahead of an actual need.
- **A dedicated idempotency-keys tracking table** (key → full cached
  response, independent of the `readings` table itself) — the kind of
  general-purpose mechanism a payments-grade system would want; this
  app's single-purpose ingestion endpoint doesn't need it, and adding
  one now would be speculative structure against this project's stated
  minimal-scope ethos.

## Revisit triggers

- **Redis fast-path (a) proves unreliable or adds meaningful latency
  under real load-test conditions** → re-evaluate whether it's worth
  keeping at all, given (b) alone is already sufficient for
  correctness; (a) exists purely as an optimization and should be cut
  if it isn't earning its complexity.
- **This app's scope ever grows to include real downstream consequence
  for a duplicate reading** (billing, regulatory, or any real
  aggregation a duplicate would corrupt) → revisit the deferred items
  above, particularly strict body-match enforcement, with the same
  seriousness applied to Postgres's own fencing/quorum decisions.
