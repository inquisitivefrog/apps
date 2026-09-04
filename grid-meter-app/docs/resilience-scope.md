# grid-meter-app — Resilience scope (retry, circuit breaking, backpressure)

## Circuit breaker: built (2026-09-04) — plus a severe, unrelated bug found and fixed along the way

**Status update to "Open decisions" item 4 below: built, not declined.** Picked up the
previously-scoped-but-never-built Resilience4j work (see "Circuit breaker" and "Where the
circuit breaker applies" sections further down, which describe the original design this
implementation follows).

**Phase 0 re-verification, live against the real registry, not assumed from how long ago the
doc was written:**
- The `resilience4j-bom` gap the doc flagged is *still* open as of the actual current release
  (2.4.0) — confirmed directly against `repo1.maven.org`, not `search.maven.org`'s index, which
  turned out to be stale and initially gave a false "doesn't exist" signal. `resilience4j-spring-
  boot4:2.4.0` itself **is** published and installable; the BOM's `dependencyManagement` just
  doesn't list it, so it needs an explicit version pin rather than BOM-managed inheritance — a
  minor, manageable gap, not a blocker.
- The named fallback (`spring-cloud-starter-circuitbreaker-resilience4j`) was checked and
  rejected: it wraps the *older* `resilience4j-spring-boot3` module paired with Spring Boot
  4.0.8 (not this project's pinned 4.1.0 line) — worse-aligned than the direct artifact, not a
  safer alternative.
- `mvn dependency:tree` (including `-Dverbose=true` for the full project) confirmed zero version
  conflicts from adding `resilience4j-spring-boot4` — it resolves to the exact same Spring
  Framework 7.0.8 line already in use everywhere else.
- Re-confirmed live against the actual pinned `spring-boot-actuator-autoconfigure-4.1.0.jar`:
  still zero Kafka-related classes, so `ReadingsKafkaHealthIndicator` remains genuinely necessary
  custom work.

**What was built**: two independent `CircuitBreaker` instances (`postgres-existence-check`,
`kafka-publish`) wired programmatically into `ReadingService.ingest()`, not via method-level
`@CircuitBreaker` annotations — the existing `@Retryable` already wraps the whole method, and a
single shared breaker would conflate two independently-failing dependencies (the exact anti-
pattern this doc's own "Where the circuit breaker applies" section warns against). Postgres uses
`CircuitBreaker.executeSupplier()` (a synchronous call); Kafka uses manual
`tryAcquirePermission()`/`onSuccess()`/`onError()`, since `KafkaTemplate.send()` is asynchronous
and its real outcome isn't known until its returned future completes. Both wrapped in a
synchronous try/catch too, not just the async path — confirmed live this was necessary, not just
defensive: a full Kafka outage produced a genuine *synchronous* `KafkaException` (`ConfigException:
No resolvable bootstrap urls given in bootstrap.servers`, once all 3 broker hostnames stopped
resolving via Docker's embedded DNS — the same class of finding as the Redis Sentinel DNS lesson
elsewhere in this project, now confirmed for Kafka too), not always the async failure the
`.whenComplete()` path alone would have caught. All `resilience4j.circuitbreaker.instances.*`
properties declared explicitly in `application.yml`, verified against the real 2.4.0 jar's
`CommonCircuitBreakerConfigurationProperties$InstanceProperties` field names via `javap`, not
copied from the doc's own illustrative shape untested.

**Behavior when open**: both breakers throw `CallNotPermittedException`, mapped by
`GlobalExceptionHandler` to a fast `503`. This is a different layer from Traefik's own edge-level
`503` shedding (see "Outcome" below) — Traefik's readiness check is deliberately Kafka/Postgres-
independent since the Traefik fix described there, so it never fires for this case; this handler
is what actually protects the ingest path specifically.

**Interaction with `PrimaryFailoverSQLExceptionOverride` (`postgres-ha-scope.md` Stage 7),
checked explicitly rather than assumed to compose cleanly**: they solve genuinely different,
non-conflicting problems at different layers. The Hikari override evicts one specific stale
*write* connection on Postgres' `25006` (read-only-transaction) SQLState; the breaker tracks
aggregate call outcomes across many requests and stops attempting calls once failures cross a
threshold. `postgres-existence-check` wraps a **read** (`existsById()`), which never triggers the
override's specific write-rejection trigger at all — the override protects a different, later
write path this breaker doesn't touch. Where they *do* meet is the general "Postgres becomes
fully unreachable" case: HikariCP's own `connection-timeout` (5s, already declared) bounds each
individual connection attempt regardless of breaker state; the breaker bounds how many attempts
get made across requests once it's seen enough of them fail. No conflict, no double-guarding.

**Testing**: 8 unit tests added to `ReadingServiceTest` (small, fast, explicit
`CircuitBreakerConfig` — not production's real 10-call window) covering: opens only after
`minimum-number-of-calls` + `failure-rate-threshold` are both crossed, not before; half-open
closes on continued success; half-open re-opens on renewed failure; the two breakers are
genuinely independent in both directions (a Kafka-only failure never opens the Postgres breaker
and vice versa); the Kafka-open case fails fast without ever calling `send()`. All 85 tests in
the suite pass, including the full Spring context boot with real `resilience4j-spring-boot4`
autoconfiguration wired in — not mocked.

**Live verification against the real stack (not stopped at unit/component tests), per this
project's standing practice throughout the HA work**: stopped all 3 Kafka brokers — confirmed the
synchronous `KafkaException` above, confirmed the breaker opened exactly at the 10-call/failure-
rate threshold, confirmed every call after that failed fast (~30ms) with a real `503`, confirmed
recovery through `HALF_OPEN` → `CLOSED` once Kafka came back (real `201`s resumed). Same full
lifecycle confirmed for the Postgres breaker against a real, sustained, all-3-Patroni-nodes-down
outage — which is where the bug below was found.

## Outcome (2026-08-28)

**Summary: the transactional outbox was built, tested against a real
sustained outage, and deliberately unwound — a documented scope decision,
not an abandoned effort.**

What happened, in sequence:

1. **Stage A (outbox write path) built and shipped** (`5d82fd2`): failed
   Kafka deliveries wrote to a new `reading_outbox` table instead of
   vanishing. Verified live against a real 150s quorum-loss re-run
   (10/10 captured).
2. **Kafka health indicator built and shipped** (`b0cd179`):
   `ReadingsKafkaHealthIndicator` correctly flips `/actuator/health`'s
   aggregate status during a real 3-broker outage. Surfaced two real
   findings along the way (Spring Boot 4's `spring-boot-health` module
   relocation; `KafkaAdmin.clusterId()` would have been the wrong
   building block since it caches after first success) and one separate
   gap: Traefik had no health check for `api` at all, not even
   TCP-level.
3. **Stage B (sustained-outage growth measurement) run**: a 12-minute
   Kafka outage under `--scale api=2`. Result was not a growth-rate
   number — it surfaced that the outbox stopped growing after ~120s
   despite Kafka staying down for the full 720s. Root cause: Traefik's
   health check (from step 2) took `api` out of rotation entirely once
   the aggregate health status flipped `DOWN`, so ~95% of the outage
   window's requests never reached `ingest()` at all — they got
   Traefik's edge-level `503` before the Kafka producer, and therefore
   the outbox write path, ever ran. Stage B's "20→40 rows and flat"
   result was an artifact of that interaction, not a capacity number.
4. **Traefik health-check fix**: repointed at a Kafka-independent
   liveness/readiness check instead of the full aggregate
   `/actuator/health`, since the aggregate incorrectly took down
   unrelated traffic (`GET /meters`, `GET /readings`, `POST /meters`)
   during any Kafka-only degradation. Verified live: `GET /meters`
   returns `200` through Traefik during a real Kafka outage (previously
   `503 no available server`), while `/actuator/health` continues to
   correctly report `DOWN`. Full test suite green. This fix stands
   regardless of the outbox decision below — it was a real, independent
   bug.
5. **The redo-path question, applied honestly to this project's actual
   scope**: does a lost meter reading have a real consequence here? Per
   `architecture.md`'s own stated scope (no billing, no anomaly
   detection, deliberately minimal), the honest answer is no — readings
   in this app are synthetic, load-test-generated values with no
   downstream consumer that depends on any individual reading surviving.
   This is different from a real physical-meter deployment (where a
   missed measurement genuinely has no redo path), and the distinction
   matters: the redo-path test is about whether *this data, in this
   system* has a redo path, not about the abstract category "point-in-time
   physical measurement."
6. **Decision: retire the outbox table.** Once the Traefik fix restored
   traffic flow through Kafka outages, the outbox would have resumed
   accumulating rows for the outage's full duration — but Stage D (the
   reconciler that drains it) was never built, and per the redo-path
   conclusion above, was deliberately not going to be. A table with no
   drain path and no query surface (`GET /readings` never exposed it)
   doesn't provide durability — it implies a guarantee that isn't real
   without a reconciler, which is a worse position than not having the
   table at all. The counter + log line + alert rule (kept, see below)
   already answer the only question anyone would actually act on: did
   this happen, and roughly when.

**What was removed**: `ReadingOutbox`/`ReadingOutboxRepository`,
`V5__create_reading_outbox_table.sql`'s effect (dropped via
`V6__drop_reading_outbox_table.sql` — a new migration, not an edit to
the already-applied `V5`, since `V5` had run against the real dev
Postgres; Flyway history stays intact), `ReadingService`'s outbox-write
branch (reverted to log+counter only), `ReadingServiceTest`'s outbox
assertions, `kafka-ha-demo.sh`'s outbox-count logic, and
`outbox-growth-stageB.sh` (its whole premise — measuring outbox growth —
no longer applies).

**What was kept**, because each was independently load-bearing and
verified on its own:

- `reading_delivery_failures_total` (Micrometer counter)
- The `ERROR` log line on delivery failure (meterId/timestamp/value, for
  manual recovery if anyone ever needs it)
- The `Reading delivery failures` Grafana alert rule — reclassified
  2026-08-28 from `alert_class: incident` to `alert_class: notice` (see
  `docs/observability-taxonomy.md` §3): the same redo-path reasoning that
  retired the outbox also argues this shouldn't page anyone, since the
  lost data has no real downstream consequence. A durable record, not an
  interruption.
- `ReadingsKafkaHealthIndicator`
- The Traefik readiness fix (independent bug, unconditionally correct)

**Why this counts as a good outcome, not a wasted build**: the decision
to stop is only trustworthy because it was backed by real measurement
rather than assumed. Stage B's "flat at 40 rows" result is what actually
surfaced the Traefik/health-indicator interaction — a real bug that
would otherwise have shipped silently, cutting unrelated traffic during
any future Kafka blip. Skipping straight to "don't bother, low
consequence" without building through Stage A/B would have reached the
same stopping point by luck, not evidence, and would have missed that
bug entirely.

**Known-superseded note**: `docs/observability-taxonomy.md` still
previews this doc as covering "the transactional-outbox pattern" —
stale as of this outcome, not yet corrected there (out of scope for this
edit per the doc's own edit-permission convention).

---

## Why this doc exists

From an SRE question raised directly: how should resilience actually be
implemented here — is it just retry between services, should services
expose a queryable health status, and what should happen once retries are
exhausted (buffer, shed load, or give up entirely)? This doc gives a
concrete answer rather than leaving "resilience" as a buzzword, and ties
directly into the HikariCP timeout already reframed in `ha-scope.md`
(pointer added there) — a circuit breaker is the more direct fix that
section was reaching for.

## What Spring Boot 4 already gives you natively — don't reach past it for retry

Spring Boot 4 introduced native `@Retryable` and `@ConcurrencyLimit`
annotations (built on Spring Framework 7), covering basic bounded retry
and concurrency limiting without any external library. Reach for
Resilience4j specifically for **circuit breaking** and its detailed
metrics — not for plain retry, which Spring Boot 4 now covers itself.
This matters for this project's stated minimal-scope ethos: adding a
whole library when the framework already covers most of the need isn't
the disciplined choice.

## Kafka producer's own blocking behavior: a real first line of defense, and a sequencing dependency

A real Kafka outage test (`b388bi7hg`, 2026-08-26, single-broker Kafka
stopped and restarted, 46s fully down) produced a result worth building
the rest of this doc around rather than skipping past: 88 `POST
/readings` requests sent during the outage, **zero HTTP errors**, and a
Postgres readings count that increased by exactly 9,248 — matching the
real sample count exactly. Every reading that returned `201` landed
durably.

**Why this happened, mechanically**: 5 of those 88 requests blocked for
~49.7–49.8s each — the Kafka producer's `send()` call stalling on
metadata refresh, bounded by `max.block.ms`'s undeclared 60s client
default. Because the 46s outage ended before that 60s ceiling was
reached, every blocked request eventually succeeded once Kafka came back.
`max.block.ms` governs a different phase of the producer lifecycle than
`request.timeout.ms` (waiting for a broker's response to an already-sent
request) or `delivery.timeout.ms` (the overall ceiling across retries) —
it specifically bounds how long `send()` itself can block before a
record is even handed off.

**This is not the same situation as the HikariCP fix, and treating it
identically would make things worse.** The HikariCP fix was justified
because a 30s default was masking a real failure as latency — the alert
never saw the outage. Here, the 60s default just produced a *genuinely
good* outcome: zero errors, zero data loss, confirmed empirically. Would
shrinking `max.block.ms` to something HikariCP-like (5s) improve this?
No — it would take that same 46s outage and convert it from a silent
success into a burst of failures, because nothing exists yet to catch
those failures. ~~Postgres persistence happens via the Kafka→consumer
pipeline, not directly inside `ingest()`, so a failed `send()` today loses
the reading outright — there's no outbox yet to land in.~~ **(Superseded
2026-08-28: this remains true — a failed `send()` loses the reading
outright — but an outbox is no longer the planned fix; see "Outcome"
above. The delivery-failure callback, counter, log, and alert are the
fix that shipped instead.)**

**Sequencing constraint (explicit, so it isn't lost to memory):**

1. **Declare `max.block.ms` explicitly now**, near its current effective
   value (~60s) — the goal at this step is only "stop it from being an
   accident," the same discipline already applied to HikariCP's timeout,
   but *not* the same fix. An undeclared default is a gap regardless of
   whether its current value happens to be good. **(Done — see
   `application.yml`.)**
2. ~~Do not shorten `max.block.ms` until the circuit breaker + outbox
   above actually exist.~~ **(Moot as originally framed — the outbox was
   built, measured, and retired; see "Outcome" above. `max.block.ms`
   remains declared at its existing value; no shortening has been made
   or is currently planned.)**

**A real risk this specific test didn't stress**: 5 threads blocking
~50s each is nowhere near enough to threaten a 200-thread Tomcat pool,
but a longer outage under real concurrent load could tie up enough
threads to trigger the existing `Tomcat thread pool saturated` alert —
the same class of risk the original HikariCP investigation surfaced, just
for Kafka instead of Postgres, and not yet tested at realistic
concurrency.

**The actually-missing test**: ~~run an outage *longer* than the declared
`max.block.ms` value and observe what happens today — does `send()`'s
`TimeoutException` propagate as an unhandled `500`, and is the reading
genuinely lost? That confirms the exact failure mode the outbox above is
meant to fix, rather than assuming it.~~ **(Done — see the 150s
quorum-loss re-test documented in the delivery-failure investigation and
in "Outcome" above. Confirmed: `TimeoutException` on `delivery.timeout.ms`
expiry, reading genuinely and permanently lost, now observable via the
counter/log/alert rather than silent.)** This is also the first real data
point for the outbox's max-depth/max-age sizing question — 88 requests
over 46s from this one test's configured rate, not necessarily a
production peak, but a real number rather than a guess. ~~(Moot — no
outbox to size.)~~

## Circuit breaker: Resilience4j, with a real gotcha to check before pinning

**Status (2026-08-28): not built. Deferred, not declined** — unlike the
outbox, no measurement has been run that argues against a circuit
breaker specifically. The redo-path reasoning that retired the outbox
was about data durability, not about fail-fast behavior in general; a
breaker in front of the Kafka `send()` call and the Postgres
`existsById()` check would still reduce wasted thread time during a
known-bad-dependency window, independent of what happens to the data
itself. Revisit as its own scoping question if thread-pool exhaustion
under sustained outage (the "real risk this specific test didn't stress"
above) becomes a real concern.

Resilience4j added Spring Boot 4 / Spring Framework 7 support in its
2.4.0 line via a new `resilience4j-spring-boot4` artifact. **A real,
recently-reported gap**: that new artifact was initially left out of
`resilience4j-bom`, breaking dependency resolution for anyone relying on
the BOM to manage versions — a fix was merged but a release incorporating
it wasn't necessarily out as of this writing. **This check has not yet
been re-run as of 2026-08-28** — still needed before any implementation
work starts.

**Action**: run this project's own `scripts/check-maven-central-version.sh`
against `io.github.resilience4j:resilience4j-spring-boot4` before pinning
anything in `pom.xml` — this is exactly the kind of "verify against the
real registry, don't trust a plausible-looking version" situation
`cross-project-lessons.md` already documents as a recurring pattern.
`org.springframework.cloud:spring-cloud-starter-circuitbreaker-resilience4j`
is a fallback worth comparing at implementation time if the BOM gap is
still open — it wraps Resilience4j under Spring Cloud's abstraction and
may have cleaner Spring Boot 4 support depending on timing.

## Where the circuit breaker applies

`ReadingService.ingest()` has two independent external calls, and each
needs its **own** breaker instance, not one shared breaker for the whole
method — Postgres and Kafka fail independently, and conflating them means
a Kafka outage would also start rejecting requests that only needed
Postgres:

- `meterRepository.existsById()` — the synchronous Postgres check already
  investigated in the HikariCP work.
- The Kafka producer `send()` call.

### Illustrative config shape (verify exact property names against the installed version)

```yaml
resilience4j:
  circuitbreaker:
    instances:
      postgres-existence-check:
        sliding-window-size: 20
        failure-rate-threshold: 50
        wait-duration-in-open-state: 10s
        permitted-number-of-calls-in-half-open-state: 5
        minimum-number-of-calls: 10
      kafka-publish:
        sliding-window-size: 20
        failure-rate-threshold: 50
        wait-duration-in-open-state: 10s
        permitted-number-of-calls-in-half-open-state: 5
        minimum-number-of-calls: 10
```

## Health status: `/actuator/health` — and a correction to something said earlier this conversation

`/actuator/health` already exists, and Spring Boot Actuator auto-configures
indicators for the datasource and Redis out of the box.

**Correction**: earlier in this conversation I said a Kafka health
indicator was "available too" alongside those — that's wrong, and worth
stating plainly rather than quietly fixing. Spring Boot Actuator does
**not** ship a built-in Kafka health indicator; an earlier version of one
existed inside the Spring Boot project itself and was removed, and
nothing has replaced it upstream. A custom indicator (extend
`AbstractHealthIndicator`, back it with a `KafkaAdmin.describeCluster()`
call) is real, bounded, well-documented work — a few community reference
implementations exist — but it's a thing to build, not a flag to flip.
**(Done — see "Outcome" above: `ReadingsKafkaHealthIndicator`, built
against `KafkaAdmin.describeCluster()` rather than `clusterId()`, which
would have been the wrong choice since it caches after first success.)**

**Action**: ~~write a `ReadingsKafkaHealthIndicator`; separately, confirm
Traefik's existing health check for `api` is actually reading
`/actuator/health`'s aggregate status rather than just checking TCP
connectivity to the port — those are meaningfully different checks. A
hung application that still accepts TCP connections looks perfectly
healthy to a TCP-only probe.~~ **(Done, with a real finding: Traefik had
no health check for `api` at all — worse than the TCP-only worst case
this section anticipated. Once the health indicator above was added and
wired to the full aggregate `/actuator/health`, it was found to
over-correct: Kafka going down took *all* traffic out of rotation,
including read paths (`GET /meters`, `GET /readings`) that don't touch
Kafka. Fixed by repointing Traefik at a Kafka-independent
liveness/readiness check instead of the full aggregate. Verified live
against a real Kafka outage — see "Outcome" above.)**

## Backpressure / give-up decision: transactional outbox

**Status (2026-08-28): built, measured, retired. See "Outcome" above for
the full account.** The section below is retained as a historical record
of the original design — not because it's wrong, but because the
reasoning in it (particularly the ordering/idempotency caveats) is
useful context for anyone who revisits this decision later.

~~The retry-exhausted decision you asked about — buffer vs. shed load vs.
give up — maps onto the **transactional outbox pattern**: when the Kafka
breaker is open, write the reading to a durable Postgres outbox table
within the same transaction as the existence check, instead of attempting
to publish directly. A background reconciler drains the outbox to Kafka
once the breaker closes again.~~

- ~~**Simple version (confirmed for this pass, 2026-08-27)**: a scheduled
  poller (e.g. every 5s) selects unsent outbox rows and republishes
  them.~~ **(Never built — see Stage D below, which was never reached.)**
- **More correct version, named but not built this pass**: Debezium
  reading Postgres's write-ahead log and publishing changes to Kafka
  automatically — no polling needed, the standard production-grade outbox
  implementation. This needs a Kafka Connect deployment, a real additional
  piece of infrastructure — flag as its own future decision, the same
  "documented, not built" treatment already given to Patroni and Redis
  Sentinel in `ha-scope.md`. **(Moot for this project per the retirement
  decision above; retained as a note for any future project reusing this
  reasoning.)**
- ~~**The give-up trigger** — this is what actually answers "buffer,
  shed, or give up": bound the outbox itself, by max row count or max age
  of its oldest unsent row. Once exceeded, stop accepting new writes into
  the outbox and start returning `503` to callers instead. This converts
  "buffer everything forever" into "shed load once buffering stops being
  safe" automatically, and directly prevents the Postgres disk-fill risk
  of unbounded buffering during a genuinely long outage.~~ **(Moot — no
  outbox exists to bound. The actual give-up behavior that shipped is
  simpler: Traefik itself sheds load at the edge via its readiness check
  once Kafka health degrades broadly, and individual `POST /readings`
  calls fail fast via the declared `max.block.ms`/`delivery.timeout.ms`
  ceilings rather than hanging.)**
- **Ordering/idempotency caveat, stated honestly**: a polling reconciler
  can republish out of original arrival order if several outbox rows
  accumulate, and a crash between "publish succeeded" and "mark the
  outbox row sent" can cause a duplicate publish. Both are real,
  known tradeoffs of the simple polling version. Debezium's CDC-based
  approach preserves WAL order more naturally but doesn't eliminate
  at-least-once duplication risk either — downstream consumers need
  idempotent handling regardless of which outbox implementation gets
  chosen. **(Retained as historical reasoning; moot for this project.)**
- **A second, distinct crash-window gap found during this investigation
  (2026-08-28), separate from the caveat above**: a process crash between
  `ingest()`'s `send()` call and its `whenComplete` callback firing —
  before either the success path or the (former) outbox-write path ever
  executed — could lose an in-flight request that never even reaches a
  durable record. This window is normally milliseconds wide, but during
  an active outage it's as wide as `delivery.timeout.ms` (120s), meaning
  a crash/restart during an outage compounds with the outage itself. This
  gap predates and is independent of the outbox retirement decision — it
  would have existed in the write-on-failure outbox design too, and would
  only have been closed by a write-ahead design (write the durable record
  *before* calling `send()`, not after failure). Evaluated and not
  pursued, for the same redo-path reasons as the outbox itself: fixing it
  would mean a synchronous Postgres write on every single ingest (not
  just failures), a real throughput cost, to protect data whose loss has
  already been assessed as having no real consequence in this project's
  actual scope. Documented here as a known, accepted, narrow gap.

## Testing implications

~~- **Resilience4j unit tests**: mock a failing dependency, assert the
  breaker opens once `minimum-number-of-calls` and `failure-rate-threshold`
  are both crossed, assert half-open behavior (a bounded number of probe
  calls, closing on success, re-opening on failure).~~ **(Still open —
  circuit breaker itself is deferred, not declined; see status note
  above. This test plan stands if/when that work resumes.)**
- ~~**Component test (Testcontainers)**: kill Postgres or Kafka mid-test,
  assert requests fail fast (sub-second, not the old ~30s hang) once the
  breaker is open — this is the test that proves the HikariCP timeout and
  the circuit breaker actually work together, not just that each exists
  independently.~~ **(Same status as above — pending the breaker.)**
- ~~**Outbox reconciliation test**: kill Kafka, confirm `POST /readings`
  still succeeds (the write lands in the outbox), restore Kafka, confirm
  the reconciler drains the outbox and the reading becomes visible via
  `GET /readings` within a bounded time window.~~ **(Moot — outbox
  retired.)**
- ~~**Outbox-bound test**: simulate filling the outbox past its configured
  max depth/age, confirm new `POST /readings` requests start returning
  `503` rather than accepting indefinitely.~~ **(Moot — outbox retired.
  The `503`-shedding behavior that actually exists comes from Traefik's
  readiness check, already covered by the live verification in
  "Outcome" above, not from an outbox bound.)**

## Open decisions needing explicit sign-off

1. ~~Simple polling reconciler now vs. scoping Debezium as the real
   target~~ — **Superseded 2026-08-28: moot. The outbox itself (and
   therefore any reconciler, polling or Debezium-based) was built,
   measured via Stage B, and retired per the redo-path decision. See
   "Outcome" above.**
2. ~~Outbox bound values (max depth / max age) — still open; no natural
   default exists yet. Needs a real number once there's a rough sense of
   acceptable Postgres disk growth during a plausible worst-case outage
   duration.~~ **(Superseded 2026-08-28: moot — no outbox to bound.)**
3. ~~`max.block.ms` — declare explicitly now near its current ~60s
   effective value; do not shorten until the circuit breaker + outbox are
   built.~~ **(Superseded 2026-08-28: declaration is done and stands
   independently of the outbox's fate. Shortening remains undecided but
   is no longer gated on an outbox that won't exist — it would now be
   gated on the circuit breaker alone, if that work resumes.)**
4. ~~New (2026-08-28): circuit breaker (Resilience4j) — build or
   formally decline? Not yet decided either way. Unlike the outbox,
   nothing has been measured that argues against it; it's simply not
   been prioritized yet, and the `resilience4j-spring-boot4` BOM gap
   hasn't been re-checked. Needs its own scoping pass if picked up.~~
   **(Resolved 2026-09-04: built.** Two independent breaker instances
   wired into `ReadingService.ingest()`, live-verified against real
   Kafka and Postgres outages. See "Circuit breaker: built" at the top
   of this doc for the full account, including a severe, unrelated bug
   found and fixed along the way.)
