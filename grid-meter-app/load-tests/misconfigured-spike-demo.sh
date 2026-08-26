#!/usr/bin/env bash
# Demonstrates the "we didn't configure for bursts" failure mode: runs an identical sustained
# burst against a single api replica twice -- once with Tomcat's properly-configured default
# accept-count (100, see application.yml), once with a deliberately under-provisioned accept-count
# (5, via SERVER_TOMCAT_ACCEPT_COUNT) -- and reports the contrast. Captures dashboard/alerting
# screenshots and a resource log for both phases, same evidence pattern as chaos-demo.sh /
# autoscale-demo.sh. Third of the traffic-spike-family test suites, alongside rapid-spike.jmx
# (sudden burst) and gentle-spike.jmx (same burst, gentler onset) -- see load-tests/README.md.
#
# Uses load-tests/misconfigured-burst.jmx, not rapid-spike.jmx directly -- see that file's own
# comment for why. Short version: a single sharp rapid-spike-style burst (with HTTP keep-alive on,
# like every other profile) only exercises accept-count during its brief connection-establishment
# window, too short for any alert's 30s-sustained + 5-minute-rate-window requirements to ever
# trip. Looping separate rapid-spike bursts back to back was tried next and also failed, for a
# different, non-obvious reason confirmed via a real run: JVM/JIT warm-up across repeated bursts
# against the same persistent process measurably raised throughput and cut the error rate each
# time (4.36%/6.82% on the first two loop iterations, decaying under 1% by the eighth) -- a warm
# JVM drains even a 5-slot queue fast enough regardless of the misconfiguration. misconfigured-
# burst.jmx disables keep-alive instead, so every request opens a fresh connection and accept-count
# stays under continuous pressure for the whole run, independent of how warm the JVM's own
# request-processing path gets.
#
# Real single-burst validation (2026-08-26, keep-alive ON, 400-thread/1s-ramp/10s-duration):
# accept-count=100 -> 0.00% errors at p95 4584ms (queue absorbs the burst, just slowly);
# accept-count=5 -> 8.61% errors, 100% genuine 502 Bad Gateway. See load-tests/README.md for the
# full comparison including gentle-spike. This script's own sustained (keep-alive-off) numbers are
# separate and recorded in its own run output, not restated here.
#
# Prerequisites: same as autoscale-demo.sh -- full stack up (observability tier included),
# Playwright's Chromium downloaded once (npx --yes playwright install chromium), and the api image
# rebuilt at least once since SERVER_TOMCAT_ACCEPT_COUNT was added to application.yml
# (docker compose build api) -- the placeholder has to already be baked into the packaged jar.
# jq required (already a load-tests/README.md prerequisite for check-thresholds.sh).
#
# Usage: load-tests/misconfigured-spike-demo.sh
#   Tune via BAD_ACCEPT_COUNT / SPIKE_THREADS / SPIKE_RAMP / BURST_DURATION env vars if the
#   defaults don't fit. Screenshots + logs land in
#   load-tests/screenshots/misconfigured-spike-<run-timestamp>/.
set -uo pipefail
cd "$(dirname "$0")/.."

# Grafana's HTTP API always lives at root-relative /api/*, regardless of GF_SERVER_SERVE_FROM_
# SUB_PATH -- that setting only affects the UI's own page/asset URLs (used for GRAFANA_URL/
# ALERTING_URL below), not the backend API alert_firing() below calls directly.
GRAFANA_HOST="http://localhost:3001"
export GRAFANA_URL="${GRAFANA_HOST}/grafana/d/grid-meter-overview/grid-meter-api-overview?kiosk&refresh=15s"
export ALERTING_URL="${GRAFANA_HOST}/grafana/alerting/list"
RUN_DIR="$(pwd)/load-tests/screenshots/misconfigured-spike-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN_DIR"

BAD_ACCEPT_COUNT="${BAD_ACCEPT_COUNT:-5}"
SPIKE_THREADS="${SPIKE_THREADS:-400}"
SPIKE_RAMP="${SPIKE_RAMP:-1}"
BURST_DURATION="${BURST_DURATION:-90}"

banner() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

alert_firing() {
  curl -s "$GRAFANA_HOST/api/prometheus/grafana/api/v1/rules" 2>/dev/null | \
    jq -e --arg name "$1" '.data.groups[].rules[] | select(.name==$name) | .state=="firing"' >/dev/null 2>&1
}

# api's own /actuator/health passing does NOT prove Traefik has finished registering a
# just-recreated container as a live backend for /api/v1/** -- see
# load-tests/autoscale-demo.sh's header for the real, twice-reproduced incident this guards
# against. Probe the actual path the load test depends on before proceeding, not just liveness.
reset_api() {
  local accept_count="$1"
  banner "Resetting api to a single replica with accept-count=$accept_count."
  SERVER_TOMCAT_ACCEPT_COUNT="$accept_count" docker compose up -d --scale api=1 api
  ./scripts/wait-for-health.sh "http://localhost/actuator/health" 60

  echo "Confirming /api/v1/auth/login is reachable through Traefik..."
  local ready=0
  for i in $(seq 1 10); do
    code=$(curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost/api/v1/auth/login \
      -H 'Content-Type: application/json' \
      -d '{"username":"demo","password":"GridMeter!Demo2026"}')
    if [ "$code" = "200" ]; then
      ready=1
      break
    fi
    echo "  attempt $i: got HTTP $code, retrying..."
    sleep 2
  done
  if [ "$ready" -ne 1 ]; then
    echo "Login through Traefik never returned 200 after 10 attempts -- aborting rather than launching a spike against an unready edge." >&2
    exit 1
  fi
}

# --- Screenshot daemon setup: same persistent-session pattern as chaos-demo.sh/autoscale-demo.sh ---
if [ ! -d load-tests/node_modules/playwright ]; then
  echo "First run: installing playwright locally into load-tests/node_modules (one-time)..."
  (cd load-tests && npm install --no-save --no-audit --no-fund playwright)
fi
SCREENSHOT_FIFO="$(mktemp -u /tmp/misconfigured-spike-screenshot-fifo.XXXXXX)"
SCREENSHOT_LOG="$(mktemp /tmp/misconfigured-spike-screenshot-daemon.XXXXXX)"
if [ -z "$SCREENSHOT_FIFO" ] || [ -z "$SCREENSHOT_LOG" ]; then
  echo "mktemp failed to produce a FIFO/log path -- aborting rather than continuing into a broken state." >&2
  exit 1
fi
mkfifo "$SCREENSHOT_FIFO"
node load-tests/screenshot-daemon.js < "$SCREENSHOT_FIFO" > "$SCREENSHOT_LOG" 2>&1 &
DAEMON_PID=$!
exec 3>"$SCREENSHOT_FIFO"

RESOURCE_LOG="$RUN_DIR/resource-log.txt"
./load-tests/monitor-resources.sh "$RESOURCE_LOG" 5 &
MONITOR_PID=$!

cleanup() {
  exec 3>&- 2>/dev/null || true
  kill "$DAEMON_PID" "$MONITOR_PID" 2>/dev/null || true
  rm -f "$SCREENSHOT_FIFO" "$SCREENSHOT_LOG"
  # Restore api to its properly-configured default -- never leave the deliberately broken
  # accept-count running after the demo ends.
  docker compose up -d --scale api=1 api >/dev/null 2>&1 || true
}
trap cleanup EXIT

shoot() {
  # $1 = output filename (no path), $2 = human-readable label for the log line
  local out="$RUN_DIR/$1"
  echo "Screenshot: $2 (dashboard) -> $out"
  echo "dashboard|$out" >&3
  for _ in $(seq 1 30); do
    grep -qF "DONE:$out" "$SCREENSHOT_LOG" 2>/dev/null && break
    grep -qF "FAILED:$out" "$SCREENSHOT_LOG" 2>/dev/null && { echo "  (failed -- continuing)"; break; }
    sleep 1
  done

  local alertsOut="${out%.png}-alerts.png"
  echo "Screenshot: $2 (alerting) -> $alertsOut"
  echo "alerts|$alertsOut" >&3
  for _ in $(seq 1 30); do
    grep -qF "DONE:$alertsOut" "$SCREENSHOT_LOG" 2>/dev/null && return 0
    grep -qF "FAILED:$alertsOut" "$SCREENSHOT_LOG" 2>/dev/null && { echo "  (failed -- continuing)"; return 0; }
    sleep 1
  done
  echo "  (alerting screenshot timed out waiting for daemon ack -- continuing)"
}

run_phase() {
  local label="$1" accept_count="$2" prefix="$3"
  reset_api "$accept_count"
  sleep 15
  shoot "${prefix}-00-baseline.png" "$label baseline"

  banner "Running misconfigured-burst ($SPIKE_THREADS threads, keep-alive off, ${BURST_DURATION}s duration) -- $label"
  local burst_results="load-tests/results/misconfigured-burst-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$burst_results"
  (
    cd load-tests
    jmeter -n -t misconfigured-burst.jmx -q config/load-test.properties \
      -Jthreads="$SPIKE_THREADS" -JrampUp="$SPIKE_RAMP" -Jduration="$BURST_DURATION" \
      -l "../$burst_results/results.jtl" -e -o "../$burst_results/report" \
      -j "../$burst_results/jmeter.log" \
      > "/tmp/misconfigured-spike-demo-${prefix}.log" 2>&1
  ) &
  local jmeter_pid=$!

  # Poll while the burst is still running so a firing alert gets captured live, not just inferred
  # after the fact.
  local fired=0
  while kill -0 "$jmeter_pid" 2>/dev/null; do
    if alert_firing "High HTTP error rate"; then
      fired=1
      break
    fi
    sleep 3
  done
  if [ "$fired" -eq 1 ]; then
    echo "High HTTP error rate is now firing -- capturing it live."
    shoot "${prefix}-01-firing.png" "$label with the alert firing"
  fi
  wait "$jmeter_pid" 2>/dev/null || true
  if [ "$fired" -ne 1 ]; then
    echo "High HTTP error rate never fired during this phase's run." >&2
  fi
  shoot "${prefix}-02-after.png" "$label after the burst"

  echo "$burst_results" > "$RUN_DIR/${prefix}-results-dir.txt"
}

# Second attempt at sustaining the error rate long enough to trip an alert: sustaining via
# keep-alive-off (misconfigured-burst.jmx, above) empirically did NOT reproduce the effect either
# (0.27% errors) -- a real run showed the vulnerability is specific to a genuinely sharp,
# near-simultaneous burst of *new* connections, not to sustained connection churn spread over
# time, even at high volume. So: loop the original, keep-alive-ON, sharp rapid-spike burst (the
# mechanism validated to reliably produce ~7-8% errors under accept-count=5) but recreate api (a
# cold JVM) before every single iteration -- the first loop attempt (above) showed JVM/JIT warm-up
# across repeated bursts against the SAME persistent process measurably cuts the error rate each
# time (4.36%/6.82% decaying under 1% by the eighth loop), so a cold reset each time is what should
# keep every iteration's error rate consistent instead of decaying away.
run_cold_reset_loop_phase() {
  local label="$1" accept_count="$2" prefix="$3" max_iterations="${4:-10}"
  : > "$RUN_DIR/${prefix}-results-dirs.txt"
  local fired=0
  for i in $(seq 1 "$max_iterations"); do
    reset_api "$accept_count"
    if [ "$i" -eq 1 ]; then
      sleep 10
      shoot "${prefix}-00-baseline.png" "$label baseline"
    fi
    (
      cd load-tests
      ./run.sh rapid-spike -Jthreads="$SPIKE_THREADS" -JrampUp="$SPIKE_RAMP" -Jduration=10 \
        > "/tmp/misconfigured-spike-demo-${prefix}-${i}.log" 2>&1
    )
    ls -td load-tests/results/rapid-spike-* | head -1 >> "$RUN_DIR/${prefix}-results-dirs.txt"
    if alert_firing "High HTTP error rate"; then
      echo "High HTTP error rate is now firing (after $i cold-reset burst(s))."
      fired=1
      shoot "${prefix}-01-firing.png" "$label with the alert firing"
      break
    fi
    echo "  cold-reset burst $i done, not firing yet -- looping again..."
  done
  if [ "$fired" -ne 1 ]; then
    echo "High HTTP error rate never fired after $max_iterations cold-reset bursts." >&2
  fi
  shoot "${prefix}-02-after.png" "$label after $([ "$fired" -eq 1 ] && echo "the alert fired" || echo "$max_iterations cold-reset bursts")"
}

run_phase "properly-configured (accept-count=100, the application.yml default)" 100 good
run_cold_reset_loop_phase "misconfigured (accept-count=$BAD_ACCEPT_COUNT)" "$BAD_ACCEPT_COUNT" bad

banner "Comparison"
dir=$(cat "$RUN_DIR/good-results-dir.txt")
stats="$dir/report/statistics.json"
if [ -f "$stats" ]; then
  samples=$(jq -r '.Total.sampleCount' "$stats")
  errpct=$(jq -r '.Total.errorPct' "$stats")
  p95=$(jq -r '.Total.pct2ResTime' "$stats")
  echo "good ($dir): samples=$samples  error-rate=${errpct}%  p95=${p95}ms"
else
  echo "good ($dir): no statistics.json found"
fi

total_samples=0
total_errors=0
burst_count=0
while read -r bdir; do
  [ -n "$bdir" ] || continue
  bstats="$bdir/report/statistics.json"
  [ -f "$bstats" ] || continue
  burst_count=$((burst_count + 1))
  total_samples=$((total_samples + $(jq -r '.Total.sampleCount' "$bstats")))
  total_errors=$((total_errors + $(jq -r '.Total.errorCount' "$bstats")))
done < "$RUN_DIR/bad-results-dirs.txt"
if [ "$total_samples" -gt 0 ]; then
  agg_err_pct=$(python3 -c "print(round(100*$total_errors/$total_samples, 4))")
  echo "bad (${burst_count} cold-reset burst(s), $RUN_DIR/bad-results-dirs.txt): samples=$total_samples  errors=$total_errors  error-rate=${agg_err_pct}%"
else
  echo "bad: no statistics.json found across any burst"
fi

echo
echo "Screenshots + resource log: $RUN_DIR/"
ls -la "$RUN_DIR"
