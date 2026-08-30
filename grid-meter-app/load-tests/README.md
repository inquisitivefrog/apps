# load-tests/

JMeter test plans, versioned like code — see `docs/testing-strategy.md` for
where this tier sits (manual/nightly only, never blocks a PR — the coarse
gates below are a blunt trip-wire, not a substitute for a human watching
Grafana while a run happens).

## Prerequisites

- JMeter 5.6.3 on `PATH` (`brew install jmeter` — see
  `docs/tech-stack-versions.md`). `jq` and `awk` (both preinstalled on macOS
  and GitHub's `ubuntu-latest` runners) for `check-thresholds.sh`.
- The stack up: `docker compose up -d traefik api postgres kafka redis`
  (matches `scripts/run-black-box-api-tests.sh` in `api/`'s test tier).
- Before a *real* run (not a quick local smoke check), dial down trace
  sampling — `application.yml` defaults `management.tracing.sampling.
  probability` to 100%, fine for normal dev but not for hundreds of
  requests/sec. Set `GRID_METER_TRACING_SAMPLING_PROBABILITY=0.05` (or
  similar) as an env var on the `api` container before a real steady-state/
  ramp-up/spike-profile/soak run.

## Running a profile

```
./run.sh <steady-state|ramp-up|rapid-spike|gentle-spike|soak> [-Jname=value ...]
```

Writes a timestamped results directory (`results/<profile>-<timestamp>/`,
gitignored — run artifacts, not versioned like the `.jmx` plans themselves)
containing the raw sample log (`results.jtl`), an HTML dashboard
(`report/index.html`), and JMeter's own log. Then runs
`check-thresholds.sh` against the report's `statistics.json` and exits
non-zero if a gate is breached.

Any property (see `config/load-test.properties` and each profile's own
Thread Group defaults below) can be overridden per run, e.g. a fast local
sanity check: `./run.sh rapid-spike -Jduration=15 -JmeterPoolSize=5`.

**`./smoke-test.sh`** runs all five profiles with small/fast overrides back
to back — not a real load test, just a quick "did I break something" check
after editing a fragment or profile.

## Profiles

| Profile | Purpose | Default shape |
|---|---|---|
| `steady-state.jmx` | Realistic sustained traffic, the baseline | 20 threads, 10s ramp, 300s duration, 200ms think time |
| `ramp-up.jmx` | Gradually increasing load, to find the knee of the curve | 0→150 threads over 150s (1 thread/s), holds at peak for the rest of a 300s duration |
| `rapid-spike.jmx` | Sudden burst, to check Traefik/Tomcat behavior under a near-instant shock | Fast ramp (10s) to 600 threads, holds for a 60s duration, no think time |
| `gentle-spike.jmx` | The same target overload as `rapid-spike.jmx`, reached gradually instead — isolates onset speed from sustained overload as separate variables | Gentle ramp (60s) to 600 threads, holds for a 120s duration, no think time |
| `soak.jmx` | Extended duration at moderate load, to catch slow leaks (connection pool exhaustion, unbounded caches) | 35 threads, 30s ramp, 3600s (1hr) duration, 300ms think time |

**Why 600 for the spike profiles**: Spring Boot's embedded Tomcat defaults
to `server.tomcat.threads.max=200` per instance (now explicit in
`application.yml`, not an accident of the parent POM). With 2 replicas
behind Traefik, that's a 400-thread ceiling on total request-handling
capacity before requests queue at `accept-count` (100/instance). A spike
test that stays under that ceiling doesn't actually exercise shock
behavior — 600 is 150% of it, chosen to force visible saturation (queuing,
climbing latency, and whether Traefik/Tomcat degrade gracefully or not)
without being an arbitrary unbounded flood. Both spike profiles target the
same 600 threads; only the ramp speed differs (10s vs. 60s), specifically
to separate "onset shock" from "sustained overload" as two different things
to observe — see the real-run comparison below.

**`rapid-spike` vs. `gentle-spike`, a real comparison**: a clean
`autoscale-demo.sh` run against a single `api` replica (93,162 samples,
1.79% error rate) had its failures bucketed into 5-second windows, showing
**all** errors clustered in
the first 10 seconds — 49.95% then 7.34% error rate, exactly matching
JMeter's own 10s ramp-up window — and **zero errors for the remaining ~80
seconds** of sustained 600-thread load, even before autoscaling's ~15-24s
reaction window had finished scaling out. That's a client-side
thread-creation thundering-herd hitting Tomcat's `accept-count` queue on
arrival, not a sustained-capacity problem — the single replica handled the
*sustained* 600-thread load fine once past that initial burst.
`gentle-spike.jmx` exists to test that read directly: spread the same 600
threads' arrival over 60s instead of 10s, and see whether the burst-driven
errors disappear entirely (supporting the "it's onset speed, not sustained
capacity" reading) or whether some baseline error rate persists regardless
of ramp speed (which would point at real sustained-capacity saturation
instead).

**Answered, at full scale, same single-`api`-replica setup**: `gentle-spike`
produced **92,034 samples, 0.00% errors** (p95 795ms — the coarse latency
gate still fails, as expected under deliberate 600-thread overload on one
replica, but the error rate itself dropped to zero). The slower ramp
eliminated every one of `rapid-spike`'s burst-driven errors entirely —
confirming the "onset speed, not sustained capacity" reading directly,
not just as a hypothesis. Same target load, same replica count, only the
ramp speed changed: `rapid-spike` (10s ramp) → 1.79% errors, all in the
first 10 seconds; `gentle-spike` (60s ramp) → 0.00% errors throughout.

## A third scenario: misconfigured for bursts (`misconfigured-spike-demo.sh`)

Both spike profiles above assume Tomcat's `accept-count` (the queue of
pending *new* connections, separate from `threads.max`) is reasonably
sized — 100, `application.yml`'s explicit default. The third scenario in
this family asks the opposite question: what if it isn't? `server.tomcat.
accept-count` is overridable via `SERVER_TOMCAT_ACCEPT_COUNT` (same pattern
as `GRID_METER_TRACING_SAMPLING_PROBABILITY`) specifically so this can be
demonstrated without editing the app.

`./misconfigured-spike-demo.sh` runs the identical burst against a single
`api` replica twice — once at the proper default (`accept-count=100`), once
deliberately under-provisioned (`accept-count=5`) — and reports the
contrast, with dashboard/alerting screenshots and a resource log for both
phases (same evidence pattern as `chaos-demo.sh`/`autoscale-demo.sh`).

**A real surprise while building this, worth recording rather than
smoothing over**: the first attempt reused `rapid-spike.jmx`'s own 10s-ramp
default at full scale (600 threads) and found the contrast had nearly
vanished — 0.00% vs. 0.019% errors, pure noise. The reason: `accept-count`
only bounds the queue of pending *new* connections; every profile already
runs with HTTP keep-alive on, so once a thread's connection is established
it never touches that queue again for the rest of the run. A 10-second
ramp turned out to be gentle enough that even a 5-slot queue drains as fast
as it fills. The queue only gets meaningfully stressed by how *sharp* the
connection-establishment burst is, not by the eventual thread count — so
the script overrides the ramp down to ~1 second (`SPIKE_RAMP`), a genuinely
sharp onset, while keeping the profile's own `POST /readings` request
otherwise untouched.

**Two real validation runs, both confirmed**, single `api` replica,
identical 400-thread/~1s-ramp/10s-duration burst each time, only
`accept-count` changed:

| Phase | Samples | Error rate | p95 | Failure type |
|---|---|---|---|---|
| `accept-count=100` (default) | 2,318–19,422 | 0.00% both runs | 3.6–4.6s | — the queue absorbs the burst, just slowly |
| `accept-count=5` (misconfigured) | 1,799–37,296 | 7.62%–8.61% | 1.0–4.5s | 100% `502 Bad Gateway` — genuine connection refusals once the undersized queue overflowed |

Same load, same everything else, only the queue size changed — a clean,
reproducible demonstration of why `accept-count` is a real capacity-
planning knob and not a cosmetic default. `misconfigured-spike-demo.sh`
restores `api` to the proper default in its cleanup trap regardless of how
the run ends, so the stack is never left running the deliberately-broken
config.

**Why `misconfigured-spike-demo.sh` never got its alert to fire — three
real attempts, told honestly**: the goal was screenshots showing not just
the numeric contrast above but Grafana's `High HTTP error rate` alert
actually firing. A single sharp burst is too brief (~10-14s) for that
alert's `for: 30s` sustained-duration requirement, so three different ways
of sustaining the bad behavior longer were tried, in order:

1. **Loop the same sharp burst back to back.** Real run: the error rate
   decayed steadily across iterations (4.36% → 6.82% → 5.70% → 2.24% → ...
   → under 1% by the 8th loop) while sample counts climbed 1,791 → 28,000+.
   Root cause: JVM/JIT warm-up. Every profile's own measurement window has
   the identical problem, which is exactly why `common/warmup.jmx` (above)
   exists now — a warmed JVM processes requests fast enough to drain even
   a 5-slot queue regardless of the misconfiguration, so looping bursts
   against the same persistent process measures a moving target.
2. **Sustain via a long run with HTTP keep-alive disabled**
   (`misconfigured-burst.jmx`), so every request opens a fresh connection
   for the whole duration instead of only at onset. Real run: 0.27% errors
   over 90s — barely different from the properly-configured baseline. This
   revealed something not obvious going in: the vulnerability is about
   *onset sharpness* (many connections arriving near-simultaneously), not
   *connection churn volume* over time. Spreading the same total number of
   new connections across 90 seconds, even continuously, never builds up
   enough instantaneous backlog to overwhelm a 5-slot queue, because
   Tomcat's acceptor drains it about as fast as it arrives.
3. **Loop the sharp burst again, but recreate `api` (a cold JVM) before
   every iteration**, combining what worked in #1 (sharp onset) while
   countering what broke it (JVM warm-up). Real run, 10 cold-reset
   iterations: aggregate 2.02% errors — still below the 5% threshold, and
   still lower than a single burst's 7.6-8.6%, for reasons not fully
   pinned down (each reset briefly re-registers with Traefik and the
   Prometheus counters reset to zero on every restart, both plausible
   contributors).

None of the three tripped the alert. First conclusion, before a follow-up
diagnostic changed the picture: Tomcat's connector, backed by the OS TCP
stack, is mature and well-tuned for anything except a genuinely
simultaneous burst meeting a cold process, and the alert's `for: 30s` + 5-
minute rate window is deliberately built to ignore exactly this kind of
brief, self-resolving blip, not a gap.

**The follow-up that overturned half of that conclusion**: asked to
confirm by lowering the alert's threshold, first checked what the alert's
own expression actually computed after a fresh burst with a real 9%
application-level error rate, rather than assume a lower number would
help. It read **0% the entire time** — not diluted, structurally zero.
Root cause: `502`s from an accept-count-queue overflow are generated by
**Traefik**, not the Spring app — a connection Tomcat refuses never
reaches `DispatcherServlet` at all, so Micrometer's
`http_server_requests_seconds_count` metric never records it, as a
success or a failure. `High HTTP error rate` is built entirely on that
metric, so it's structurally blind to this failure class at *any*
threshold — the "correct outcome" conclusion above was right about the
alert's sustained-duration design filtering brief blips, but wrong about
there being no real gap underneath it.

**Fixed with a genuinely different signal source**: enabled Traefik's own
Prometheus exporter (`--metrics.prometheus=true`), added it as a second
Prometheus scrape target, and added a new `High Traefik edge error rate`
alert rule (`observability/alerting/rules.yml`) on
`traefik_service_requests_total{service="api@docker", code=~"5.."}` — a
metric Traefik itself populates regardless of whether the request ever
reached the app. Verified for real, not assumed: a fresh cold-JVM burst
(600 threads, `accept-count=2`, 20.2% application-level error rate)
produced a real `Normal → Pending → Firing` transition within the
expected ~30-40s, screenshotted with **`High Traefik edge error rate`
firing while all three app-level alerts stayed Normal** — direct visual
proof of the gap and the fix in one image. The real, validated numeric
contrast earlier in this section stands as evidence either way; this
closes out the part of the story that numeric contrast alone couldn't
tell.

**Real-scale validation** (all four profiles, 2 `api` replicas, full
defaults — see the "Real-scale validation results" section below for
numbers): set up via `docker compose up -d --scale api=2` plus
`GRID_METER_TRACING_SAMPLING_PROBABILITY=0.05` on both replicas (confirmed
identical via `docker inspect`, not assumed — a first attempt using
`--no-recreate` left one replica at the default 100% sampling while only
the other picked up the override). rapid-spike's max response time (3560ms,
climbing from an ~85-99ms baseline average) is the real saturation signal
this profile exists to produce. These runs were unattended (no Prometheus/
Grafana stack up alongside them), so `tomcat.threads.busy`/
`tomcat.connections.current` weren't directly observed — the saturation
evidence is the response-time climb from the JMeter side, not a live
Tomcat-metrics confirmation. An earlier short (15s), single-replica smoke
run of rapid-spike at the same 600-thread default showed the same pattern
(85ms baseline → 1474ms max) — consistent across both runs, not a fluke of
either one. (At the time of this run, the profile was still named
`spike.jmx`, later relabeled `rapid-spike.jmx` when `gentle-spike.jmx` was
added — same test, same numbers, new name.)

**`api`'s memory limit, bumped and reverified**: an earlier autoscale-demo.sh
run under sustained 2-replica load showed `api-2` pinned at a literal
100.00% of its then-512m limit via `docker stats` — didn't OOM that run,
but the margin was uncomfortably thin (`-Xmx384m` left only 128MB for
everything else: metaspace, 200 Tomcat threads' stacks, JIT code cache,
direct buffers). Bumped `docker-compose.yml`'s limit to 768m (heap max
unchanged) and reverified with the identical scenario: a real full-scale
rapid-spike run against 2 replicas, memory polled via `docker stats` every
5s throughout. Result: memory stayed between 40-67% the whole run (peak
67.24% on `api-2`), under the same real 100%+ CPU pressure as before —
comfortable headroom where there was previously none.

**What to watch in Grafana during the spike profiles/soak**:
`tomcat.threads.busy`, `tomcat.threads.current`, and
`tomcat.connections.current` (Micrometer/Actuator, already scraped via
`/actuator/prometheus` — no extra wiring needed) alongside JVM heap and the
Kafka/Postgres/Redis panels. Tomcat's own saturation is a first-class
signal here, not just an infra afterthought — the whole point of the spike
profiles is watching it happen.

## Why chaos-demo.sh's postgres outage didn't originally trip an alert

A real re-test (see "user asked to re-confirm all three demo scripts" in
`status/`) found `High HTTP error rate` and `Tomcat thread pool saturated`
didn't fire during `chaos-demo.sh`'s postgres-outage step, even though
`API is down` fired correctly for the api-outage step in the same run.
Checked the actual JMeter response times during the outage window rather
than guess: throughput collapsed from ~480 samples/5s down to just 20,
with average latency climbing to ~25s and one request measured at exactly
**30107ms**. Not a coincidence — Spring Boot's HikariCP connection pool
defaults `connection-timeout` to exactly 30 seconds, and `application.yml`
had no `spring.datasource.hikari.*` block at all, so that default applied
untouched. `ReadingService.ingest()` calls `meterRepository.existsById()`
synchronously before publishing to Kafka, so every thread needing a
connection during the outage blocked for up to 30s instead of failing —
collapsing throughput (masking the real failure count) rather than
producing a clean, alertable error-rate spike. The app absorbed a real
outage as latency, not as visible errors.

**Fixed by declaring HikariCP's settings explicitly in `application.yml`**
(same reasoning already applied to `server.tomcat.threads.max`/
`accept-count` in the same file — discoverable and tunable, not an
unlisted default), with `connection-timeout` deliberately shortened from
30s to 5s. Rebuilt the `api` image and re-tested the identical scenario
(steady-state background load, stop Postgres for ~45s, restart): requests
now fail in ~5s instead of hanging up to 30s, throughput stays sustained
during the outage (100% failure rate, ~20 samples/5s continuously for
55+ seconds) instead of collapsing, and **both `High HTTP error rate` and
`High Traefik edge error rate` fired for real** — confirmed via Grafana's
alert state history, not assumed from the config change alone.

**A valid pushback on the 5s timeout, and the more complete fix it led
to**: shortening `connection-timeout` from 30s to 5s was questioned as
possibly optimizing for this demo rather than general production
practice — 30s is HikariCP's deliberate default specifically to tolerate
a brief HA failover or a momentary pool squeeze without converting it
into a hard, user-facing error. Fair, and correct for a database layer
that actually has something to fail over to; this project's Postgres is a
single, unclustered instance (`docker-compose.yml`), so there's nothing
to wait for during a real outage here — but the general point stands for
a real deployment. The actual production-grade answer isn't "pick a
smaller timeout," it's decoupling how long *one attempt* waits from how
long the *request* tolerates a blip: `ReadingService.ingest()`'s
`meterRepository.existsById()` call now has `@Retryable` (Spring Retry,
`spring-retry` — not managed by this project's Spring Boot BOM, needed an
explicit version), 3 attempts with a 200ms/2x exponential backoff.

**A second real exception-targeting bug, found by actually testing the
retry rather than trusting the annotation compiled**: the first attempt
scoped `retryFor` to `TransientDataAccessException`/
`CannotCreateTransactionException` — the two Spring exception types
that cover "can't acquire a *new* pooled connection," matching the
original chaos-demo scenario. A live test (kill Postgres mid-request,
restart it 2s later, confirm the request still succeeds) instead got an
immediate 500 in 94ms — far too fast to be the 5s connection-timeout
engaging, meaning the retry never fired at all. The actual exception, from
the api logs: `JpaSystemException: Unable to rollback against JDBC
Connection` (root cause: `SQLException: Connection is closed`, from an
*already-open* pooled connection that Postgres killed server-side on
shutdown) — a different, and empirically more common, failure mode than
"can't get a new connection," and one Spring's own hierarchy classifies
as non-transient by default despite genuinely being transient here. Added
`JpaSystemException` to `retryFor` explicitly and re-ran the identical
live test: the request that previously failed in 94ms now succeeds in
~3.2s (`HTTP_CODE:201`) — the retry absorbed the outage and the client
never saw a failure at all.

**Migrated off `spring-retry` entirely once a real gap in the initial
implementation surfaced**: this project's own scoping docs (a parallel
architecture-discussion thread) pointed out that Spring Boot 4 ships its
*own* native `@Retryable`/`@ConcurrencyLimit` annotations
(`org.springframework.resilience.annotation`, Spring Framework 7.0+,
enabled via `@EnableResilientMethods`) — no external library needed at
all, since the mechanism lives in `spring-context`, already a required
dependency regardless. Verified this wasn't just a plausible-sounding
claim before acting on it: found both classes for real in the installed
`spring-context-7.0.8.jar`, then pulled the actual sources jar
(`mvn dependency:get -Dclassifier=sources`) to read the real Javadoc
rather than guess at attribute semantics (`maxRetries` counts retries
*after* the initial attempt, unlike `spring-retry`'s `maxAttempts` which
counts the initial attempt too — `maxRetries=2` is the equivalent of the
`maxAttempts=3` used above). Migrated `ingest()`'s `@Retryable` to the
native annotation, removed the `spring-retry` dependency (and its
unmanaged-version workaround) from `pom.xml` entirely, and re-ran the
identical live Postgres-kill test again: `HTTP_CODE:201` in ~3.19s,
matching the `spring-retry` version's behavior almost exactly. All 53
existing tests still pass. Net effect: same resilience behavior, one
fewer dependency, matching this project's stated minimal-scope ethos —
and a good reminder that a working `@Retryable`+external-library
implementation doesn't mean it was the leanest available option for a
Spring Boot 4 project specifically.

## How each profile is built

- **`common/login.jmx`** — shared Test Fragment: logs in as the seed demo
  user (`demo`/`GridMeter!Demo2026`, see `docs/api-and-data-model.md`) and
  stashes the access token as a **JMeter Property** (`props`, via a
  JSR223 PostProcessor) rather than a Variable. Variables are per-Thread-
  Group; Properties are the only thing shared across the separate setUp
  Thread Group and the main load-generating Thread Group.
- **`common/provision-meters.jmx`** — shared Test Fragment: creates a pool
  of meters via `POST /meters` (size: `meterPoolSize`, default 10) and
  writes each returned id to a CSV file (`meterCsvPath`, default
  `results/meter-pool.csv`) that the main Thread Group's CSV Data Set
  Config reads `meterId` from per-iteration. Keeps every profile
  self-contained — no manual DB seeding before a run, and no hardcoded
  UUIDs that would drift from whatever's actually in the database.
- **`common/warmup.jmx`** — shared Test Fragment, pulled in after
  provision-meters: fires `warmupIterations` (default 50) sequential
  throwaway `POST /readings` requests, labeled `WARMUP: POST /readings` so
  they're easy to spot/exclude if ever needed, before the profile's real
  measurement window starts. A cold JVM (before JIT compilation, connection
  pool/cache population) behaves measurably differently under load than a
  warmed one — standard practice for any Java performance test whose goal
  is a representative steady-state average is to warm up first and treat
  cold-start behavior as separate from the real measurement, not let it
  skew the reported numbers. **Deliberately not included in
  `misconfigured-burst.jmx`** (used by `misconfigured-spike-demo.sh`) —
  that scenario's whole point is testing a cold JVM's behavior on purpose
  (the realistic case is a freshly-started replica meeting a burst during
  autoscaling scale-out or a rolling deploy), so warming it up first would
  defeat the test. This exact distinction came out of a real investigation
  — see "Why `misconfigured-spike-demo.sh` never got its alert to fire"
  below.
- All three fragments are pulled into each profile's **setUp Thread
  Group** via an **Include Controller** (not a Module Controller, which
  only works within a single tree — Include Controller is what lets five
  separate `.jmx` files share one login/provisioning/warm-up sequence
  without copy-pasting it five times and letting them drift).
- The main Thread Group then runs `POST /readings` — the endpoint JMeter
  hammers per `docs/api-and-data-model.md` — using the Authorization header
  set from the login fragment's Property and a `meterId` drawn from the
  CSV pool.

## Gates (`check-thresholds.sh`)

```
./check-thresholds.sh <statistics.json> [max-error-pct=1] [p95-ceiling-ms=500]
```

Reads a JMeter HTML dashboard report's `statistics.json` directly —
deliberately outside JMeter itself (not a Backend Listener, which is built
for streaming live metrics to something like InfluxDB, not post-run
pass/fail logic) — and checks `Total.errorPct` and `Total.pct2ResTime`
(JMeter's default percentile mapping is pct1=90th/pct2=95th/pct3=99th, so
this genuinely is the p95, not a guess) against the thresholds. `run.sh`
calls it automatically after every run.

## CI

Wired as `.github/workflows/grid-meter-app-load-test.yml` —
`workflow_dispatch` (profile picker + duration override) and a nightly
steady-state smoke. Verified with a real triggered run on GitHub's own
runners (2,470 samples, 0% errors, 8ms p95), which is what surfaced the
Java 21 requirement below. **Not yet verified**: the true `schedule`
trigger itself only fires at its scheduled time — what's actually been
confirmed is the `workflow_dispatch` path, where `github.event.inputs`
always exists with defaults populated even without explicit `-f` flags.
The `github.event.inputs.profile` fallback the workflow uses for a
schedule event (which has no `inputs` object at all) is written
defensively in bash (`${PROFILE:-steady-state}`, not relying on GitHub's
own expression-level `||`) specifically because that exact path hasn't
been exercised by a real cron firing yet.

## Real-scale validation results

All five profiles have now been run at their full documented scale (full
default thread count/duration, no `-J` overrides); four at 2 `api`
replicas in the same session, `gentle-spike` at a single replica to match
the `rapid-spike` comparison above:

| Profile | Samples | Error rate | p95 | Notes |
|---|---|---|---|---|
| `steady-state` | 28,441 | 0% | 11ms | Clean baseline |
| `ramp-up` | 165,241 | 0.0006% (1 error) | 10ms | Isolated single error, not investigated further |
| `rapid-spike` | 348,697 | 0% | 164ms (max 3560ms) | Real saturation signal — see above (run before this profile was relabeled from `spike`) |
| `gentle-spike` | 92,034 | 0% | 795ms | Run at full default scale against a **single** `api` replica (not 2, to match the `rapid-spike` comparison above) — see above |
| `soak` | 340,304 | 0.031% | 8ms (max 268ms) | See token-TTL note below — no leak/exhaustion signal otherwise |

**`soak`'s error burst, explained, not just noted**: 105 of soak's errors
(all of them) were `401 Unauthorized`, all firing within a ~23ms window
across all 35 threads simultaneously, at the exact moment the run's
1-hour duration elapsed. This is not an app bug — `soak.jmx` logs in once
at the start via `common/login.jmx` and never re-authenticates, and the
JWT's TTL is a documented, deliberate 60 minutes with **no refresh token**
(see `docs/architecture.md`'s "Authentication" section — a token expiring
mid-session is an accepted tradeoff for this project's scope). A soak run
at or beyond 60 minutes will always show this same tail-end 401 burst by
design; it's the documented auth tradeoff actually manifesting in a real
test for the first time, not a defect in the app or the test. Decided
(2026-08-24) to document this rather than add mid-run re-authentication to
`soak.jmx` — keeps the test's purpose (leak/exhaustion detection) separate
from re-exercising a tradeoff that's already covered by the auth test
suite.

## Kafka HA demo (`kafka-ha-demo.sh`)

Exercises `docs/ha-scope.md`'s three stated test goals against the real
3-broker KRaft cluster (`docker-compose.yml`'s `kafka-1`/`kafka-2`/
`kafka-3`): tolerate-one-broker-loss, two-broker quorum-loss, and rolling
maintenance (restart all three, one at a time). Deliberately lighter than
`chaos-demo.sh`/`misconfigured-spike-demo.sh` — no Playwright screenshots;
evidence is real HTTP status codes plus `kafka-topics.sh --describe`'s
actual replica/ISR state, which answers "did this work, and why" more
directly for a broker-quorum question than a dashboard screenshot would.

**Real run (2026-08-27/28)**: scenario 1 (tolerate one broker loss) — 20/20
succeeded, zero impact, confirming RF=3's whole point. Scenario 3 (rolling
maintenance) — 30/30 succeeded across all three sequential restarts, zero
downtime, the actual payoff of "3, not 2" quorum math.

**Correction/strengthening (2026-08-30)**: the original run's zero-downtime
result was real, but the script's own narration ("waiting for the broker to
rejoin and catch up" after a fixed 8s sleep) overclaimed what that wait
actually achieved. Measured directly across two full re-runs: real
ISR-rejoin time per broker restart is **13-30 seconds**, 2 to nearly 4x the
assumed 8s — not a bug in the *outcome* (0 failures held every time,
confirmed twice), but the test's own account of *why* was wrong. The real
explanation is stronger than what was originally claimed: zero client
impact was demonstrated **while a broker was still mid-rejoin**, not after
quiet convergence — direct proof that `min.insync.replicas=2` provides
real margin during a slow rejoin, not just against a broker that's already
fully caught up. `kafka-ha-demo.sh` now measures and reports the real
convergence time per restart instead of assuming it.

**Scenario 2 (two-broker quorum loss), first attempt (~15-20s outage)**:
10/10 requests returned `201`, and a direct Postgres query afterward
confirmed all 10 readings landed durably — zero visible failure anywhere,
even though the cluster was genuinely below the 2-of-3 majority it needs.
This was *not* evidence quorum loss is harmless, just an outage window too
short to prove anything: `ReadingService.ingest()`'s `kafkaTemplate.send()`
only blocks synchronously on **metadata** fetch (bounded by `max.block.ms`,
declared explicitly at 60000ms); the actual delivery retry runs in the
background under `delivery.timeout.ms` — an **undeclared** client default
of 120000ms — and a ~15-20s outage is well inside that budget, so
background retries silently absorbed it once brokers came back.

**Scenario 2, re-run with the outage extended to 150s (past the 120s
`delivery.timeout.ms` budget) — CONFIRMED real, permanent data loss.**
All 10 readings sent during the outage were lost forever: 0 landed while
still below quorum, 0 more landed after brokers recovered, `total 0 of
10`. The api container's own logs show the exact mechanism, not a guess:

```
org.apache.kafka.common.errors.TimeoutException: Expiring 8 record(s) for readings-0:120001 ms has passed since batch creation
```

(all expirations against `readings-0` specifically — the default
partitioner hashes by key, and every reading in this test used the same
meter ID, so every send landed on the same partition). Throughout the
entire 150s outage, every one of the 10 `POST /readings` calls still
returned `201 Created` — the app told the client "created successfully"
for data that was, at that exact moment, permanently gone. This is a real
silent-data-loss bug, not a hypothetical: `ReadingService.ingest()` never
checks the `Future`/callback `kafkaTemplate.send()` returns, so a
producer-side delivery failure has no path back to the caller, and nothing
logs it either beyond the raw Kafka client's own internal `Sender` thread
warning (which nothing in the app's own log aggregation currently treats
as actionable). Two concrete fixes, neither done yet: (1) declare
`delivery.timeout.ms` explicitly (matching the `max.block.ms` precedent)
so how long a quorum-loss incident can silently eat writes is a real,
documented decision rather than an accident of an undeclared default; (2)
add a `whenComplete`/`ProducerListener` callback on the `send()` call so a
delivery failure becomes a real, actionable server-side signal (a metric,
a log line CI/alerting can catch) instead of disappearing into a discarded
`Future`.
