#!/usr/bin/env bash
# docs/redis-ha-scope.md Stage 6 Step 4: re-runs the Stage 4 primary-failure scenario, but through
# the app's real endpoints (Traefik -> API -> Lettuce/Sentinel -> Redis) instead of direct
# redis-cli. Stage 4 already measured the infrastructure-level RTO; this checks what the app
# actually experiences.
#
# Redis sits differently in this app's write path than Postgres does: POST /api/v1/readings
# persists to Postgres and publishes to Kafka synchronously, but the Redis cache write
# (ReadingEventConsumer.onReadingEvent -> redisTemplate.opsForValue().set(...)) happens later, in
# an async Kafka consumer, fully decoupled from the HTTP request/response. This means a Redis
# outage is NOT expected to make POST /readings fail at all -- the real question this script exists
# to answer is whether the async cache write survives the failover (retries/eventually succeeds
# once Sentinel promotes a new master) or is silently lost, and whether a Redis exception thrown
# inside the @KafkaListener method disrupts Kafka consumption for anything after it.
#
# Deliberately `set -uo pipefail`, NOT `-e` -- matching load-tests/redis-primary-failover-rto.sh's
# own considered choice, not an oversight. A first version of this script used `-e` (carried over
# from postgres-app-primary-failure-test.sh's pattern) and died silently, with zero output, at the
# very first readiness-poll loop: `grep -c "^ip$"` exits 1 whenever it finds zero matches, even
# though it still correctly prints "0" -- under `pipefail`, that non-zero pipeline exit fed
# straight into `-e` and killed the script before the loop's own `if` check ever ran. All explicit
# abort conditions below use their own `if ...; then exit 1; fi` checks rather than relying on
# `-e`, so dropping it costs nothing here and avoids this exact class of silent-death bug recurring
# on every `grep -c`/similarly-zero-exit-on-no-match command in this script. The request loop's own
# `|| echo "000"` guard is kept regardless, since it's also needed for correctness (a real
# connection failure must still be logged as a "000" row, not silently dropped from the log).
#
# Usage: ./redis-app-primary-failure-test.sh
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1

DATA_SVCS="redis redis-replica-1 redis-replica-2"

find_master_service() {
  for svc in $DATA_SVCS; do
    if docker compose ps --status running --format '{{.Service}}' | grep -qx "$svc"; then
      ROLE=$(docker compose exec -T "$svc" redis-cli ROLE 2>/dev/null | head -1)
      if [ "$ROLE" = "master" ]; then
        echo "$svc"
        return 0
      fi
    fi
  done
  return 1
}

echo "=== Resetting to canonical topology (redis=primary) before this run ==="
docker compose up -d --force-recreate redis redis-replica-1 redis-replica-2 sentinel-1 sentinel-2 sentinel-3

echo
echo "=== Waiting for Sentinel to discover both replicas ==="
DISCOVERED=0
for i in $(seq 1 30); do
  KNOWN_REPLICAS=$(docker compose exec -T sentinel-1 redis-cli -p 26379 sentinel replicas mymaster 2>/dev/null | grep -c "^ip$")
  if [ "$KNOWN_REPLICAS" -ge 2 ]; then
    DISCOVERED=1
    echo "Both replicas discovered at t+${i}s"
    break
  fi
  sleep 1
done
if [ "$DISCOVERED" -eq 0 ]; then
  echo "Sentinel still doesn't know about both replicas after 30s -- aborting (setup problem)." >&2
  exit 1
fi

echo
echo "=== Waiting for the primary to consider both replicas 'good' for min-replicas-to-write ==="
GOOD_SLAVES_READY=0
for i in $(seq 1 15); do
  GOOD_SLAVES=$(docker compose exec -T redis redis-cli INFO replication 2>/dev/null | grep "min_slaves_good_slaves" | tr -d '\r' | cut -d: -f2)
  if [ "${GOOD_SLAVES:-0}" -ge 1 ]; then
    GOOD_SLAVES_READY=1
    echo "Primary considers replicas good at t+${i}s"
    break
  fi
  sleep 1
done
if [ "$GOOD_SLAVES_READY" -eq 0 ]; then
  echo "Primary still doesn't consider any replica 'good' after 15s -- aborting (setup problem)." >&2
  exit 1
fi

CURRENT_MASTER=$(find_master_service)
if [ "$CURRENT_MASTER" != "redis" ]; then
  echo "Reset did not converge on 'redis' as master -- aborting (setup problem)." >&2
  exit 1
fi
echo "Current master: $CURRENT_MASTER"

# Restart api so its Lettuce/Sentinel client starts fresh against the just-reset topology, rather
# than reusing a connection pool built against the previous run's (possibly different) master.
echo
echo "=== Restarting api against the freshly reset topology ==="
docker compose restart api
until curl -sf http://localhost/actuator/health >/dev/null 2>&1; do sleep 1; done
echo "api is healthy"

LOG_DIR=$(mktemp -d)
REQUEST_LOG="$LOG_DIR/requests.log"
STOP_FLAG="$LOG_DIR/stop"

echo
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
  -d '{"serialNumber":"REDIS-STAGE6-'"$(date +%s)"'","location":"Redis Stage 6 test","status":"ACTIVE","installedAt":"2026-01-01T00:00:00Z"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin).get('id',''))")
if [[ -z "$METER_ID" ]]; then
  echo "Could not create test meter, aborting" >&2
  exit 1
fi
echo "Meter: $METER_ID"

send_requests_loop() {
  local i=0
  while [[ ! -f "$STOP_FLAG" ]]; do
    i=$((i + 1))
    local sec; sec=$(printf "%02d" $((i % 60)))
    local ts; ts=$(($(date +%s%N) / 1000000))
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" -m 5 -X POST http://localhost/api/v1/readings \
      -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
      -H "Idempotency-Key: $(python3 -c 'import uuid; print(uuid.uuid4())')" \
      -d "{\"meterId\":\"$METER_ID\",\"readingTimestamp\":\"2026-09-01T00:01:${sec}Z\",\"value\":${i}.0}" \
      2>/dev/null || echo "000")
    code="${code: -3}"
    [[ -z "$code" ]] && code="000"
    echo "${ts} ${code} ${i}" >> "$REQUEST_LOG"
    sleep 0.3
  done
}

echo
echo "=== Starting continuous app-level write traffic (background, ~3.3 req/s) ==="
send_requests_loop &
LOOP_PID=$!
sleep 2

echo
echo "=== Killing $CURRENT_MASTER ==="
T0_MS=$(($(date +%s%N) / 1000000))
KILL_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
docker compose stop "$CURRENT_MASTER"

echo
echo "=== Polling up to 30s for a surviving replica to become master (infra-level) ==="
NEW_MASTER=""
for i in $(seq 1 30); do
  for svc in redis-replica-1 redis-replica-2; do
    if docker compose ps --status running --format '{{.Service}}' | grep -qx "$svc"; then
      ROLE=$(docker compose exec -T "$svc" redis-cli ROLE 2>/dev/null | head -1)
      if [ "$ROLE" = "master" ]; then
        NEW_MASTER="$svc"
        break 2
      fi
    fi
  done
  sleep 1
done
if [[ -z "$NEW_MASTER" ]]; then
  echo "!!! No promotion within 30s -- real failure, not a timing artifact" >&2
  kill "$LOOP_PID" 2>/dev/null || true
  touch "$STOP_FLAG"
  exit 1
fi
T1_MS=$(($(date +%s%N) / 1000000))
echo "New master: $NEW_MASTER -- infra-level RTO: $((T1_MS - T0_MS))ms"

echo
echo "=== Continuing app traffic for 20s past infra-level promotion ==="
sleep 20

echo
echo "=== Stopping traffic and restoring $CURRENT_MASTER ==="
touch "$STOP_FLAG"
LAST_I=$(tail -1 "$REQUEST_LOG" | awk '{print $3}')
wait "$LOOP_PID" 2>/dev/null || true
docker compose start "$CURRENT_MASTER"

TOTAL=$(wc -l < "$REQUEST_LOG" | tr -d ' ')
SUCCESS=$(awk '$2 == 201' "$REQUEST_LOG" | wc -l | tr -d ' ')
FAIL=$((TOTAL - SUCCESS))

echo
echo "=== Waiting up to 20s for the LAST request's async cache write to land on $NEW_MASTER ==="
LAST_SEC=$(printf "%02d" $((LAST_I % 60)))
CACHE_CAUGHT_UP="no"
CACHE_MS=""
CACHE_START=$SECONDS
while (( SECONDS - CACHE_START < 20 )); do
  VAL=$(docker compose exec -T "$NEW_MASTER" redis-cli GET "reading:latest:${METER_ID}" 2>/dev/null || true)
  if echo "$VAL" | grep -q "\"readingTimestamp\":\"2026-09-01T00:01:${LAST_SEC}Z\""; then
    CACHE_CAUGHT_UP="yes"
    CACHE_MS=$(( (SECONDS - CACHE_START) * 1000 ))
    break
  fi
  sleep 0.5
done

echo
echo "=== Checking api logs for Redis-specific exceptions during the outage window (Kafka consumer health) ==="
# Deliberately Redis-specific, not a generic "exception|error" grep -- this environment has a
# separate, pre-existing, unrelated background noise source (intermittent "Failed to resolve
# 'tempo'" tracing-exporter errors) that would otherwise inflate this count with nothing to do
# with Redis, making the number meaningless for what this check actually exists to answer.
REDIS_EXCEPTION_COUNT=$(docker compose logs api --since "$KILL_ISO" 2>&1 | grep -ci "redis" || true)
CONSUMER_STUCK_EVIDENCE=$(docker compose logs api --since "$KILL_ISO" 2>&1 | grep -i "RedisConnectionFailureException\|RedisCommandTimeoutException" | tail -5)

echo
echo "=== RESULT SUMMARY ==="
echo "Old master: $CURRENT_MASTER -> New master: $NEW_MASTER"
echo "Total requests during run: $TOTAL (success: $SUCCESS, failed/timed-out: $FAIL)"
echo "HTTP status code breakdown:"
awk '{print $2}' "$REQUEST_LOG" | sort | uniq -c
echo "Async cache write for the LAST request caught up on new master ($NEW_MASTER): $CACHE_CAUGHT_UP${CACHE_MS:+ (~${CACHE_MS}ms after promotion+20s window started)}"
echo "Lines mentioning Redis in api logs during outage window: $REDIS_EXCEPTION_COUNT"
if [[ -n "$CONSUMER_STUCK_EVIDENCE" ]]; then
  echo "Redis-related exceptions seen in api logs (expected during the outage, informational):"
  echo "$CONSUMER_STUCK_EVIDENCE"
fi

echo
echo "=== Cleanup: deleting the test meter's readings via direct SQL (readings are immutable, no DELETE endpoint) ==="
docker compose exec -T patroni-1 psql -U gridmeter -d gridmeter -c \
  "DELETE FROM readings WHERE meter_id = '${METER_ID}';" 2>&1
docker compose exec -T patroni-1 psql -U gridmeter -d gridmeter -c \
  "DELETE FROM meters WHERE id = '${METER_ID}';" 2>&1
docker compose exec -T "$NEW_MASTER" redis-cli DEL "reading:latest:${METER_ID}" 2>&1
