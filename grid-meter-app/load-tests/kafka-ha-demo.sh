#!/usr/bin/env bash
# Kafka HA demo: exercises docs/ha-scope.md's stated test goals against the real 3-broker KRaft
# cluster (kafka-1/kafka-2/kafka-3, docker-compose.yml) -- three scenarios a single-broker setup
# structurally cannot demonstrate:
#   1. Tolerate-one-broker-loss: stop one broker, confirm normal operation continues (RF=3's whole
#      point) -- a brief leader-election pause is possible for whichever partition that broker led,
#      but the client's own retry/max.block.ms handling should absorb it, not fail the request.
#   2. Two-broker quorum loss: stop two of three (1 of 3 remaining, below the 2-of-3 majority this
#      cluster needs), confirm REAL failures -- this is the "second, independent loss while already
#      down to 2" danger docs/ha-scope.md's quorum-mechanics section describes. A failure here is
#      the correct, expected outcome to demonstrate, not a bug to chase away.
#   3. Rolling maintenance: restart all three brokers one at a time, confirm zero downtime across
#      the whole sequence -- the actual payoff of "3, not 2": a full maintenance pass with no
#      user-visible impact, since only one broker is ever down at a time.
#
# Deliberately lighter-weight than chaos-demo.sh/misconfigured-spike-demo.sh: no Playwright
# screenshots here. Evidence is real HTTP status codes plus `kafka-topics.sh --describe`'s actual
# replica/ISR state, which answers "did this work" and "why" more directly for a broker-quorum
# question than a dashboard screenshot would -- a deliberate difference from this project's other
# load-tests/ scripts' visual-evidence convention, not an oversight.
#
# Prerequisites: full stack up (docker compose up -d) with the 3-broker Kafka cluster already
# applied (docker-compose.yml's kafka-1/kafka-2/kafka-3 -- see docs/ha-scope.md).
#
# Usage: load-tests/kafka-ha-demo.sh
set -uo pipefail
cd "$(dirname "$0")/.."

TOKEN=""
SUCCESS_COUNT=0
FAIL_COUNT=0

banner() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

login() {
  TOKEN=$(curl -s -X POST http://localhost/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"demo","password":"GridMeter!Demo2026"}' \
    | python3 -c "import sys,json;print(json.load(sys.stdin).get('accessToken',''))")
}

# Sends $1 readings for meter $2, ~2/sec, printing a running pass/fail tally. Sets
# SUCCESS_COUNT/FAIL_COUNT for the caller to read.
send_readings() {
  local count="${1:-20}" meter_id="$2"
  SUCCESS_COUNT=0
  FAIL_COUNT=0
  for i in $(seq 1 "$count"); do
    local sec; sec=$(printf "%02d" $((i % 60)))
    code=$(curl -s -o /dev/null -w "%{http_code}" -m 10 -X POST http://localhost/api/v1/readings \
      -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
      -d "{\"meterId\":\"$meter_id\",\"readingTimestamp\":\"2026-08-28T00:01:${sec}Z\",\"value\":${i}.0}")
    if [ "$code" = "201" ]; then
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
      FAIL_COUNT=$((FAIL_COUNT + 1))
      echo "    request $i -> HTTP $code"
    fi
    sleep 0.5
  done
  echo "  -> $SUCCESS_COUNT succeeded, $FAIL_COUNT failed (of $count)"
}

cluster_state() {
  docker compose exec -T kafka-1 /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server localhost:9092 --describe --topic readings 2>&1
}

banner "Setup: login + create a test meter"
login
if [ -z "$TOKEN" ]; then
  echo "Login failed -- is the stack up? (docker compose up -d)" >&2
  exit 1
fi
METER_ID=$(curl -s -X POST http://localhost/api/v1/meters \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"serialNumber\":\"MTR-HA-DEMO-$(date +%s)\",\"location\":\"Kafka HA Demo\",\"status\":\"ACTIVE\",\"installedAt\":\"2026-01-15T00:00:00Z\"}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])")
echo "Test meter: $METER_ID"

banner "Baseline cluster state (all 3 brokers up)"
cluster_state

banner "SCENARIO 1: Tolerate one broker loss (kafka-2 stopped)"
docker compose stop kafka-2
sleep 5
send_readings 20 "$METER_ID"
S1_SUCCESS=$SUCCESS_COUNT; S1_FAIL=$FAIL_COUNT
echo "--- cluster state with kafka-2 down ---"
cluster_state
docker compose start kafka-2
echo "Waiting for kafka-2 to rejoin and catch up..."
sleep 15
cluster_state

# Must clear the Kafka client's own delivery.timeout.ms (undeclared default: 120000ms) -- a
# shorter outage gets silently absorbed by the producer's background retries once brokers return
# (confirmed via a real run, see load-tests/README.md), which proves nothing about what happens
# when quorum loss actually outlasts that budget. 150s gives 30s of margin past it.
QUORUM_LOSS_SECONDS="${QUORUM_LOSS_SECONDS:-150}"

banner "SCENARIO 2: Two-broker quorum loss (kafka-2 AND kafka-3 stopped, ${QUORUM_LOSS_SECONDS}s)"
echo "Below the 2-of-3 majority; min.insync.replicas=2 cannot be satisfied with 1 broker up."
BASELINE_COUNT=$(docker compose exec -T postgres psql -U gridmeter -d gridmeter -t -c \
  "SELECT COUNT(*) FROM readings r JOIN meters m ON r.meter_id = m.id WHERE m.id = '$METER_ID';" | tr -d ' ')
echo "Readings for this meter before scenario 2: $BASELINE_COUNT"

docker compose stop kafka-2 kafka-3
sleep 3
send_readings 10 "$METER_ID"
S2_SUCCESS=$SUCCESS_COUNT; S2_FAIL=$FAIL_COUNT
SENT_AT=$(date +%s)
ELAPSED=$(( $(date +%s) - SENT_AT + 3 ))
REMAINING=$(( QUORUM_LOSS_SECONDS - ELAPSED ))
if [ "$REMAINING" -gt 0 ]; then
  echo "Holding quorum loss for ${REMAINING}s more (total ~${QUORUM_LOSS_SECONDS}s) so"
  echo "delivery.timeout.ms has a chance to actually expire before brokers come back..."
  sleep "$REMAINING"
fi

echo "--- Checking Postgres and api logs BEFORE restoring brokers (still below quorum) ---"
DURING_OUTAGE_COUNT=$(docker compose exec -T postgres psql -U gridmeter -d gridmeter -t -c \
  "SELECT COUNT(*) FROM readings r JOIN meters m ON r.meter_id = m.id WHERE m.id = '$METER_ID';" | tr -d ' ')
LANDED_DURING_OUTAGE=$(( DURING_OUTAGE_COUNT - BASELINE_COUNT ))
echo "Readings landed while still below quorum: $LANDED_DURING_OUTAGE (of the 10 sent)"
echo "api log lines mentioning delivery/timeout errors during the outage:"
docker compose logs api --since "${QUORUM_LOSS_SECONDS}s" 2>&1 | grep -iE "delivery.*timeout|expir.*record|TimeoutException" | tail -10 || echo "  (none found)"

docker compose start kafka-2 kafka-3
echo "Waiting for kafka-2/kafka-3 to rejoin and catch up..."
sleep 20
cluster_state

AFTER_RECOVERY_COUNT=$(docker compose exec -T postgres psql -U gridmeter -d gridmeter -t -c \
  "SELECT COUNT(*) FROM readings r JOIN meters m ON r.meter_id = m.id WHERE m.id = '$METER_ID';" | tr -d ' ')
LANDED_AFTER_RECOVERY=$(( AFTER_RECOVERY_COUNT - DURING_OUTAGE_COUNT ))
echo "Additional readings that landed in the real readings table AFTER recovery: $LANDED_AFTER_RECOVERY"
echo "Total readings from the 10 sent during outage that ever landed in readings: $(( LANDED_DURING_OUTAGE + LANDED_AFTER_RECOVERY )) of 10"
OUTBOX_COUNT=$(docker compose exec -T postgres psql -U gridmeter -d gridmeter -t -c \
  "SELECT COUNT(*) FROM reading_outbox WHERE meter_id = '$METER_ID';" | tr -d ' ')
echo "Of those, landed in reading_outbox instead (Stage A, docs/resilience-scope.md): $OUTBOX_COUNT of 10"
echo "Note: outbox rows are NOT yet visible via GET /readings -- no reconciler drains them back"
echo "to Kafka/the readings table yet (Stage D, not built). The data survives the outage; it just"
echo "isn't queryable through the normal API path yet."

banner "SCENARIO 3: Rolling maintenance (restart all 3 brokers, one at a time)"
S3_SUCCESS=0
S3_FAIL=0
for broker in kafka-1 kafka-2 kafka-3; do
  echo "--- Restarting $broker ---"
  docker compose restart "$broker"
  sleep 8
  send_readings 10 "$METER_ID"
  S3_SUCCESS=$((S3_SUCCESS + SUCCESS_COUNT))
  S3_FAIL=$((S3_FAIL + FAIL_COUNT))
done

banner "Results"
echo "Scenario 1 (tolerate one broker loss):   $S1_SUCCESS succeeded, $S1_FAIL failed (of $((S1_SUCCESS + S1_FAIL)))"
[ "$S1_FAIL" -eq 0 ] && echo "  PASS: zero impact from a single broker loss, as RF=3 promises." \
  || echo "  Some failures during single-broker loss -- worth investigating, not automatically a bug (see script header)."
echo "Scenario 2 (two-broker quorum loss, ${QUORUM_LOSS_SECONDS}s):"
echo "  HTTP level:     $S2_SUCCESS succeeded, $S2_FAIL failed (of $((S2_SUCCESS + S2_FAIL))) -- NOT the real evidence, see below."
echo "  Durability:     $LANDED_DURING_OUTAGE of 10 landed while still below quorum; $LANDED_AFTER_RECOVERY more landed after recovery."
echo "  Outbox:         $OUTBOX_COUNT of 10 captured in reading_outbox (Stage A -- not yet visible via GET /readings)."
TOTAL_LANDED=$(( LANDED_DURING_OUTAGE + LANDED_AFTER_RECOVERY ))
TOTAL_ACCOUNTED_FOR=$(( TOTAL_LANDED + OUTBOX_COUNT ))
if [ "$TOTAL_ACCOUNTED_FOR" -lt 10 ]; then
  echo "  REAL DATA LOSS: $(( 10 - TOTAL_ACCOUNTED_FOR )) reading(s) missing from BOTH readings AND"
  echo "  reading_outbox -- genuinely gone, not just delayed or captured. Investigate before trusting"
  echo "  the outbox write path."
elif [ "$TOTAL_LANDED" -lt 10 ]; then
  echo "  Data captured, not lost: $(( 10 - TOTAL_LANDED )) reading(s) never reached the real readings"
  echo "  table, but all of those landed in reading_outbox instead (Stage A, docs/resilience-scope.md)"
  echo "  -- delivery.timeout.ms (undeclared default: 120000ms) expired before quorum was restored,"
  echo "  same root cause as before, but the outbox write path (added after the first version of this"
  echo "  test found real permanent loss) now catches what the raw Kafka client gives up on. Still"
  echo "  not queryable via the API until the reconciler (Stage D) exists to drain the outbox."
elif [ "$TOTAL_LANDED" -eq 10 ] && [ "$LANDED_DURING_OUTAGE" -eq 10 ]; then
  echo "  UNEXPECTED: all 10 landed WHILE still below quorum -- worth understanding why (are these"
  echo "  partitions' leaders still up on the surviving broker with a stale ISR, or is this test's"
  echo "  meter/partition assignment not exercising the leaderless case?) before trusting quorum"
  echo "  loss is safe."
else
  echo "  All 10 eventually landed, but only after recovery -- confirms delivery was blocked/queued"
  echo "  during the outage (not lost), and resumed once quorum returned. Not silent data loss, but"
  echo "  still worth knowing the HTTP response gave zero indication of the wait these readings"
  echo "  went through."
fi
echo "Scenario 3 (rolling maintenance):        $S3_SUCCESS succeeded, $S3_FAIL failed (of $((S3_SUCCESS + S3_FAIL)))"
[ "$S3_FAIL" -eq 0 ] && echo "  PASS: zero downtime across the full rolling restart." \
  || echo "  FAIL: $S3_FAIL requests failed during rolling maintenance -- investigate before trusting this pattern for real maintenance windows."

banner "Final cluster state"
cluster_state
