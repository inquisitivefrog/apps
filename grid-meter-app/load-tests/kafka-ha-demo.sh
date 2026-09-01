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
source scripts/check-disk-headroom.sh || exit 1

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

# Defaults to exec'ing via kafka-1, which every OTHER call site in this script can rely on since
# kafka-1 is never the one taken down there -- but Scenario 1 now dynamically determines and kills
# whichever broker actually leads this run's traffic, which can BE kafka-1. A hardcoded exec target
# that happens to be the broker just killed doesn't return stale/wrong data, it fails outright
# (`docker compose exec` can't reach a stopped container at all) -- silently turning every poll
# during that outage into an empty result, indistinguishable from "no leader elected yet" and, worse
# still, not caught by anything since the loop's own `[ -n "$CUR" ]` check treats "empty because the
# query target is dead" identically to "empty because there's genuinely no leader yet". Callers that
# might kill kafka-1 must pass a witness broker that's guaranteed to survive.
cluster_state() {
  local witness="${1:-kafka-1}"
  docker compose exec -T "$witness" /opt/kafka/bin/kafka-topics.sh \
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

banner "SCENARIO 1: Tolerate the ACTUAL partition leader's loss (dynamically determined, real RTO measured)"
echo "docs/testing-strategy-ha-supplement.md flagged this as still open: the original version of"
echo "this scenario stopped kafka-2 unconditionally, regardless of whether kafka-2 actually led any"
echo "partition this test's traffic uses -- with 3 partitions spread across all 3 brokers (each"
echo "partition has its own leader) and messages keyed by meterId, a fixed broker choice risks"
echo "silently testing nothing at all if this run's meter happens to hash to a partition kafka-2"
echo "doesn't lead. It also never measured real RTO, just a fixed 5s sleep before sending traffic."
echo
echo "Determining which partition THIS meter's traffic actually lands on, via an offset diff around"
echo "a canary write, rather than assuming or hashing it ourselves (Kafka's own partitioner is the"
echo "only source of truth for this)."
BEFORE_OFFSETS=$(docker compose exec -T kafka-1 /opt/kafka/bin/kafka-get-offsets.sh \
  --bootstrap-server localhost:9092 --topic readings --time -1 2>&1)
CANARY_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 10 -X POST http://localhost/api/v1/readings \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"meterId\":\"$METER_ID\",\"readingTimestamp\":\"2026-08-28T00:00:00Z\",\"value\":0.0}")
echo "Canary reading HTTP status: $CANARY_CODE"
sleep 2
AFTER_OFFSETS=$(docker compose exec -T kafka-1 /opt/kafka/bin/kafka-get-offsets.sh \
  --bootstrap-server localhost:9092 --topic readings --time -1 2>&1)

TARGET_PARTITION=""
while IFS=: read -r _ part off_after; do
  off_before=$(echo "$BEFORE_OFFSETS" | awk -F: -v p="$part" '$2==p {print $3}')
  if [ "$off_after" -gt "${off_before:-0}" ]; then
    TARGET_PARTITION="$part"
    break
  fi
done <<< "$AFTER_OFFSETS"

if [ -z "$TARGET_PARTITION" ]; then
  echo "Could not determine target partition from the offset diff -- aborting Scenario 1 (a setup" >&2
  echo "problem, not a finding)." >&2
  exit 1
fi
echo "This meter's traffic lands on partition $TARGET_PARTITION"

# Tab-separated fields from kafka-topics.sh --describe (e.g. "Partition: 0\tLeader: 2\t...") --
# converting tabs to newlines and grepping for the exact "Partition: N" line plus the next line
# avoids both awk field-index fragility and grep -P (not available in this Mac's BSD grep, per
# CLAUDE.md's standing GNU-vs-BSD tooling note). Accepts an optional witness (see cluster_state's
# own comment for why this matters once the broker being killed can be kafka-1 itself).
find_leader() {
  cluster_state "${2:-kafka-1}" | tr '\t' '\n' | grep -A1 "^Partition: $1\$" | grep "^Leader:" | awk '{print $2}'
}
OLD_LEADER=$(find_leader "$TARGET_PARTITION")
if [ -z "$OLD_LEADER" ]; then
  echo "Could not determine partition $TARGET_PARTITION's current leader -- aborting (setup problem)." >&2
  exit 1
fi
echo "Current leader of partition $TARGET_PARTITION: broker $OLD_LEADER (kafka-$OLD_LEADER)"

# Whichever broker we're about to kill can't also be queried for state afterward -- pick a witness
# that's guaranteed to survive (mirrors the same witness pattern already used in
# load-tests/postgres-primary-failure-test.sh for the identical reason).
case "$OLD_LEADER" in
  1) WITNESS=kafka-2 ;;
  *) WITNESS=kafka-1 ;;
esac
echo "Witness broker for state queries during the outage (guaranteed to survive): $WITNESS"

echo
echo "Killing kafka-$OLD_LEADER -- the broker THIS test's traffic actually depends on, not an"
echo "assumed one -- and measuring real RTO (polling for a new leader) concurrently with sending"
echo "traffic, so some of it genuinely spans the live election window rather than only running"
echo "after recovery is already confirmed."
T0_MS=$(( $(date +%s%N) / 1000000 ))
docker compose stop "kafka-$OLD_LEADER"

RTO_FILE=$(mktemp)
(
  for i in $(seq 1 60); do
    CUR=$(find_leader "$TARGET_PARTITION" "$WITNESS")
    if [ -n "$CUR" ] && [ "$CUR" != "$OLD_LEADER" ] && [ "$CUR" != "-1" ]; then
      T1_MS=$(( $(date +%s%N) / 1000000 ))
      echo "$CUR $((T1_MS - T0_MS))" > "$RTO_FILE"
      exit 0
    fi
    sleep 0.5
  done
  echo "NONE 0" > "$RTO_FILE"
) &
RTO_PID=$!

send_readings 20 "$METER_ID"
S1_SUCCESS=$SUCCESS_COUNT; S1_FAIL=$FAIL_COUNT

wait "$RTO_PID"
read -r NEW_LEADER RTO_MS < "$RTO_FILE"
rm -f "$RTO_FILE"
if [ "$NEW_LEADER" = "NONE" ]; then
  echo "!!! No new leader elected for partition $TARGET_PARTITION within 30s -- real finding, not a timing artifact" >&2
else
  echo "New leader of partition $TARGET_PARTITION: broker $NEW_LEADER -- measured RTO: ${RTO_MS}ms (real, polled -- not assumed)"
fi

echo "--- cluster state with kafka-$OLD_LEADER down ---"
cluster_state "$WITNESS"
docker compose start "kafka-$OLD_LEADER"
echo "Waiting for kafka-$OLD_LEADER to rejoin and catch up..."
sleep 15
cluster_state

# Must clear the Kafka client's own delivery.timeout.ms (undeclared default: 120000ms) -- a
# shorter outage gets silently absorbed by the producer's background retries once brokers return
# (confirmed via a real run, see load-tests/README.md), which proves nothing about what happens
# when quorum loss actually outlasts that budget. 150s gives 30s of margin past it.
QUORUM_LOSS_SECONDS="${QUORUM_LOSS_SECONDS:-150}"

banner "SCENARIO 2: Two-broker quorum loss (kafka-2 AND kafka-3 stopped, ${QUORUM_LOSS_SECONDS}s)"
echo "Below the 2-of-3 majority; min.insync.replicas=2 cannot be satisfied with 1 broker up."
# Routes through Traefik's :55432 entrypoint (docs/postgres-ha-scope.md's Patroni cutover) rather
# than querying patroni-1 directly -- exec'ing INTO patroni-1's container for its psql binary, but
# the actual DB connection goes through Traefik to whichever node is currently primary. Querying
# patroni-1 directly would repeat the exact bug just fixed in cluster_state() above in a new
# location: correct today only because patroni-1 happens to be primary right now, silently wrong
# (or a stale replica read) the next time that isn't true. Traefik's entrypoint already exists and
# was already verified specifically to solve "reach whichever node is currently correct" --
# inheriting that rather than introducing a fresh hardcoded-node assumption.
BASELINE_COUNT=$(docker compose exec -T -e PGPASSWORD=gridmeter patroni-1 psql -h traefik -p 55432 -U gridmeter -d gridmeter -t -c \
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
DURING_OUTAGE_COUNT=$(docker compose exec -T -e PGPASSWORD=gridmeter patroni-1 psql -h traefik -p 55432 -U gridmeter -d gridmeter -t -c \
  "SELECT COUNT(*) FROM readings r JOIN meters m ON r.meter_id = m.id WHERE m.id = '$METER_ID';" | tr -d ' ')
LANDED_DURING_OUTAGE=$(( DURING_OUTAGE_COUNT - BASELINE_COUNT ))
echo "Readings landed while still below quorum: $LANDED_DURING_OUTAGE (of the 10 sent)"
echo "api log lines mentioning delivery/timeout errors during the outage:"
docker compose logs api --since "${QUORUM_LOSS_SECONDS}s" 2>&1 | grep -iE "delivery.*timeout|expir.*record|TimeoutException" | tail -10 || echo "  (none found)"

docker compose start kafka-2 kafka-3
echo "Waiting for kafka-2/kafka-3 to rejoin and catch up..."
sleep 20
cluster_state

AFTER_RECOVERY_COUNT=$(docker compose exec -T -e PGPASSWORD=gridmeter patroni-1 psql -h traefik -p 55432 -U gridmeter -d gridmeter -t -c \
  "SELECT COUNT(*) FROM readings r JOIN meters m ON r.meter_id = m.id WHERE m.id = '$METER_ID';" | tr -d ' ')
LANDED_AFTER_RECOVERY=$(( AFTER_RECOVERY_COUNT - DURING_OUTAGE_COUNT ))
echo "Additional readings that landed in the real readings table AFTER recovery: $LANDED_AFTER_RECOVERY"
echo "Total readings from the 10 sent during outage that ever landed in readings: $(( LANDED_DURING_OUTAGE + LANDED_AFTER_RECOVERY )) of 10"
# A transactional-outbox pattern was built and load-tested here at one point (captured a
# failed-delivery reading in a reading_outbox table instead of losing it outright), then
# deliberately retired -- see docs/resilience-scope.md. Any reading that never lands in
# `readings` below is genuinely gone, not delayed-but-recoverable, per that decision.

banner "SCENARIO 3: Rolling maintenance (restart all 3 brokers, one at a time)"
# The 8s wait below does NOT reliably mean the restarted broker has fully rejoined ISR --
# confirmed empirically (2026-08-30) across two full runs: real ISR-rejoin times measured at
# 13s, 18s, 19s, and 30s (once right at the original 30s poll ceiling, since raised to 60s) --
# 2 to nearly 4x the assumed 8s wait, every single time. That's not a bug in this test's outcome:
# min.insync.replicas=2 is already satisfied by the other two healthy brokers regardless of the
# restarting one's rejoin status, so sending traffic before full convergence is actually the MORE
# rigorous version of this test -- it proves zero client impact during partial rejoin (confirmed:
# 0 failures across 30 requests in both full runs), not just after everything has quietly
# settled. The actual bug was this test's own narration implying convergence had happened by the
# time reads/writes were sent, which measurement showed is essentially never true -- fixed below
# by measuring and reporting the real convergence time instead of assuming it.
S3_SUCCESS=0
S3_FAIL=0
for broker in kafka-1 kafka-2 kafka-3; do
  echo "--- Restarting $broker ---"
  RESTART_EPOCH=$(date +%s)
  docker compose restart "$broker"
  sleep 8
  echo "Sending traffic now -- NOT waiting for full ISR rejoin first (see comment above for why)"
  send_readings 10 "$METER_ID"
  S3_SUCCESS=$((S3_SUCCESS + SUCCESS_COUNT))
  S3_FAIL=$((S3_FAIL + FAIL_COUNT))
  BROKER_ID="${broker##*-}"
  REJOINED_AT=""
  # 60s ceiling, not 30 -- a real measurement came in at exactly t+30s once, meaning a 30s ceiling
  # risks silently capping (and understating) a genuinely longer convergence time in a future run.
  for i in $(seq 1 60); do
    ISR_LINES=$(cluster_state)
    MISSING=$(echo "$ISR_LINES" | grep "Isr:" | grep -vc "\b${BROKER_ID}\b")
    if [ "$MISSING" -eq 0 ]; then
      REJOINED_AT=$(( $(date +%s) - RESTART_EPOCH ))
      break
    fi
    sleep 1
  done
  if [ -n "$REJOINED_AT" ]; then
    echo "Measured: $broker fully rejoined ISR on all partitions at t+${REJOINED_AT}s after restart (test sent traffic at t+8s, before this measurement)"
  else
    echo "Measured: $broker had NOT fully rejoined ISR even after 60s -- worth investigating on its own"
  fi
done

banner "Results"
echo "Scenario 1 (actual partition leader loss, partition $TARGET_PARTITION, kafka-$OLD_LEADER -> ${NEW_LEADER:-none}):"
echo "  $S1_SUCCESS succeeded, $S1_FAIL failed (of $((S1_SUCCESS + S1_FAIL))); measured RTO: ${RTO_MS:-N/A}ms"
[ "$S1_FAIL" -eq 0 ] && echo "  PASS: zero impact from the actual leader's loss, as RF=3 promises." \
  || echo "  Some failures during the actual leader's loss -- worth investigating, not automatically a bug (see script header)."
echo "Scenario 2 (two-broker quorum loss, ${QUORUM_LOSS_SECONDS}s):"
echo "  HTTP level:     $S2_SUCCESS succeeded, $S2_FAIL failed (of $((S2_SUCCESS + S2_FAIL))) -- NOT the real evidence, see below."
echo "  Durability:     $LANDED_DURING_OUTAGE of 10 landed while still below quorum; $LANDED_AFTER_RECOVERY more landed after recovery."
TOTAL_LANDED=$(( LANDED_DURING_OUTAGE + LANDED_AFTER_RECOVERY ))
if [ "$TOTAL_LANDED" -lt 10 ]; then
  echo "  REAL DATA LOSS: $(( 10 - TOTAL_LANDED )) reading(s) never reached the readings table --"
  echo "  delivery.timeout.ms (undeclared default: 120000ms) expired before quorum was restored."
  echo "  Accepted per docs/resilience-scope.md's redo-path decision: a simulated meter reading has"
  echo "  no real downstream consequence if lost, so this is observed (deliveryFailureCounter, the"
  echo "  'reading delivery failures' alert) rather than prevented via an outbox+reconciler."
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
