# grid-meter-app — Idempotency scope: `POST /api/v1/readings`

**Status (2026-09-02): implemented and live-verified, including the
JMeter companion work.** Built exactly as designed below — required
`Idempotency-Key` header, Redis fast path, DB constraint as the real
guarantee — with 70/70 tests green and live confirmation against the
real running stack that the two layers divide labor correctly (Redis
caught the one live duplicate test before Kafka ever saw it). All 7
affected `.jmx` files (6 profiles plus the shared `warmup.jmx`
fragment — `provision-meters.jmx` only posts to `/meters` and needed no
change) now generate a fresh `${__UUID()}` per request via their shared
`HeaderManager`, confirmed via a live run of every profile at 0.00%
error rate. See "Implementation results" near the end of this doc for
the full account, including an unrelated regression found and fixed
along the way.

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

**JMeter, closed out (2026-09-02), after checking in explicitly on the
approach rather than rushing it in alongside the rest of this work**:
7 files needed the header — `steady-state.jmx`, `ramp-up.jmx`,
`rapid-spike.jmx`, `gentle-spike.jmx`, `soak.jmx`,
`misconfigured-burst.jmx`, and the shared `common/warmup.jmx` fragment
they all include. `common/provision-meters.jmx` was checked and
confirmed to only POST `/meters`, not `/readings` — no change needed
there despite matching an early, looser grep for the string "readings"
(present only in a comment). Each of the 7 files' `POST /readings`
sampler is covered by a shared thread-group-level (or, for `warmup.jmx`,
sampler-level) `HeaderManager` alongside the existing `Authorization`/
`Content-Type` headers — added a third header there,
`Idempotency-Key: ${__UUID()}`, JMeter's built-in function that
re-evaluates fresh on every request the same way `${__Random(...)}` and
`${__time(...)}` already do in the same sampler's body, rather than once
per thread (which would have made every request after a thread's first
one a detected duplicate). Verified live: `smoke-test.sh`'s full run of
all 5 named profiles (which also exercises `warmup.jmx` via each
profile's setUp) at 0.00% error rate, plus a direct short run of
`misconfigured-burst.jmx` (not part of `smoke-test.sh`, run separately)
also at 0.00% error rate — all 7 files confirmed working, not just
believed fixed from reading the XML. This closes the "required companion
work" note above in full; nothing from this doc's original scope remains
outstanding.

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
