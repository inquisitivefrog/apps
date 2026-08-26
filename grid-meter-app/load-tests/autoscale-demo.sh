#!/usr/bin/env bash
# Real Docker Compose autoscaling demo: starts api at a single replica, launches a JMeter spike
# against it, and lets load-tests/autoscale-watcher.sh detect real CPU/memory pressure and scale
# api out to 2 replicas on its own -- then scale back in once load subsides. Captures a dashboard
# screenshot at each transition and logs resource usage throughout, same evidence pattern as
# chaos-demo.sh. See docs/autoscaling-scope.md for why autoscaling is scoped to api only, and
# load-tests/autoscale-watcher.sh's header for why scale-in deliberately ignores memory.
#
# Prerequisites: same as chaos-demo.sh -- full stack up (observability tier included), Playwright's
# Chromium downloaded once (npx --yes playwright install chromium). The api service's `cpus: "1.0"`
# limit in docker-compose.yml is what makes the watcher's CPU% threshold meaningful.
#
# Usage: load-tests/autoscale-demo.sh
#   Tune via SPIKE_DURATION / CPU_THRESHOLD / MEM_THRESHOLD / POLL_SECONDS / SCALE_UP_STREAK /
#   SCALE_DOWN_STREAK env vars if the defaults don't fit -- see autoscale-watcher.sh for what each
#   controls. Screenshots + logs land in load-tests/screenshots/autoscale-<run-timestamp>/.
set -uo pipefail
cd "$(dirname "$0")/.."

export GRAFANA_URL="http://localhost:3001/grafana/d/grid-meter-overview/grid-meter-api-overview?kiosk&refresh=15s"
export ALERTING_URL="http://localhost:3001/grafana/alerting/list"
RUN_DIR="$(pwd)/load-tests/screenshots/autoscale-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN_DIR"
SPIKE_DURATION="${SPIKE_DURATION:-90}"

banner() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

banner "Resetting api to a single replica before starting."
docker compose up -d --scale api=1 api
./scripts/wait-for-health.sh "http://localhost/actuator/health" 60

# /actuator/health only proves the api process itself is alive -- it does NOT prove Traefik has
# finished registering the (possibly just-recreated) container as a live backend for /api/v1/**.
# Reproduced twice in testing: the very first POST through Traefik right after this reset got a
# transient 502 even though health had already passed -- confirmed via api's own access log
# showing the request never arrived there at all, so it's a proxy-side gap, not an app crash.
# Probe the actual path the load test depends on before proceeding, not just liveness.
echo "Confirming /api/v1/auth/login is reachable through Traefik..."
login_ready=0
for i in $(seq 1 10); do
  code=$(curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost/api/v1/auth/login \
    -H 'Content-Type: application/json' \
    -d '{"username":"demo","password":"GridMeter!Demo2026"}')
  if [ "$code" = "200" ]; then
    login_ready=1
    break
  fi
  echo "  attempt $i: got HTTP $code, retrying..."
  sleep 2
done
if [ "$login_ready" -ne 1 ]; then
  echo "Login through Traefik never returned 200 after 10 attempts -- aborting rather than launching a spike against an unready edge." >&2
  exit 1
fi

# --- Screenshot daemon setup: same persistent-session pattern as chaos-demo.sh ---
if [ ! -d load-tests/node_modules/playwright ]; then
  echo "First run: installing playwright locally into load-tests/node_modules (one-time)..."
  (cd load-tests && npm install --no-save --no-audit --no-fund playwright)
fi
SCREENSHOT_FIFO="$(mktemp -u /tmp/autoscale-demo-screenshot-fifo.XXXXXX)"
SCREENSHOT_LOG="$(mktemp /tmp/autoscale-demo-screenshot-daemon.XXXXXX)"
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

WATCHER_LOG="$RUN_DIR/autoscale-watcher-log.txt"
./load-tests/autoscale-watcher.sh "$WATCHER_LOG" &
WATCHER_PID=$!

cleanup() {
  exec 3>&- 2>/dev/null || true
  kill "$DAEMON_PID" "$MONITOR_PID" "$WATCHER_PID" 2>/dev/null || true
  rm -f "$SCREENSHOT_FIFO" "$SCREENSHOT_LOG"
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

banner "Baseline: 15s settle, then a baseline screenshot (1 replica)."
sleep 15
shoot "00-baseline.png" "baseline, 1 replica"

banner "Launching a ${SPIKE_DURATION}s spike against the single api replica (600 threads vs its 200-thread ceiling)."
(
  cd load-tests
  ./run.sh spike -Jduration="$SPIKE_DURATION" > /tmp/autoscale-demo-load.log 2>&1
) &
LOAD_PID=$!
shoot "01-spike-started.png" "spike started, still 1 replica"

banner "Waiting for the watcher to detect pressure and scale out..."
scaled_out=0
for i in $(seq 1 60); do
  sleep 2
  if grep -q "SCALING OUT" "$WATCHER_LOG" 2>/dev/null; then
    echo "Scale-out detected after ~$((i * 2))s."
    scaled_out=1
    break
  fi
done
if [ "$scaled_out" -eq 1 ]; then
  shoot "02-scaled-out.png" "scaled out to 2 replicas"
else
  echo "Scale-out did not occur within the wait window -- capturing current state anyway."
  shoot "02-no-scale-out-detected.png" "spike ongoing, no scale-out yet"
fi

banner "Waiting for the spike to finish..."
wait "$LOAD_PID"
shoot "03-spike-finished.png" "spike finished"

banner "Waiting for the watcher to detect calm and scale back in (slower by design -- anti-flapping)..."
scaled_in=0
for i in $(seq 1 90); do
  sleep 2
  if grep -q "SCALING IN" "$WATCHER_LOG" 2>/dev/null; then
    echo "Scale-in detected after ~$((i * 2))s."
    scaled_in=1
    break
  fi
done
if [ "$scaled_in" -eq 1 ]; then
  shoot "04-scaled-in.png" "scaled back in to 1 replica"
else
  echo "Scale-in did not occur within the wait window -- capturing current state anyway."
  shoot "04-no-scale-in-detected.png" "load subsided, no scale-in yet"
fi

banner "Demo complete."
echo "Load run log: /tmp/autoscale-demo-load.log"
echo "Watcher log: $WATCHER_LOG"
echo "Resource log: $RESOURCE_LOG"
echo "Screenshots: $RUN_DIR/"
ls -la "$RUN_DIR"
