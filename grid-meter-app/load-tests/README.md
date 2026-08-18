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
  ramp-up/spike/soak run.

## Running a profile

```
./run.sh <steady-state|ramp-up|spike|soak> [-Jname=value ...]
```

Writes a timestamped results directory (`results/<profile>-<timestamp>/`,
gitignored — run artifacts, not versioned like the `.jmx` plans themselves)
containing the raw sample log (`results.jtl`), an HTML dashboard
(`report/index.html`), and JMeter's own log. Then runs
`check-thresholds.sh` against the report's `statistics.json` and exits
non-zero if a gate is breached.

Any property (see `config/load-test.properties` and each profile's own
Thread Group defaults below) can be overridden per run, e.g. a fast local
sanity check: `./run.sh spike -Jduration=15 -JmeterPoolSize=5`.

**`./smoke-test.sh`** runs all four profiles with small/fast overrides back
to back — not a real load test, just a quick "did I break something" check
after editing a fragment or profile.

## Profiles

| Profile | Purpose | Default shape |
|---|---|---|
| `steady-state.jmx` | Realistic sustained traffic, the baseline | 20 threads, 10s ramp, 300s duration, 200ms think time |
| `ramp-up.jmx` | Gradually increasing load, to find the knee of the curve | 0→150 threads over 150s (1 thread/s), holds at peak for the rest of a 300s duration |
| `spike.jmx` | Sudden burst, to check Traefik/Tomcat behavior under shock | Fast ramp (10s) to 600 threads, holds for a 60s duration, no think time |
| `soak.jmx` | Extended duration at moderate load, to catch slow leaks (connection pool exhaustion, unbounded caches) | 35 threads, 30s ramp, 3600s (1hr) duration, 300ms think time |

**Why 600 for spike**: Spring Boot's embedded Tomcat defaults to
`server.tomcat.threads.max=200` per instance (now explicit in
`application.yml`, not an accident of the parent POM). With 2 replicas
behind Traefik, that's a 400-thread ceiling on total request-handling
capacity before requests queue at `accept-count` (100/instance). A spike
test that stays under that ceiling doesn't actually exercise shock
behavior — 600 is 150% of it, chosen to force visible saturation (queuing,
climbing latency, and whether Traefik/Tomcat degrade gracefully or not)
without being an arbitrary unbounded flood.

**What to watch in Grafana during spike/soak**: `tomcat.threads.busy`,
`tomcat.threads.current`, and `tomcat.connections.current` (Micrometer/
Actuator, already scraped via `/actuator/prometheus` — no extra wiring
needed) alongside JVM heap and the Kafka/Postgres/Redis panels. Tomcat's
own saturation is a first-class signal here, not just an infra afterthought
— the whole point of the spike profile is watching it happen.

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

## Not yet wired

- **CI**: `workflow_dispatch`/nightly per `docs/testing-strategy.md`'s plan
  — not wired into `.github/workflows/grid-meter-app-ci.yml` yet.
- These profiles hit a single `api` replica in the default local
  `docker compose up` (only `--scale api=2` gives the full 400-thread
  ceiling assumed above); run with `docker compose up --scale api=2` for a
  spike run that's actually testing what the ceiling math describes.
