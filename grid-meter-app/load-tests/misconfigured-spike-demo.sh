#!/usr/bin/env bash
# Demonstrates the "we didn't configure for bursts" failure mode: runs the identical rapid-spike
# burst against a single api replica twice -- once with Tomcat's properly-configured default
# accept-count (100, see application.yml), once with a deliberately under-provisioned accept-count
# (5, via SERVER_TOMCAT_ACCEPT_COUNT) -- and reports the contrast. Captures dashboard/alerting
# screenshots and a resource log for both phases, same evidence pattern as chaos-demo.sh /
# autoscale-demo.sh. Third of the traffic-spike-family test suites, alongside rapid-spike.jmx
# (sudden burst) and gentle-spike.jmx (same burst, gentler onset) -- see load-tests/README.md.
#
# Deliberately overrides rapid-spike.jmx's own 10s-ramp default down to a much sharper ~1s ramp
# (SPIKE_RAMP below) -- accept-count only bounds the queue of pending *new* connections. HTTP
# keep-alive (already on for every profile) means once a connection is established, all of that
# thread's remaining requests reuse it and never touch the accept-count queue again. A first
# attempt at this demo reused rapid-spike's default 10s ramp at full scale and found the contrast
# had nearly vanished (0.00% vs 0.019% errors, pure noise) -- 10s is gentle enough that even a
# tiny queue drains as fast as it fills. Confirmed via a real run, not assumed, before landing on
# these parameters: a genuinely sharp ~1s onset is what actually exercises accept-count.
#
# Real validation run (2026-08-26, single api replica, identical 400-thread/1s-ramp/10s-duration
# burst both times): accept-count=100 (default) produced 0.00% errors at p95 4584ms -- the queue
# absorbed the burst, just slowly. accept-count=5 produced 8.61% errors (all 502 Bad Gateway, i.e.
# real connection refusals once the undersized queue overflowed) at a similar p95 -- same load,
# same everything else, only the queue size changed.
#
# Prerequisites: same as autoscale-demo.sh -- full stack up (observability tier included),
# Playwright's Chromium downloaded once (npx --yes playwright install chromium), and the api image
# rebuilt at least once since SERVER_TOMCAT_ACCEPT_COUNT was added to application.yml
# (docker compose build api) -- the placeholder has to already be baked into the packaged jar.
#
# Usage: load-tests/misconfigured-spike-demo.sh
#   Tune via BAD_ACCEPT_COUNT / SPIKE_THREADS / SPIKE_RAMP / SPIKE_DURATION env vars if the
#   defaults don't fit. Screenshots + logs land in
#   load-tests/screenshots/misconfigured-spike-<run-timestamp>/.
set -uo pipefail
cd "$(dirname "$0")/.."

export GRAFANA_URL="http://localhost:3001/grafana/d/grid-meter-overview/grid-meter-api-overview?kiosk&refresh=15s"
export ALERTING_URL="http://localhost:3001/grafana/alerting/list"
RUN_DIR="$(pwd)/load-tests/screenshots/misconfigured-spike-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN_DIR"

BAD_ACCEPT_COUNT="${BAD_ACCEPT_COUNT:-5}"
SPIKE_THREADS="${SPIKE_THREADS:-400}"
SPIKE_RAMP="${SPIKE_RAMP:-1}"
SPIKE_DURATION="${SPIKE_DURATION:-10}"

banner() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
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
  local out="$RUN_DIR/$1"
  echo "Screenshot: $2 -> $out"
  echo "dashboard|$out" >&3
  for _ in $(seq 1 30); do
    grep -qF "DONE:$out" "$SCREENSHOT_LOG" 2>/dev/null && return 0
    grep -qF "FAILED:$out" "$SCREENSHOT_LOG" 2>/dev/null && { echo "  (failed -- continuing)"; return 0; }
    sleep 1
  done
  echo "  (screenshot timed out waiting for daemon ack -- continuing)"
}

run_phase() {
  local label="$1" accept_count="$2" prefix="$3"
  reset_api "$accept_count"
  sleep 15
  shoot "${prefix}-00-baseline.png" "$label baseline"

  banner "Running rapid-spike ($SPIKE_THREADS threads, ${SPIKE_RAMP}s ramp, ${SPIKE_DURATION}s duration) -- $label"
  (
    cd load-tests
    ./run.sh rapid-spike -Jthreads="$SPIKE_THREADS" -JrampUp="$SPIKE_RAMP" -Jduration="$SPIKE_DURATION" \
      > "/tmp/misconfigured-spike-demo-${prefix}.log" 2>&1
  )
  shoot "${prefix}-01-after.png" "$label after the spike"

  ls -td load-tests/results/rapid-spike-* | head -1 > "$RUN_DIR/${prefix}-results-dir.txt"
}

run_phase "properly-configured (accept-count=100, the application.yml default)" 100 good
run_phase "misconfigured (accept-count=$BAD_ACCEPT_COUNT)" "$BAD_ACCEPT_COUNT" bad

banner "Comparison"
for prefix in good bad; do
  dir=$(cat "$RUN_DIR/${prefix}-results-dir.txt")
  stats="$dir/report/statistics.json"
  if [ -f "$stats" ]; then
    samples=$(jq -r '.Total.sampleCount' "$stats")
    errpct=$(jq -r '.Total.errorPct' "$stats")
    p95=$(jq -r '.Total.pct2ResTime' "$stats")
    echo "$prefix ($dir): samples=$samples  error-rate=${errpct}%  p95=${p95}ms"
  else
    echo "$prefix ($dir): no statistics.json found"
  fi
done

echo
echo "Screenshots + resource log: $RUN_DIR/"
ls -la "$RUN_DIR"
