#!/usr/bin/env bash
# The clean, uncofounded Failover/RTO test testing-strategy-ha-supplement.md calls for: kill the
# current partition leader (only), keep the other 2 brokers (and controller quorum) healthy,
# measure actual wall-clock time to a new leader, confirm writes resume with no data loss.
#
# Deliberately NOT the same shape as kafka-ha-demo.sh's quorum-loss scenario (which stops 2 of 3
# brokers on purpose to test unsafe-quorum behavior) -- this test isolates leader failover alone,
# with quorum never at risk, matching the doc's own distinction between "does failover work" and
# "does the cluster fail safe when quorum is lost" as two different questions.
#
# Usage: load-tests/kafka-leader-failover-rto.sh
# Prerequisites: full stack up, all 3 Kafka brokers healthy, acks=all + replication factor 3
# already configured (see application.yml / KafkaTopicConfig.java).
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1
source scripts/check-no-stray-traffic.sh || exit 1

KAFKA_BIN="docker compose exec -T kafka-1 /opt/kafka/bin"
TOKEN=""

banner() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

login() {
  TOKEN=$(curl -s -X POST http://localhost/api/v1/auth/login \
    -H 'Content-Type: application/json' \
    -d '{"username":"demo","password":"GridMeter!Demo2026"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['accessToken'])")
}

describe_topic() {
  $KAFKA_BIN/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic readings
}

now_ms() {
  python3 -c "import time; print(int(time.time()*1000))"
}

banner "Pre-check: full ISR, identify current leader distribution"
describe_topic
login
METER_ID=$(curl -s -X POST http://localhost/api/v1/meters \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"serialNumber":"MTR-RTO-TEST-'"$(date +%s)"'","location":"rto-test","status":"ACTIVE","installedAt":"2026-01-01T00:00:00Z"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])")
echo "Meter: $METER_ID"

banner "Baseline write (confirms pipeline healthy before the test)"
curl -s -o /dev/null -w "HTTP %{http_code}\n" -X POST http://localhost/api/v1/readings \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -H "Idempotency-Key: $(python3 -c 'import uuid; print(uuid.uuid4())')" \
  -d '{"meterId":"'"$METER_ID"'","readingTimestamp":"2026-08-28T12:00:00Z","value":1.111}'

# Dynamically determined, not a stale hardcoded assumption -- an earlier version of this script
# hardcoded LEADER_SVC="kafka-2" based on a one-time observation written into a comment, never
# re-verified at runtime. Confirmed live (2026-09-03) this goes stale fast: on a real re-run,
# kafka-2 wasn't leading any partition at all, so "stopping the leader" tested nothing real --
# the identical bug already found and fixed once in kafka-ha-demo.sh's own Scenario 1, just never
# ported to this sibling script until now. Picks whichever broker currently leads the MOST
# partitions (preserving this test's original intent -- impact the whole topic's traffic, not
# just one partition -- without requiring the fragile precondition that one broker leads
# literally all 3, which isn't the guaranteed steady state: leadership has been observed split
# across all 3 brokers in some runs, concentrated in one in others). Same "pick the broker
# leading the most partitions right now" technique already proven in this project's
# kafka-controller-failover-rto-test.py.
banner "Determining which broker currently leads the most partitions (real state, not an assumption)"
DESC=$(describe_topic)
echo "$DESC"
LEADER_ID=$(echo "$DESC" | grep -oE "Leader: [0-9]+" | awk '{print $2}' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
if [ -z "$LEADER_ID" ]; then
  echo "Could not determine any partition leader from describe_topic output -- aborting." >&2
  exit 1
fi
LEADER_SVC="kafka-$LEADER_ID"
# Reuses the exact `grep -oE "Leader: [0-9]+"` extraction already proven correct above, rather
# than grep -c "Leader: N$" -- caught live (2026-09-03) that the $ end-of-line anchor never
# matches, since "Leader: N" is always followed by more tab-separated fields (Replicas:, Isr:,
# ...) on the same line, not end-of-line. That bug silently zeroed this count and, more
# seriously, made the STILL_OLD check below a structural no-op (always reading 0 regardless of
# whether the old leader was still reported) -- caught by actually running this and noticing the
# printed count didn't match the describe_topic output directly above it, not assumed correct
# because the syntax looked plausible.
LED_COUNT=$(echo "$DESC" | grep -oE "Leader: [0-9]+" | awk -v id="$LEADER_ID" '$2==id' | wc -l | tr -d ' ')
echo "$LEADER_SVC currently leads $LED_COUNT of 3 partitions -- this is the broker being stopped"

banner "Stopping the leader ($LEADER_SVC) -- the other two brokers (and controller quorum) stay up"
STOP_START=$(now_ms)
docker compose stop "$LEADER_SVC"

banner "Polling for new leader election across all 3 partitions"
NEW_LEADER_MS=""
for i in $(seq 1 60); do
  DESC=$(describe_topic 2>/dev/null)
  LEADERLESS=$(echo "$DESC" | grep -c "Leader: -1\|Leader: none")
  STILL_OLD=$(echo "$DESC" | grep -oE "Leader: [0-9]+" | awk -v id="$LEADER_ID" '$2==id' | wc -l | tr -d ' ')
  if [ "$LEADERLESS" -eq 0 ] && [ "$STILL_OLD" -eq 0 ]; then
    NEW_LEADER_MS=$(( $(now_ms) - STOP_START ))
    echo "All 3 partitions have a new leader (not broker $LEADER_ID, not leaderless) after ${NEW_LEADER_MS}ms"
    echo "$DESC"
    break
  fi
  sleep 0.5
done
if [ -z "$NEW_LEADER_MS" ]; then
  echo "Did not observe full new-leader election within 30s -- current state:"
  describe_topic
fi

banner "Sending a write immediately -- measuring time until it succeeds again"
WRITE_START=$(now_ms)
for i in $(seq 1 60); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 5 -X POST http://localhost/api/v1/readings \
    -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
    -H "Idempotency-Key: $(python3 -c 'import uuid; print(uuid.uuid4())')" \
    -d '{"meterId":"'"$METER_ID"'","readingTimestamp":"2026-08-28T12:00:0'"$i"'Z","value":2.'"$i"'}')
  if [ "$HTTP_CODE" == "201" ]; then
    echo "First successful write returned HTTP 201 after $(( $(now_ms) - WRITE_START ))ms of retrying"
    break
  fi
  sleep 0.5
done

banner "Confirming that write actually landed durably (not just a fast HTTP 201 -- ingest() is"
echo "fire-and-forget, so the real proof is the record reaching Postgres, not the HTTP response)"
sleep 5
# The standalone `postgres` container this used to target was retired in Postgres HA Stage 7
# (docs/postgres-ha-scope.md) -- this call was silently, unconditionally broken until now, not
# just fragile under some fault. Routes through Traefik's :55432 entrypoint instead, reusing the
# exact pattern kafka-ha-demo.sh's own Scenario 2 durability check already uses: exec into
# patroni-1 purely to borrow its psql binary (this script never touches Patroni/Postgres nodes,
# so patroni-1 is safe to assume up), but the actual DB connection routes through Traefik to
# whichever node is currently primary, not to patroni-1's own local database.
docker compose exec -T -e PGPASSWORD=gridmeter patroni-1 psql -h traefik -p 55432 -U gridmeter -d gridmeter -t -c \
  "SELECT COUNT(*) FROM readings WHERE meter_id = '$METER_ID';"

banner "Restarting $LEADER_SVC and confirming it rejoins cleanly"
docker compose start "$LEADER_SVC"
sleep 15
describe_topic

banner "Total RTO summary"
echo "Time to full 3-partition leader re-election after stopping the leader: ${NEW_LEADER_MS:-unknown}ms"
echo "This is the number testing-strategy-ha-supplement.md's Failover/RTO test explicitly asks for."
