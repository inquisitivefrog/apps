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
and vice versa); the Kafka-open case fails fast without ever calling `send()`. A further,
dedicated component test (`ReadingIngestCircuitBreakerLatencyComponentTest`, 2026-09-04) closes
the timing half of this work: both breakers' OPEN-state behavior is proven not just to throw the
right exception internally but to actually return fast over real HTTP — measured wall-clock
time of the HTTP call itself, not an internal breaker metric, matching this project's own App
RTO vs. Infra RTO distinction (`postgres-ha-scope.md`'s Stage 7). Real measured latencies across
4 runs: `postgres-existence-check` 5–12ms, `kafka-publish` 11–24ms, both comfortably under a
200ms ceiling chosen to be tight enough to catch a real regression toward the old undeclared-
default multi-second hang, not just "not literally infinite." All 87 tests in the suite pass,
including the full Spring context boot with real `resilience4j-spring-boot4` autoconfiguration
wired in — not mocked.

**Live verification against the real stack (not stopped at unit/component tests), per this
project's standing practice throughout the HA work**: stopped all 3 Kafka brokers — confirmed the
synchronous `KafkaException` above, confirmed the breaker opened exactly at the 10-call/failure-
rate threshold, confirmed every call after that failed fast (~30ms) with a real `503`, confirmed
recovery through `HALF_OPEN` → `CLOSED` once Kafka came back (real `201`s resumed). Same full
lifecycle confirmed for the Postgres breaker against a real, sustained, all-3-Patroni-nodes-down
outage — which is where the bug below was found.

**What's still open: load-test validation of thread-pool protection under sustained concurrent
failure — not yet done.** Everything above (unit tests, the dedicated latency component test,
and live verification against real Kafka/Postgres outages) proves the breakers are *correct* —
they open/close at the right thresholds, fail fast without fabricating false success, and recover
cleanly. None of it proves the breakers achieve their *original motivating purpose*: this doc's
own "real risk this specific test didn't stress" note (see the Kafka producer section above) —
whether a **sustained outage under realistic concurrent load** would tie up enough Tomcat request
threads to trigger the `Tomcat thread pool saturated` alert, and whether the breaker actually
prevents that once it's open. All verification so far, unit and live alike, has been **sequential,
single-call reproduction** — one request at a time, never concurrent load. A breaker that opens
correctly under sequential probing could still fail to protect the thread pool under real
concurrent pressure if, for example, enough requests arrive simultaneously *before* the breaker
has accumulated enough failures to open (the exact ramp-up window this doc's Kafka circuit
breaker section already flags as a real, un-eliminated cost).

**Scoped as a specific, pick-up-able follow-up, not vague "someday" language**: extend or add a
`load-tests/` JMeter scenario that drives **Kafka specifically** (not Postgres — Kafka already has
a clean, already-proven full-outage story from this pass: stop all 3 brokers, confirmed
synchronous `KafkaException`, confirmed breaker lifecycle) into a sustained failing state under
realistic concurrent load (matching this project's existing load-test profiles' shape — see
`load-tests/README.md`), and confirms via Tomcat thread-pool metrics **already scraped through
Actuator/Micrometer** per `architecture.md` (`tomcat_threads_busy_threads`,
`tomcat_connections_current` — the same metrics the original HikariCP `connection-timeout`
investigation and the misconfigured-spike-demo scenario already rely on) that the pool does *not*
saturate the way it would without the breaker. The natural comparison point, matching
`misconfigured-spike-demo.sh`'s own before/after technique for `accept-count`: run the identical
sustained-Kafka-outage-under-load scenario twice, once with the breaker enabled and once with it
effectively disabled (no such toggle exists yet -- would need one, e.g. an env-var-driven
override setting `resilience4j.circuitbreaker.instances.kafka-publish.minimum-number-of-calls`
high enough that it never opens during the test, mirroring the existing
`docker-compose.redis-retry-isolation-test.yml` override pattern), and compare the two runs'
thread-pool metrics directly.

**Status (2026-09-11): done — see the dated section below for the full account.** The follow-up
above was built essentially as scoped (a real `load-tests/` JMeter scenario, Tomcat metrics
already scraped via Actuator/Micrometer, no new tooling beyond polling those same metrics faster
than Prometheus's own 15s scrape interval). The before/after breaker-disabled comparison suggested
above was **not** needed to answer the question — a single real run against the enabled breaker
already showed the pool reaching its full configured ceiling, which settles "does the breaker
prevent this" without needing a disabled-breaker control. **The answer is more nuanced than either
"yes" or "no": correctness (fail-fast under real concurrency) is confirmed; "prevents thread-pool
saturation" is not — the pool does reach 100% in real, measured bursts, for a reason outside the
breaker's own control.** Not fixed unilaterally, per this project's own check-in convention — see
"Open decisions" item 4's update at the bottom of this doc.

## Circuit breaker: load-tested under sustained concurrent Kafka failure (2026-09-11)

Picks up the "What's still open" note directly above. Built
`load-tests/kafka-outage-concurrent.jmx` (a sixth JMeter profile, structured identically to the
other five — shared `common/login.jmx`/`provision-meters.jmx`/`warmup.jmx` fragments via Include
Controller, the same `POST /readings` sampler and `Idempotency-Key: ${__UUID()}` header — but
driven by a dedicated orchestrating script, `load-tests/kafka-circuitbreaker-loadtest.sh`, rather
than `run.sh`, since this scenario needs to background JMeter and kill/restore real Kafka brokers
mid-run, the same shape `misconfigured-spike-demo.sh` already established for a two-phase
scripted scenario). Instrumentation is two new small scripts, not new tooling in spirit:
`kafka-cb-loadtest-poller.py` polls `api`'s own `/actuator/prometheus` directly at 0.2s resolution
(Prometheus's own `scrape_interval` is 15s — far too coarse for a breaker whose
`minimum-number-of-calls` is 10 and can plausibly open in well under a second; a single fetch
timed at ~10-20ms before trusting the loop, per `docs/testing-strategy.md`'s "a polling loop's own
per-call cost can dominate the measurement" standing lesson), and
`kafka-cb-loadtest-analyze.py` combines that CSV with JMeter's own `results.jtl` to answer both
questions with real numbers rather than a pass/fail assertion.

**Two real methodology bugs found and fixed before trusting any run — both instances of this
project's own standing lessons, not new categories:**

1. **A fixed pre-kill sleep raced the SetupThreadGroup's own warmup, exactly the
   fixed-sleep-vs-unbounded-readiness pattern `docs/testing-strategy.md` already tracks.** This
   scenario's `TestPlan.serialize_threadgroups=true` means the main load Thread Group can't start
   until `setUp` (login + 10-meter provisioning + `warmup.jmx`'s 50 sequential, *real*
   `POST /readings` calls) finishes — and the first dry run killed Kafka while that warmup phase's
   own real Kafka-touching requests were still in flight, contaminating the exact baseline the
   pre-kill window exists to establish. Fixed by polling the growing `results.jtl` for the first
   sample carrying the main group's own label (`POST /readings`, not `warmup.jmx`'s
   `WARMUP: POST /readings`) before starting the pre-kill countdown, instead of guessing how long
   setup takes.
2. **The first real (post-fix) run used an 8-second outage and found nothing — not because the
   breaker worked, but because the outage was too short to prove anything, exactly the gap
   `load-tests/README.md`'s own Kafka HA section already documents for `kafka-ha-demo.sh`'s
   Scenario 2.** Every one of that run's samples returned `201`; `kafka-publish`'s breaker never
   opened. Root cause: `kafkaTemplate.send()`'s background delivery retries, bounded by the
   declared `delivery.timeout.ms` (120000ms), silently absorb any outage shorter than that once
   brokers return — nothing ever completes as a *failure*, so the breaker's sliding window never
   sees one. Fixed by using a 150-second outage (120s + 30s margin, the identical number
   `kafka-ha-demo.sh` already uses for the same reason) as the default, not a round "long enough"
   guess.

**A real mechanism found, empirically, that the original design didn't anticipate: `send()` can
block synchronously for the full declared `max.block.ms` (60000ms) under a genuine sustained
outage, and the resulting exception is uncaught.** The circuit-breaker build's own live
verification (top of this doc) saw a *fast*, synchronous `ConfigException` once all 3 broker
hostnames stopped resolving via Docker's embedded DNS. Under *sustained concurrent load*, a
different and slower manifestation of the same "the Kafka client can block the calling Tomcat
thread synchronously" risk shows up instead: with many requests continuously enqueuing records
against unreachable brokers, the producer's internal buffer fills, and *new* `send()` calls block
waiting for buffer space — bounded by `max.block.ms`, exactly as this doc's own Kafka-producer
section named it, just triggered by buffer exhaustion rather than a stale-metadata refresh. In a
50-thread diagnostic run, this produced 5 samples that each took almost exactly 60.05–60.06
seconds before returning **`500`**, not `503` — confirmed via the raw `.jtl`: `GlobalExceptionHandler`
has no handler for a bare Kafka client exception (`KafkaException`/`TimeoutException`), so it falls
through to Spring's own default error handling, the same *shape* of gap (an uncaught exception
reaching an ambiguous Spring default instead of an explicit classification) as the
`DisconnectedClientHelper`/Postgres finding documented below, just a different hierarchy and a
different symptom (a bare `500` instead of a fabricated `200`). Named as its own item in "Open
decisions" below — not fixed here, since it's a genuinely new gap, not something this test was
scoped to unilaterally patch.

**Two runs, deliberately at two different concurrency levels, to isolate cause from a confound
found in the first one:**

| Run | Threads | Why | Result |
|---|---|---|---|
| 300 (150% of `server.tomcat.threads.max=200`, matching `rapid-spike.jmx`'s own established "force visible saturation" convention) | Confounded — `tomcat_threads_busy_threads` was already pinned at `200/200` **before Kafka was even killed**, simply because 300 concurrent JMeter threads exceed the 200-thread ceiling on their own, Kafka notwithstanding. Kept as a real, honestly-labeled secondary data point (a combined "traffic burst + Kafka outage" scenario), not the answer to the causal question. |
| 150 (comfortably under the 200-thread ceiling — the pool never approaches saturation from raw concurrency alone) | The clean, causally-isolated primary result. |

**150-thread run (the primary result) — real numbers, `load-tests/results/kafka-cb-loadtest-20260911-095945/`:**

- **Healthy baseline** (before the kill, and during the calm stretches of the outage between
  breaker-state transitions): `tomcat_threads_busy_threads` sits flat at ~150–153 the entire time —
  confirming 150 concurrent threads alone never stresses a 200-thread pool, the necessary
  precondition for treating any later spike as Kafka-outage-driven rather than raw concurrency.
- **The `kafka-publish` breaker first opened at `t+60.64s`** after the kill (`resilience4j_circuitbreaker_state{name="kafka-publish",state="open"}` observed transitioning `0→1`), not instantly and not on a fixed schedule — bounded by how long the first batch of calls needed to actually *complete* as failures, not by `minimum-number-of-calls=10` alone. The raw `.jtl` confirms the mechanism precisely: **150 of 150 concurrent threads' requests started blocking within the same sub-second window right at the kill**, and **all 150 completed (`500`, the uncaught `max.block.ms` timeout above) in a tight cluster right around `t+60s`** — the same near-simultaneous batch that also supplied the breaker's first 10+ failures.
- **`tomcat_threads_busy_threads` reached its full configured ceiling — `200/200`, 100% — in two distinct ~10–15 second windows, both precisely aligned with a breaker-state transition**: `t+60–75s` (the first `OPEN`, then the next-request-triggered transition to `HALF_OPEN` at exactly `t+70.64s` — 10.00s after opening, matching the declared `wait-duration-in-open-state: 10s` to the millisecond) and `t+120–145s` (a second full re-open/re-probe cycle, including one probe cycle that failed back to `OPEN` in only 0.21s rather than blocking, showing the failure mode varies run to run even within one outage). Outside those two windows, the pool stayed at its normal ~150–153 baseline for the entire rest of the 150-second outage.
- **Honest, bounded limit on this finding**: the *precise* reason the reading reaches a full 200 (not merely the raw 150-thread concurrency ceiling) during these specific bursts wasn't further isolated within this test's scope — plausibly some overlap between an old, just-timing-out request and its thread's own immediately-issued next request, but not confirmed at the level of rigor this project holds other mechanism claims to (e.g. the Kafka `external_confirm_s` investigation). The core, load-bearing finding — the pool reaches its full ceiling in bursts tied to the breaker's own open/half-open cycling — is not in question; only the exact arithmetic of *why it's 200 and not 150* is left as an unchased, explicitly-flagged loose end.

**300-thread run (secondary, confounded, `load-tests/results/kafka-cb-loadtest-20260911-095418/`) — kept for a different, real finding it surfaced:** with the pool already saturated by raw concurrency alone, the high-resolution poller's *own* `GET /actuator/prometheus` calls started timing out (a 2-second client-side timeout, for roughly 12 real seconds right at the point of peak contention) — this app has no separate Actuator management port (`server.port: 8080` serves everything), so even the health/metrics endpoint competes for the same saturated Tomcat pool as the business endpoints it's trying to observe. A real, if secondary, operational finding: under severe enough combined load, an operator's own dashboard-refresh or scrape can itself start failing, not just the endpoint under test.

**Question (a) — does the breaker open before the pool saturates? Answered, precisely, and it's the honest "no" the top of this section flagged as a legitimate possible outcome, not a failure to fix silently.** The breaker's correctness is not in question — it opened, and its `minimum-number-of-calls`/`failure-rate-threshold` config was honored exactly (confirmed via the state-gauge transitions above). What's now confirmed wrong is the *assumption* that opening the breaker is sufficient to bound thread-pool pressure: calls that pass `tryAcquirePermission()` *before* the breaker has enough completed failures to open are entirely outside the breaker's control once they're in flight, and if they hit Kafka's own `max.block.ms`-bounded synchronous block, each one can occupy a Tomcat thread for up to a full minute regardless of what the breaker does moments later. Under a genuinely non-oversubscribed 150-thread baseline, this drove the pool to its full configured ceiling twice during one 150-second outage.

**Question (b) — does concurrent traffic get shed fast once open? Yes, confirmed under real concurrency, not just sequentially.** Across the 150-thread run's 228,122 real `503` (`CallNotPermittedException`) responses during the outage: min 1ms, mean 58.8ms, p95 116ms, max 1194ms — an order of magnitude higher than `ReadingIngestCircuitBreakerLatencyComponentTest`'s idealized sequential figure (11–24ms), but still clearly sub-second, with no long tail suggesting pile-up. Checked specifically **during** the two thread-pool-saturation windows above, in case concurrency-driven queueing degraded fast-fail latency too: it didn't — `503`s landing inside those windows were, if anything, slightly *faster* (mean 50.3ms, p95 96ms) than `503`s in the calm stretches (mean 69.3ms, p95 134ms) — no evidence of lock contention or pile-up inside Resilience4j's own state machine at this concurrency level, in either condition.

**What this means for "Open decisions" item 4, closed precisely, not just closed**: correctness under real concurrent load is now confirmed (question (b), unambiguously yes). The original motivating concern — "does the breaker protect the thread pool" — resolves to a real, honest **no, not by itself**, for a reason outside the breaker's own design: it can only act on calls it gets a chance to gate, and a call that already blocked past that gate can hold a thread for up to `max.block.ms` regardless of the breaker's state. Two possible remediations are named here for explicit sign-off, per `CLAUDE.md`'s check-in convention — **neither applied unilaterally**:

1. **Shorten `max.block.ms`** from its current declared 60000ms to something much smaller (e.g. a few seconds) — bounds the worst case per stuck call directly, at the cost of potentially converting a transient, self-resolving delay into a fast failure sooner than necessary during a brief, real broker hiccup. This is the most direct fix, but changes a value this doc already declared deliberately (see the Kafka producer section above) for reasons specific to the *pre-breaker* investigation, not yet re-examined against this finding.
2. **Accept the current behavior as a bounded, honest cost** — up to 60 seconds per call that happened to start just before the breaker opened, self-resolving, with no data corruption (the request either eventually succeeds or the reading is lost per the already-accepted redo-path decision above) — and revisit only if a real production signal (the `Tomcat thread pool saturated` alert actually firing during a real Kafka outage) makes it worth the tradeoff in (1). Matches this project's own "measure first, decide only if a real gap needs fixing" discipline already applied to the Postgres fencing decision and the Redis `min-replicas-to-write` gap.

A third, smaller, related item is also flagged for sign-off rather than fixed here: **`GlobalExceptionHandler` has no explicit handler for a bare Kafka client exception**, so the `max.block.ms`/`500` path found above returns a generic, inconsistent error shape instead of this app's usual `503`/`ApiError` contract for "a dependency is failing." A narrow `@ExceptionHandler({KafkaException.class})`-style addition, mapped to `503`, would close it — the same shape of fix already applied twice in this doc for the Postgres `DisconnectedClientHelper` gap, just for a different exception hierarchy.

Full evidence: `load-tests/kafka-outage-concurrent.jmx`, `load-tests/kafka-circuitbreaker-loadtest.sh`,
`load-tests/kafka-cb-loadtest-poller.py`, `load-tests/kafka-cb-loadtest-analyze.py`; raw results
under `load-tests/results/kafka-cb-loadtest-20260911-{094510,094803,094922,095418,095945}/`
(the first two are the pre-fix/post-fix methodology-bug runs, kept as evidence of the fix rather
than deleted, matching `misconfigured-spike-demo.sh`'s own precedent of keeping a "real kink we
caught" run alongside the corrected one; the third is the 50-thread mechanism-diagnostic run; the
fourth and fifth are the 300-thread and 150-thread runs analyzed above).

## Circuit breaker: `max.block.ms` shortened + the missing exception handler added, re-verified (2026-09-11)

Closes "Open decisions" items 5 and 6 above. Both were approved for this pass; nothing here was
built without that sign-off.

**Item 6 first (the exception handler), because item 5's own safety margin needed to be checked
against a *confirmed* exception type, not an assumed one.** Reproduced the `max.block.ms` timeout
live (a small, dedicated repro — modest concurrent traffic against a real stopped 3-broker
cluster, not the full load-test scenario) and captured the actual stack trace before writing
anything: `KafkaTemplate.doSend()` (`spring-kafka-4.1.0` source, confirmed by pulling the sources
jar and reading it directly, not assumed from general Kafka-client knowledge) wraps a
synchronously-completed, already-failed send future as `org.springframework.kafka.KafkaException("Send
failed", cause)` — **Spring Kafka's own wrapper class, not the raw
`org.apache.kafka.common.KafkaException`** the original finding's prose loosely suggested — with
root cause `org.apache.kafka.common.errors.TimeoutException: Topic readings not present in
metadata after 60000 ms.` Added `@ExceptionHandler(KafkaException.class)` to
`GlobalExceptionHandler` (importing `org.springframework.kafka.KafkaException`), mapped to `503`
with the same `ApiError` shape every other "a dependency is failing" response in that class uses —
placed immediately after `handleCircuitBreakerOpen()`, since the two are conceptually adjacent
(both concern a Kafka call gated by the same breaker) but structurally unrelated: confirmed via
`javap` that `KafkaException` (`extends NestedRuntimeException`) and `CallNotPermittedException`
share no hierarchy, so Spring's nearest-match dispatch can never confuse one for the other — the
two genuinely can't fire for the same call (one means the call was never attempted; the other
means it was, and then failed). New `GlobalExceptionHandlerTest` (3 unit tests: the new handler's
`503`/`ApiError` shape, the two exception classes' confirmed disjoint hierarchy, and a regression
check that `handleCircuitBreakerOpen()` still behaves independently) plus a **live spot-check
against a real outage** (not just the unit test): `{"timestamp":"...","status":503,"error":"Service
Unavailable","message":"A dependency (kafka-publish) is currently failing; try again
shortly","details":[]}` — the real body, captured mid-outage, not inferred. Full suite: 91/91 green
(88 pre-existing + 3 new).

**Item 5 — `max.block.ms`, shortened 60000ms → 5000ms — but not for the exact reason the sign-off
brief itself cited, worth stating precisely rather than quietly using the brief's number
anyway.** The brief's own RTO figures were checked against the real docs before trusting them
(per this project's own "Claude Chat has no live repo access, verify before relying on a pasted
figure" lesson) and two of the three didn't hold up:

- **"~2.44s" turned out to be a different metric from a different investigation entirely** —
  `docs/k8s-kafka-ha-scope.md`'s k8s pod-*recreation* time after `kubectl delete pod kafka-1`, not
  a Kafka-client-observed leader-failover RTO. Not a number this decision should have been
  checked against at all.
- **`kafka-leader-failover-rto.sh`'s own reported "~3.7–3.9s"** (`docs/postgres-ha-scope.md`,
  2026-09-03) is real output from a real script, but checking that script's own measurement
  method (not just trusting its printed number) found it still polls via `kafka-topics.sh
  --describe` on a 0.5s sleep — the *exact* ~1s-per-call JVM-spawn-cost measurement artifact this
  project already found and fixed once, in `kafka-ha-demo.sh`'s own sibling Scenario 1 measurement
  (`docs/testing-strategy-ha-supplement.md`'s "RTO variance retest"). `kafka-leader-failover-rto.sh`
  itself was never given the equivalent fix. Its ~3.7–3.9s figure is very likely dominated by that
  same artifact, not real election time — flagged here, not fixed, since re-verifying that
  specific script is outside this task's scope.
- **The trustworthy figure is `kafka-ha-demo.sh`'s own log-tail-based measurement** — reading the
  KRaft controller's actual internal decision timestamp, the version of this measurement this
  project has already scrutinized hardest: **0.098–0.167s across 9 samples in 3 independent
  passes**, corroborated by 3 separate real production runs at 0.115s/0.119s/0.155s
  (`docs/testing-strategy-ha-supplement.md`).

**5000ms clears the real, trustworthy ceiling (0.167s) by roughly 30x** — comfortable margin for a
genuine in-progress leader election (which also transiently can't resolve fresh topic metadata) to
never be misclassified as a stuck call. Deliberately picked at the *higher* end of the brief's own
suggested 3000–5000ms range specifically as a hedge against `kafka-leader-failover-rto.sh`'s
unconfirmed ~3.7–3.9s figure turning out to have some real signal in it after all — 5000ms would
still comfortably exceed that number too, where 3000ms would not. Declared explicitly in
`application.yml` (same "declared, not defaulted" convention as every other value in this file),
with a comment recording this exact reasoning and both citation corrections, not just the final
number. Full suite re-run after the change: still 91/91 green — this is a producer-config value,
not something any existing test asserts a specific timing against.

**Re-verification: the identical primary scenario re-run (150 threads, 150s outage,
`load-tests/results/kafka-cb-loadtest-20260911-114205/`) — real before/after numbers, not a
"seemed fine" close-out:**

| | Before (60000ms) | After (5000ms) |
|---|---|---|
| Status code on the timeout path | `500` (uncaught, generic body) | `503` (`ApiError`, `"A dependency (kafka-publish) is currently failing"`) |
| Time to first breaker open | 60.64s | 39.48s |
| Peak `tomcat_threads_busy_threads` during the outage | `200/200` (100%) | `177/200` (88.5%) |
| Time spent at/near full saturation (`busy≥190`, 2s buckets, over the whole 150s outage) | ~20–30s (two ~10–15s windows) | **0s** — no bucket ever reaches 190 |
| Time spent even moderately elevated (`busy≥170`) | ~20–30s | **~2s total** (one single 2-second bucket, peak 177) |
| Max latency on the slow path | ~60.8s (`500`) | **5893ms** (`503`) — bounded to essentially the new `max.block.ms` ceiling, as designed |
| `503` fast-fail latency once genuinely `OPEN` (unaffected by this change) | mean 58.8ms, p95 116ms | mean 168.9ms, p95 380ms — higher (more reopen/reprobe cycling under the same 150s window, 7 vs. 3, since each cycle now resolves ~12x faster), but still clearly sub-second, no pile-up |

**This is the expected shrink, confirmed rather than assumed** — per the sign-off brief's own
instruction to investigate rather than round to "close enough" if it wasn't clean: the two
full-ceiling saturation bursts are gone entirely (zero 2-second buckets ever reach `busy≥190`
across the whole outage, versus roughly 20–30 cumulative seconds pinned at `200/200` before), and
the worst-case latency on the slow path dropped from ~60.8s to 5.9s — tracking the new
`max.block.ms` ceiling closely, exactly the mechanism this change targets. **The one remaining
~2-second window (`busy=177`, 88.5%) is an expected residual of the same already-understood
mechanism, not a new or partially-understood gap** — stated explicitly so it doesn't read as
ambiguous: it's the very first batch of calls that were already in flight, already past
`tryAcquirePermission()`, before the outage was even detected, so no config change to the breaker
itself could have prevented them from blocking at all; this change only controls *how long* that
first batch blocks (now ≤5s instead of ≤60s), which is exactly what "bound the worst case, don't
eliminate the mechanism" (this section's own stated goal) means in practice. Not chased further.
`time_to_open_s` dropping (60.64s → 39.48s) and `reopen_probe_cycles` rising (3 → 7) are both
side effects of the same change (failures now resolve ~12x faster, so the sliding window fills
sooner and the breaker cycles through open/half-open more times in the same 150s window) — not
independent findings.

**"Open decisions" items 5 and 6: both closed.** Item 5 — shortened to 5000ms, checked against
the real, corrected RTO ceiling (0.167s, ~30x margin) rather than the brief's own uncorrected
citations; re-verified live to actually bound the worst case (60.8s → 5.9s) without eliminating
the underlying mechanism, which was never the goal. Item 6 — `GlobalExceptionHandler` now
explicitly classifies this exception type; confirmed live that a real outage now returns a real
`503`/`ApiError`, not a bare `500`.

Full evidence: `api/src/main/java/com/gridmeter/api/common/GlobalExceptionHandler.java`,
`api/src/test/java/com/gridmeter/api/common/GlobalExceptionHandlerTest.java`,
`api/src/main/resources/application.yml`'s `max.block.ms` comment; re-verification run under
`load-tests/results/kafka-cb-loadtest-20260911-114205/`.

### A severe, pre-existing, unrelated bug found live-testing the Postgres breaker: Postgres outages could silently fabricate `200 OK` responses

**Not a circuit-breaker defect — confirmed by reproducing it on a plain, unmodified
`GET /api/v1/meters` with no breaker or `@Retryable` involved at all.** During a genuine,
sustained, all-3-Patroni-nodes-down outage (a scenario this project had apparently never tested
before — every prior Postgres HA test was failover-focused, where a new primary becomes available
within seconds, not a total, sustained unavailability), an uncaught
`org.springframework.transaction.CannotCreateTransactionException` (HikariCP unable to open a
connection at all) reached Spring MVC's `DispatcherServlet` with no matching resolver, fell through
to `org.springframework.web.util.DisconnectedClientHelper`, and was **misdiagnosed as the HTTP
client having disconnected** — producing a fabricated `200 OK` with `Content-Length: 0`, even
though the real client (`curl`, with a 15–30s timeout) was still connected and waiting the whole
time. This is worse than a timeout or a `500`: a caller sees an apparently-successful response for
a request that never actually completed.

**Root cause, found via `-DEBUG`-level Spring web tracing against a live reproduction**: the exact
log sequence — `o.s.w.s.handler.DisconnectedClient : Looks like the client has gone away:
CannotCreateTransactionException...` immediately followed by `DispatcherServlet : Completed 200
OK` — led directly to `DisconnectedClientHelper`'s source (spring-web 7.0.8). That class explicitly
excludes `org.springframework.dao.DataAccessException` from its "client disconnected" heuristic,
with a comment stating the intent plainly: *"Ignore onward connection issues to other servers (500
error)"* — Spring's own authors clearly anticipated and guarded against exactly this category of
misdiagnosis. But `CannotCreateTransactionException` belongs to a **different** hierarchy,
`org.springframework.transaction.TransactionException`, which is **not** in that exclusion list —
a real, narrow gap in Spring Framework itself, not something this app can patch upstream. The
helper falls through to matching the most-specific cause's message against the phrases "broken
pipe"/"connection reset by peer" — phrasing a genuinely-dead Postgres backend connection can
produce (from the *server*-side socket, not the HTTP client's), which the helper's global,
undiscriminating phrase match conflates with the client's own connection.

**Fixed** in `GlobalExceptionHandler` by adding an explicit `@ExceptionHandler({DataAccessException
.class, TransactionException.class})`, mapped to `503` — this makes `ExceptionHandlerException
Resolver` claim the exception before `DispatcherServlet` ever reaches `DisconnectedClientHelper`'s
ambiguous fallback path. `503`, not `500`, since this is a downstream dependency being
unavailable, not a bug in the app's own code — the same semantic the circuit breaker's own
`CallNotPermittedException` handler already uses.

**Regression test**: `PostgresUnavailableComponentTest`, a dedicated (not `ComponentTestSupport`'s
shared singleton) Testcontainers Postgres, genuinely stopped mid-test. Red/green-verified by
directly, temporarily disabling the fix and re-running: confirmed the test fails predictably
without it. Honest finding along the way, documented in the test's own Javadoc rather than
glossed over: a single stopped Testcontainers container more often produces "connection refused"
for a fresh connection attempt (which doesn't match either phrase, so without the fix this
specific environment reliably surfaces a plain `500` rather than the worse fabricated `200`) than
the "connection reset by peer" wording the real sustained 3-node outage produced live. The
CannotCreateTransactionException path was still reliably reproduced and shown to resolve to the
wrong status without the fix (500, not 503) — a real, provable regression either way, since the
fix is exception-type-based, not message-text-based, and closes both variants regardless of which
one a given environment happens to produce. A small, fixed-size (2-connection) Hikari pool was
needed to reach this exception type deterministically within a handful of calls, since the far
larger production pool size means several already-open pooled connections can each individually
fail with the already-safe `JpaSystemException` first.

**Live re-verification after the fix**: 8 sequential requests against a real, sustained, all-3-
Patroni-nodes-down outage — every single one now returns a real `503` with a proper error body,
zero fabricated `200`s. Confirmed the app fully recovers (real `200`s resume) once Patroni
re-elects a leader.

**Follow-up correction (2026-09-08): the same broad handler this fix added needed its own
more-specific carve-out, one level down from where the lesson above was first written.**
Found re-verifying `docs/k8s-kafka-ha-scope.md`'s kill test, while cleaning up test data:
`DELETE /meters/{id}` on a meter with existing readings threw a `DataIntegrityViolationException`
(the FK constraint on `readings.meter_id` correctly rejecting the delete) — a `DataAccessException`
subtype, so it was silently caught by `handleDatabaseUnavailable` above and reported as `503`
"the database is currently unavailable," indistinguishable to any caller from a genuine outage.
This is the mirror image of the bug this section exists to describe: there, an exception hierarchy
needed to be *added* to stop falling through Spring's own ambiguous fallback; here, a *broader*
handler had grown to cover a case it was never meant to (an ordinary, expected client conflict, not
a database-availability problem). Fixed with a dedicated
`@ExceptionHandler(DataIntegrityViolationException.class)` mapped to `409 Conflict`, declared
separately from the `DataAccessException`/`TransactionException` handler — Spring dispatches by
nearest-match in the exception hierarchy regardless of declaration order, so the more specific
handler wins for this exception type without needing any ordering annotation. New component test
(`MeterApiTestBase.delete_meterWithExistingReadings_returns409NotServiceUnavailable`, run via both
`MeterApiComponentTest` and `MeterApiIT`) — real Postgres, real HTTP layer, real FK violation, not
mocked. Full suite green (80/80) after the fix. **Standing lesson refined, not superseded**: any
future global exception handling in this project should assume both directions of this failure
shape are possible — a hierarchy that's too narrow (falls through to Spring's own ambiguous
fallback) and a hierarchy that's too broad (catches an unrelated, non-outage exception under the
same umbrella) — not just the first one this section originally found.

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

**Correction (2026-09-08): both items below predate the breaker actually
being built (2026-09-04) — see "Circuit breaker: built" at the top of
this doc. Correctness was verified via sequential unit/component tests,
HTTP-level fail-fast latency checks, and live outages; the two plans
below describe what was actually run, not a still-open test plan.**

- **Resilience4j unit tests**: mock a failing dependency, assert the
  breaker opens once `minimum-number-of-calls` and `failure-rate-threshold`
  are both crossed, assert half-open behavior (a bounded number of probe
  calls, closing on success, re-opening on failure). Done.
- **Component test (Testcontainers)**: kill Postgres or Kafka mid-test,
  assert requests fail fast (sub-second, not the old ~30s hang) once the
  breaker is open — this is the test that proves the HikariCP timeout and
  the circuit breaker actually work together, not just that each exists
  independently. Done. **Load-testing thread-pool protection under
  sustained *concurrent* failure — done (2026-09-11), see "Circuit
  breaker: load-tested under sustained concurrent Kafka failure" above.
  Fail-fast correctness is confirmed under real concurrency; the pool
  reaching its full ceiling in bursts tied to the breaker's own
  open/half-open cycling is a real, separate finding, not a test gap.**
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
   **The narrower question this item was standing in for is now resolved
   too (2026-09-11), not left open — see "Circuit breaker: load-tested
   under sustained concurrent Kafka failure" above for the full account.**
   Fail-fast correctness under real concurrency is confirmed (hundreds of
   thousands of real concurrent `503`s, sub-second every time). The
   original "does the breaker protect the thread pool" framing resolves
   to a real, measured **no, not by itself**: under a genuinely
   non-oversubscribed 150-concurrent-thread load, `tomcat_threads_busy_threads`
   reached its full configured ceiling (`200/200`) twice during one
   150-second outage, in bursts tied precisely to the breaker's own
   open/half-open state transitions — driven by calls that already passed
   `tryAcquirePermission()` before getting stuck in Kafka's own
   `max.block.ms`-bounded synchronous block, entirely outside the
   breaker's control once in flight. This is not a defect in the breaker
   itself (its own thresholds and state machine behaved exactly as
   configured) — it's a real, now-measured limit on what a circuit
   breaker gating *new* calls can do about calls that are already stuck.
5. ~~New (2026-09-11): shorten `max.block.ms` (currently 60000ms) to bound
   the per-call worst case found above, or accept it as-is?~~ **Resolved
   (2026-09-11): shortened to 5000ms.** Checked against this project's
   real, most-scrutinized Kafka failover RTO figures first (0.098–0.167s,
   `kafka-ha-demo.sh`'s log-tail-based measurement — ~30x margin), not
   the sign-off brief's own uncorrected citations, two of which didn't
   hold up on verification (see the dated section below for the full
   correction). Re-verified live: the same 150-thread/150s-outage
   scenario now shows zero time at full thread-pool saturation (was
   ~20–30s) and a worst-case slow-path latency of 5.9s (was ~60.8s) — see
   "Circuit breaker: `max.block.ms` shortened + the missing exception
   handler added, re-verified" above for the full before/after.
6. ~~New (2026-09-11): `GlobalExceptionHandler` has no explicit handler
   for a bare Kafka client exception~~ **Resolved (2026-09-11).** Added
   `@ExceptionHandler(KafkaException.class)` (confirmed live which exact
   class is thrown — `org.springframework.kafka.KafkaException`, not
   assumed — before writing it), mapped to `503`/`ApiError`, matching
   this class's existing pattern. Confirmed structurally independent from
   `CallNotPermittedException` (disjoint hierarchies, can never fire for
   the same call) and confirmed live against a real outage that the
   response body is now the real `ApiError` shape, not a bare `500`. See
   the dated section above for the full account, including the new
   `GlobalExceptionHandlerTest`.
