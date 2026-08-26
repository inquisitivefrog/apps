#!/usr/bin/env bash
# Observability demo: runs a sustained background load, then takes each link in the request chain
# offline in turn (docker compose stop/start) -- Traefik, api, Kafka, Postgres, Redis, matching
# ../docs/architecture.md's system diagram -- taking a real Grafana dashboard screenshot before and
# during each outage and after recovery, via a headless Playwright browser. Fully automated,
# including the screenshots -- no manual browser step required.
#
# Prerequisites:
#   - Full stack up, including the observability tier:
#       docker compose up -d --scale api=2 traefik frontend api postgres kafka redis \
#         prometheus loki tempo grafana alloy
#   - Playwright's Chromium downloaded once: npx --yes playwright install chromium
#     (the `playwright` npm module itself is bootstrapped automatically into
#     load-tests/node_modules on first run -- see below)
#   - The grid-meter-overview dashboard provisioned (observability/dashboards/, wired into
#     docker-compose.yml's grafana service volumes -- already the case if grafana started clean).
#
# Screenshots are taken against Grafana's direct host port (localhost:3001), not through Traefik,
# specifically so they keep working when Traefik itself is the link being taken offline -- see the
# comment on grafana's `ports:` entry in docker-compose.yml.
#
# Screenshots reuse ONE persistent browser session (screenshot-daemon.js), not a fresh
# `npx playwright screenshot` per shot. A fresh anonymous-auth Grafana session per shot was
# measured costing ~80-170MB server-side and never releasing it -- 2-3 fresh-session screenshots
# reliably OOM-killed Grafana regardless of its container memory limit. See
# status/claude_code_2026-08-24.md for the full investigation.
#
# Usage: load-tests/chaos-demo.sh
#   Runs steady-state.jmx in the background for the whole sequence, then walks through each link.
#   Tune timing via the OUTAGE_SECONDS / RECOVERY_SECONDS env vars if the defaults don't fit.
#   Screenshots land in load-tests/screenshots/<run-timestamp>/, numbered in sequence order.
set -uo pipefail
cd "$(dirname "$0")/.."

BASELINE_SECONDS="${BASELINE_SECONDS:-60}"
OUTAGE_SECONDS="${OUTAGE_SECONDS:-45}"
RECOVERY_SECONDS="${RECOVERY_SECONDS:-20}"
LINKS=(traefik api kafka postgres redis)
export GRAFANA_URL="http://localhost:3001/grafana/d/grid-meter-overview/grid-meter-api-overview?kiosk&refresh=15s"
RUN_DIR="$(pwd)/load-tests/screenshots/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN_DIR"

# Rough budget: baseline + 5 * (outage + recovery) + buffer.
LOAD_DURATION=$(( BASELINE_SECONDS + ${#LINKS[@]} * (OUTAGE_SECONDS + RECOVERY_SECONDS) + 60 ))

banner() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

# --- Screenshot daemon setup: one persistent browser session for the whole run ---
# `require('playwright')` resolution is inconsistent under `npx -p playwright node <script>`
# depending on the script's own location (worked for a script directly in /tmp, not for one under
# load-tests/) -- self-bootstrapping a plain local node_modules here is more reliable than fighting
# that. No package.json needed; `npm install` handles a bare node_modules fine on its own.
if [ ! -d load-tests/node_modules/playwright ]; then
  echo "First run: installing playwright locally into load-tests/node_modules (one-time)..."
  (cd load-tests && npm install --no-save --no-audit --no-fund playwright)
fi
SCREENSHOT_FIFO="$(mktemp -u /tmp/chaos-demo-screenshot-fifo.XXXXXX)"
SCREENSHOT_LOG="$(mktemp /tmp/chaos-demo-screenshot-daemon.XXXXXX)"
if [ -z "$SCREENSHOT_FIFO" ] || [ -z "$SCREENSHOT_LOG" ]; then
  echo "mktemp failed to produce a FIFO/log path -- aborting rather than continuing into a broken state." >&2
  exit 1
fi
mkfifo "$SCREENSHOT_FIFO"
node load-tests/screenshot-daemon.js < "$SCREENSHOT_FIFO" > "$SCREENSHOT_LOG" 2>&1 &
DAEMON_PID=$!
exec 3>"$SCREENSHOT_FIFO"  # keep a writer open so the fifo doesn't see EOF between shots

cleanup() {
  exec 3>&- 2>/dev/null || true
  kill "$DAEMON_PID" 2>/dev/null || true
  rm -f "$SCREENSHOT_FIFO" "$SCREENSHOT_LOG"
}
trap cleanup EXIT

shoot() {
  # $1 = output filename (no path), $2 = human-readable label for the log line
  local out="$RUN_DIR/$1"
  echo "Screenshot: $2 -> $out"
  echo "$out" >&3
  for _ in $(seq 1 30); do
    grep -qF "DONE:$out" "$SCREENSHOT_LOG" 2>/dev/null && return 0
    grep -qF "FAILED:$out" "$SCREENSHOT_LOG" 2>/dev/null && {
      echo "  (screenshot failed -- continuing; check $SCREENSHOT_LOG)"
      return 0
    }
    sleep 1
  done
  echo "  (screenshot timed out waiting for daemon ack -- continuing)"
}

banner "Starting a $LOAD_DURATION-second steady-state load in the background."
echo "This intentionally ends with a FAILED check-thresholds.sh gate -- that's expected, not a bug,"
echo "since we're deliberately injecting errors partway through. Log: /tmp/chaos-demo-load.log"
(
  cd load-tests
  ./run.sh steady-state -Jduration="$LOAD_DURATION" > /tmp/chaos-demo-load.log 2>&1
) &
LOAD_PID=$!

banner "Baseline: ${BASELINE_SECONDS}s warm-up, then a baseline screenshot before any outage starts."
sleep "$BASELINE_SECONDS"
shoot "00-baseline.png" "baseline, no outage yet"

step=1
for service in "${LINKS[@]}"; do
  n=$(printf "%02d" "$step")
  banner "TAKING '$service' OFFLINE (~${OUTAGE_SECONDS}s window)"
  case "$service" in
    api) echo "Watch: tomcat.threads.busy/connections.current will vanish; Traefik should surface" \
              "connection errors for /api/* since both replicas are stopped." ;;
    traefik) echo "Watch: the whole app becomes unreachable via Traefik -- this is the degenerate" \
                  "case, total outage, not graceful degradation. JMeter's error rate should spike." \
                  "Grafana itself stays reachable (direct port, bypasses Traefik)." ;;
    kafka) echo "Watch: does POST /readings still 201 or start failing? Genuinely worth observing," \
                "not assumed -- check consumer lag/error panels too." ;;
    postgres) echo "Watch: reads (GET /meters, /readings) should start failing; the async Kafka" \
                   "consumer's writes should start erroring too -- check Loki for the actual" \
                   "exception logged." ;;
    redis) echo "Watch: does the app degrade gracefully (cache-miss fallback to Postgres, per" \
                "architecture.md) or hard-fail? This is the one link where graceful degradation is" \
                "the documented expectation -- worth confirming for real." ;;
  esac
  docker compose stop "$service"
  sleep "$OUTAGE_SECONDS"
  shoot "${n}-${service}-outage.png" "$service offline"

  banner "RESTORING '$service'"
  docker compose start "$service"
  sleep "$RECOVERY_SECONDS"
  shoot "${n}-${service}-recovered.png" "$service recovered"

  step=$((step + 1))
done

banner "Sequence complete. Waiting on the background load run to finish (PID $LOAD_PID)..."
wait "$LOAD_PID"
echo
echo "Load run log: /tmp/chaos-demo-load.log (a failed threshold gate at the end is expected)"
echo "Screenshots: $RUN_DIR/"
ls -la "$RUN_DIR"
echo "Check Loki/Grafana Explore for the actual error logs during each outage window."
