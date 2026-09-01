#!/usr/bin/env bash
# docs/postgres-ha-scope.md Stage 7 Step 4: re-runs Stage 4's primary-kill scenario, but through
# the app's real endpoints (Traefik -> API -> HikariCP -> Patroni cluster) instead of direct
# psql. Stage 4 already measured the infrastructure-level RTO (new leader elected, no unsafe
# promotion); this script measures what an actual HTTP client experiences during that same
# window, and specifically whether PrimaryFailoverSQLExceptionOverride (added during the app
# cutover) lets HikariCP recover on its own -- a stale pooled connection to a freshly-demoted
# node passes Connection.isValid() fine (only writes are rejected), so without that override the
# pool would keep handing it out until max-lifetime eventually recycled it, long after Patroni
# itself has already elected a new primary.
#
# Dynamically detects the current leader and generates real, continuous POST /api/v1/readings
# traffic through the app throughout the whole outage -- not just before/after snapshots -- so
# the actual moment writes start succeeding again is captured, not inferred. Polls for actual
# readiness conditions (per-node pg_is_in_recovery(), same as Stage 4) rather than a fixed sleep,
# per this project's standing test-infrastructure discipline (docs/testing-strategy.md).
#
# Usage: ./postgres-app-primary-failure-test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

LOG_DIR=$(mktemp -d)
REQUEST_LOG="$LOG_DIR/requests.log"
STOP_FLAG="$LOG_DIR/stop"

echo "=== Logging in ==="
TOKEN=$(curl -s -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"GridMeter!Demo2026"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin).get('accessToken',''))")
if [[ -z "$TOKEN" ]]; then
  echo "Could not log in, aborting" >&2
  exit 1
fi

echo "=== Creating a test meter for this run ==="
METER_ID=$(curl -s -X POST http://localhost/api/v1/meters \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"serialNumber":"STAGE7-FAILOVER-'"$(date +%s)"'","location":"Stage 7 test","status":"ACTIVE","installedAt":"2026-01-01T00:00:00Z"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin).get('id',''))")
if [[ -z "$METER_ID" ]]; then
  echo "Could not create test meter, aborting" >&2
  exit 1
fi
echo "Meter: $METER_ID"

echo
echo "=== Identifying current leader ==="
LIST=$(docker compose exec -T patroni-2 patronictl -c /etc/patroni.yml list 2>&1)
echo "$LIST"
LEADER=$(echo "$LIST" | awk -F'|' '/Leader/ {gsub(/ /,"",$2); print $2}')
if [[ -z "$LEADER" ]]; then
  echo "Could not identify current leader, aborting" >&2
  exit 1
fi
echo "Current leader: $LEADER"

case "$LEADER" in
  patroni-1) WITNESS=patroni-2 ;;
  patroni-2) WITNESS=patroni-1 ;;
  patroni-3) WITNESS=patroni-1 ;;
esac

# Sends one POST /api/v1/readings roughly every 300ms until $STOP_FLAG exists. Logs
# "<epoch_ms> <http_code>" per attempt (000 for a curl-level failure/timeout, not an HTTP code).
send_requests_loop() {
  local i=0
  while [[ ! -f "$STOP_FLAG" ]]; do
    i=$((i + 1))
    local sec; sec=$(printf "%02d" $((i % 60)))
    local ts; ts=$(($(date +%s%N) / 1000000))
    local code
    # This loop runs under the script's own `set -e` (inherited into the `&`-backgrounded
    # subshell) -- an unguarded command substitution here would kill the whole loop the instant
    # curl returns non-zero, which is exactly what a real connection-refused/timeout during the
    # failover window does. A first version of this script hit exactly that: the loop silently
    # died ~2s into a run instead of running the full ~24s, while the script's own summary still
    # printed a clean result -- the same "set -e + unguarded substitution" bug class already
    # documented elsewhere in this project (docs/cross-project-lessons.md). The `|| echo "000"`
    # guard is required, not optional; curl can ALSO print a partial "%{http_code}" (usually
    # "000") to stdout before exiting non-zero, so the guard's own "000" can land right after
    # curl's partial one -- `${code: -3}` below takes the last 3 characters unconditionally to
    # collapse that "000000" case, correct whether curl printed nothing, a partial "000", or a
    # real 3-digit status.
    code=$(curl -s -o /dev/null -w "%{http_code}" -m 5 -X POST http://localhost/api/v1/readings \
      -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
      -d "{\"meterId\":\"$METER_ID\",\"readingTimestamp\":\"2026-09-01T00:01:${sec}Z\",\"value\":${i}.0}" \
      2>/dev/null || echo "000")
    code="${code: -3}"
    [[ -z "$code" ]] && code="000"
    echo "${ts} ${code}" >> "$REQUEST_LOG"
    sleep 0.3
  done
}

echo
echo "=== Starting continuous app-level write traffic (background, ~3.3 req/s) ==="
send_requests_loop &
LOOP_PID=$!
sleep 2

echo
echo "=== Killing $LEADER ==="
T0_MS=$(($(date +%s%N) / 1000000))
docker compose stop "$LEADER"

echo
echo "=== Polling for a new leader at the infrastructure level (up to 60s) ==="
NEW_LEADER=""
START=$SECONDS
while (( SECONDS - START < 60 )); do
  LIST2=$(docker compose exec -T "$WITNESS" patronictl -c /etc/patroni.yml list 2>&1)
  CANDIDATE=$(echo "$LIST2" | awk -F'|' -v old="$LEADER" '/Leader/ {gsub(/ /,"",$2); if ($2 != old) print $2}')
  if [[ -n "$CANDIDATE" ]]; then
    T1_MS=$(($(date +%s%N) / 1000000))
    NEW_LEADER="$CANDIDATE"
    echo "  New leader: $NEW_LEADER -- infra-level RTO: $((T1_MS - T0_MS))ms"
    break
  fi
  sleep 0.5
done
if [[ -z "$NEW_LEADER" ]]; then
  echo "!!! No new leader elected within 60s -- real failure, not a timing artifact" >&2
  kill "$LOOP_PID" 2>/dev/null || true
  touch "$STOP_FLAG"
  exit 1
fi

echo
echo "=== Continuing app traffic for 20s past infra-level election, to observe app-level recovery ==="
sleep 20

echo
echo "=== Stopping traffic and restoring $LEADER ==="
touch "$STOP_FLAG"
wait "$LOOP_PID" 2>/dev/null || true
docker compose start "$LEADER"

TOTAL=$(wc -l < "$REQUEST_LOG" | tr -d ' ')
SUCCESS=$(awk '$2 == 201' "$REQUEST_LOG" | wc -l | tr -d ' ')
FAIL=$((TOTAL - SUCCESS))

# First successful (201) request logged at or after T0 (outage start) marks the app-level
# recovery point -- i.e., how long a real HTTP client kept seeing failures for, not just how
# long Patroni took to elect someone.
APP_RTO_MS=""
while read -r ts code; do
  if [[ "$ts" -ge "$T0_MS" && "$code" == "201" ]]; then
    APP_RTO_MS=$((ts - T0_MS))
    break
  fi
done < "$REQUEST_LOG"

# Last failing request at or after T0, to see whether failures were contiguous (a single clean
# outage window) or whether some requests inside that window intermittently succeeded already
# (e.g. against a replica or a not-yet-demoted old primary via a stale connection).
LAST_FAIL_MS=""
while read -r ts code; do
  if [[ "$ts" -ge "$T0_MS" && "$code" != "201" ]]; then
    LAST_FAIL_MS="$ts"
  fi
done < "$REQUEST_LOG"

echo
echo "=== RESULT SUMMARY ==="
echo "Old leader: $LEADER -> New leader: $NEW_LEADER"
echo "Total requests during run: $TOTAL (success: $SUCCESS, failed/timed-out: $FAIL)"
echo "App-level RTO (first successful write after outage began): ${APP_RTO_MS:-NEVER within the run window -- real problem}ms"
if [[ -n "$LAST_FAIL_MS" ]]; then
  echo "Last failing request at: $((LAST_FAIL_MS - T0_MS))ms after outage began"
fi
echo "HTTP status code breakdown:"
awk '{print $2}' "$REQUEST_LOG" | sort | uniq -c
echo
echo "Recovered without any app/pool restart: $([[ $SUCCESS -gt 0 && -n "$APP_RTO_MS" ]] && echo yes || echo no)"
echo
echo "Full request log: $REQUEST_LOG"

echo
echo "=== Cleanup: deleting the test meter's readings via direct SQL (readings are immutable, no DELETE endpoint) ==="
docker compose exec -T "$NEW_LEADER" psql -U gridmeter -d gridmeter -c \
  "DELETE FROM readings WHERE meter_id = '${METER_ID}';" 2>&1
docker compose exec -T "$NEW_LEADER" psql -U gridmeter -d gridmeter -c \
  "DELETE FROM meters WHERE id = '${METER_ID}';" 2>&1
