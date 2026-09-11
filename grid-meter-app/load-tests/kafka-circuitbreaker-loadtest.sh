#!/usr/bin/env bash
# Load-tests the kafka-publish circuit breaker's thread-pool protection under SUSTAINED CONCURRENT
# Kafka failure -- the one piece docs/resilience-scope.md's "Circuit breaker: built" section names
# as still open: every prior verification (unit tests, ReadingIngestCircuitBreakerLatencyComponentTest,
# live outages) was sequential, one call at a time. This drives real concurrent POST /readings
# traffic (via kafka-outage-concurrent.jmx, not a curl loop like kafka-ha-demo.sh -- this scenario
# specifically needs many requests genuinely in flight at once, which curl's own serial loop can't
# produce) straight through a real all-3-broker Kafka outage and measures, at high resolution:
#
#   (a) does resilience4j.circuitbreaker.instances.kafka-publish open before Tomcat's thread pool
#       (server.tomcat.threads.max=200, application.yml) saturates, or does the ramp-up window
#       (minimum-number-of-calls=10 calls before the breaker can even consider opening) let enough
#       concurrent requests pile up first?
#   (b) once open, does concurrent traffic actually get shed fast via the already-verified
#       CallNotPermittedException -> 503 path, or does something (e.g. lock contention inside
#       Resilience4j's own state machine) still cause pile-up under real concurrency?
#
# Scope: Kafka only, not Postgres -- Postgres already has a clean, proven full-outage story from
# Stage 7 of docs/postgres-ha-scope.md (see docs/resilience-scope.md's Open Decisions item 4).
#
# Instrumentation: reads api's own /actuator/prometheus directly (the same series Prometheus itself
# scrapes, per docs/architecture.md's Observability section) via kafka-cb-loadtest-poller.py, at a
# far finer interval than Prometheus's own 15s scrape_interval (observability/prometheus.yml) --
# that interval is far too coarse to catch a breaker that can plausibly open in well under a
# second. No new tooling beyond reading the existing metrics faster.
#
# Prerequisites: full stack up (docker compose up -d), single api replica (this script forces that
# via --scale api=1, same as misconfigured-spike-demo.sh's reset_api, for a clean single-instance
# signal matching every other app-level HA test script in this project).
#
# Usage: load-tests/kafka-circuitbreaker-loadtest.sh
#   Tune via THREADS / RAMP_UP / PRE_KILL_SECONDS / OUTAGE_SECONDS / RECOVERY_SECONDS env vars.
#   Results (JMeter .jtl/report, the poller's raw CSV, and a JSON analysis) land in
#   load-tests/results/kafka-cb-loadtest-<timestamp>/.
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1
source scripts/check-no-stray-traffic.sh || exit 1

THREADS="${THREADS:-300}"
RAMP_UP="${RAMP_UP:-3}"
PRE_KILL_SECONDS="${PRE_KILL_SECONDS:-15}"
# 150s, not a round "long enough" guess -- matches kafka-ha-demo.sh's own Scenario 2 durability
# test, which found the client-side delivery.timeout.ms default (120000ms, undeclared at the time,
# now declared explicitly in application.yml) silently absorbs any outage shorter than that via
# background retries once brokers return. This script's own first (too-short, 8s) smoke run
# reproduced exactly that: every sample succeeded (201) with no breaker activity at all, because
# nothing had failed for real yet -- 150s (120s + 30s margin, same margin kafka-ha-demo.sh uses)
# is required to see genuine kafka-publish breaker failures, not an outage long enough by
# assumption. See docs/resilience-scope.md's dated findings section for the full account.
OUTAGE_SECONDS="${OUTAGE_SECONDS:-150}"
RECOVERY_SECONDS="${RECOVERY_SECONDS:-60}"
BUFFER_SECONDS=15
TOTAL_DURATION=$(( PRE_KILL_SECONDS + OUTAGE_SECONDS + RECOVERY_SECONDS + BUFFER_SECONDS ))

RUN_DIR="load-tests/results/kafka-cb-loadtest-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN_DIR"

# Never leave the stack on this script's own reduced-tracing-sampling override (set below, so a
# real high-volume run doesn't flood Tempo) if the script exits early for any reason.
cleanup() {
  docker compose up -d --scale api=1 api >/dev/null 2>&1 || true
}
trap cleanup EXIT

banner() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

banner "Setup: single api replica, reduced tracing sampling, fresh breaker state"
# A fresh api instance also means a fresh (CLOSED, zero-count) kafka-publish breaker -- this run's
# numbers shouldn't be polluted by whatever an earlier session's testing already did to it.
GRID_METER_TRACING_SAMPLING_PROBABILITY=0.05 docker compose up -d --scale api=1 api
./scripts/wait-for-health.sh "http://localhost/actuator/health" 60 || {
  echo "api never became healthy -- aborting." >&2
  exit 1
}

echo "Confirming /api/v1/auth/login is reachable through Traefik (same check as"
echo "misconfigured-spike-demo.sh's reset_api -- /actuator/health passing doesn't prove Traefik has"
echo "finished registering a just-recreated container as a live backend)..."
LOGIN_READY=0
for i in $(seq 1 10); do
  code=$(curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost/api/v1/auth/login \
    -H 'Content-Type: application/json' \
    -d '{"username":"demo","password":"GridMeter!Demo2026"}')
  if [ "$code" = "200" ]; then
    LOGIN_READY=1
    break
  fi
  echo "  attempt $i: got HTTP $code, retrying..."
  sleep 2
done
if [ "$LOGIN_READY" -ne 1 ]; then
  echo "Login through Traefik never returned 200 -- aborting rather than launching load against an unready edge." >&2
  exit 1
fi

echo "Confirming the kafka-publish breaker starts CLOSED (sanity check, not assumed)..."
CLOSED_VAL=$(curl -s http://localhost/actuator/prometheus | \
  grep -oE 'resilience4j_circuitbreaker_state\{name="kafka-publish",state="closed"\} [0-9.]+' | \
  awk '{print $2}')
if [ "$CLOSED_VAL" != "1.0" ]; then
  echo "kafka-publish breaker is not reporting CLOSED=1.0 (got '$CLOSED_VAL') before the run even starts -- aborting." >&2
  exit 1
fi
echo "  confirmed: kafka-publish breaker is CLOSED, 0 prior calls (fresh instance)."

banner "Starting kafka-outage-concurrent.jmx (${THREADS} threads, ${RAMP_UP}s ramp, ${TOTAL_DURATION}s duration)"
(
  cd load-tests
  jmeter -n -t kafka-outage-concurrent.jmx -q config/load-test.properties \
    -Jthreads="$THREADS" -JrampUp="$RAMP_UP" -Jduration="$TOTAL_DURATION" \
    -l "../$RUN_DIR/results.jtl" -e -o "../$RUN_DIR/report" \
    -j "../$RUN_DIR/jmeter.log"
) &
JMETER_PID=$!

# Do NOT assume a fixed sleep covers the SetupThreadGroup's own login+meter-provisioning+50-request
# warmup (common/login.jmx, provision-meters.jmx, warmup.jmx) -- per this project's own standing
# "poll for the actual readiness condition, don't assume a fixed sleep" lesson
# (docs/testing-strategy.md). Confirmed the hard way in this script's own dry run: a too-short fixed
# wait let Kafka get killed WHILE the warmup phase's own real POST /readings calls were still in
# flight, contaminating the very baseline this pre-kill window exists to establish and (because
# serialize_threadgroups=true means the main load group can't even start until setUp finishes)
# silently shifting the whole outage window onto samples that were never the intended "steady
# concurrent load" traffic at all. Poll the growing results.jtl for the first sample carrying the
# main Thread Group's own label ("POST /readings", not warmup.jmx's "WARMUP: POST /readings")
# instead of guessing how long setup takes.
echo "Waiting for the main load Thread Group's own traffic to actually start (not warmup) before"
echo "starting the poller or the pre-kill countdown..."
READY=0
for i in $(seq 1 300); do
  if [ -f "$RUN_DIR/results.jtl" ] && awk -F, 'NR>1 && $3=="POST /readings" {found=1; exit} END{exit !found}' "$RUN_DIR/results.jtl"; then
    READY=1
    break
  fi
  sleep 0.5
done
if [ "$READY" -ne 1 ]; then
  echo "Main load traffic never started within 150s -- aborting (a setup problem, not a finding)." >&2
  kill "$JMETER_PID" 2>/dev/null || true
  exit 1
fi
echo "  confirmed: main load traffic has started."

banner "Starting the metrics poller (${TOTAL_DURATION}s from now, 0.2s interval)"
POLLER_CSV="$RUN_DIR/poller.csv"
python3 load-tests/kafka-cb-loadtest-poller.py --duration "$TOTAL_DURATION" --interval 0.2 --out "$POLLER_CSV" &
POLLER_PID=$!

echo "Letting steady concurrent load run for ${PRE_KILL_SECONDS}s before touching Kafka..."
sleep "$PRE_KILL_SECONDS"

banner "Stopping all 3 Kafka brokers (kafka-1, kafka-2, kafka-3) under live concurrent load"
# Kill instant via Python's own clock, not bash `date +%3N` -- this Mac's BSD date silently
# misparses that field-width modifier (docs/testing-strategy.md's GNU-vs-BSD lesson).
KILL_ISO=$(python3 -c "from datetime import datetime, timezone; print(datetime.now(timezone.utc).isoformat())")
echo "Kill instant: $KILL_ISO"
docker compose stop kafka-1 kafka-2 kafka-3

echo "Holding the outage for ${OUTAGE_SECONDS}s while the poller and JMeter keep running..."
sleep "$OUTAGE_SECONDS"

banner "Restarting all 3 Kafka brokers"
RESTART_ISO=$(python3 -c "from datetime import datetime, timezone; print(datetime.now(timezone.utc).isoformat())")
echo "Restart instant: $RESTART_ISO"
docker compose start kafka-1 kafka-2 kafka-3

echo "Holding a ${RECOVERY_SECONDS}s recovery window for the breaker to close again..."
sleep "$RECOVERY_SECONDS"

banner "Waiting for JMeter and the poller to finish on their own"
wait "$JMETER_PID"
JMETER_EXIT=$?
wait "$POLLER_PID"
echo "JMeter exit code: $JMETER_EXIT"

{
  echo "kill_iso=$KILL_ISO"
  echo "restart_iso=$RESTART_ISO"
  echo "threads=$THREADS"
  echo "ramp_up_s=$RAMP_UP"
  echo "pre_kill_s=$PRE_KILL_SECONDS"
  echo "outage_s=$OUTAGE_SECONDS"
  echo "recovery_s=$RECOVERY_SECONDS"
} > "$RUN_DIR/run-params.txt"

banner "Analyzing results"
python3 load-tests/kafka-cb-loadtest-analyze.py \
  --jtl "$RUN_DIR/results.jtl" \
  --poller-csv "$POLLER_CSV" \
  --kill-iso "$KILL_ISO" \
  --restart-iso "$RESTART_ISO" \
  --tomcat-max 200 \
  --json "$RUN_DIR/analysis.json"

echo
echo "Full evidence in $RUN_DIR/ (results.jtl, report/, poller.csv, analysis.json, run-params.txt)"
