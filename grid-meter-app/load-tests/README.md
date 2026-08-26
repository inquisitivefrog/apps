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
instead). Not yet run at full scale — this is the hypothesis it's designed
to test, not a result yet.

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

**What to watch in Grafana during the spike profiles/soak**:
`tomcat.threads.busy`, `tomcat.threads.current`, and
`tomcat.connections.current` (Micrometer/Actuator, already scraped via
`/actuator/prometheus` — no extra wiring needed) alongside JVM heap and the
Kafka/Postgres/Redis panels. Tomcat's own saturation is a first-class
signal here, not just an infra afterthought — the whole point of the spike
profiles is watching it happen.

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
- Both fragments are pulled into each profile's **setUp Thread Group** via
  an **Include Controller** (not a Module Controller, which only works
  within a single tree — Include Controller is what lets four separate
  `.jmx` files share one login/provisioning step without copy-pasting it
  four times and letting them drift).
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

Four of the five profiles have now been run at their full documented scale
(2 `api` replicas, full default thread count/duration, no `-J` overrides),
in the same session:

| Profile | Samples | Error rate | p95 | Notes |
|---|---|---|---|---|
| `steady-state` | 28,441 | 0% | 11ms | Clean baseline |
| `ramp-up` | 165,241 | 0.0006% (1 error) | 10ms | Isolated single error, not investigated further |
| `rapid-spike` | 348,697 | 0% | 164ms (max 3560ms) | Real saturation signal — see above (run before this profile was relabeled from `spike`) |
| `gentle-spike` | — | — | — | Not yet run at full scale — added to isolate onset speed from sustained overload, see above |
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
