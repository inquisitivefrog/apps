#!/usr/bin/env bash
# Reproduces (then, after the acks=all fix ships, re-verifies) the gap testing-strategy-ha-
# supplement.md's Failover/RTO test explicitly calls for: "verify acks=all and a replication
# factor > 1 are actually configured, not just present in a config file." Running that check for
# real found replication factor correctly configured (3) but acks left undeclared, silently
# defaulting to the raw Kafka client's "1" (leader-only ack) -- meaning min.insync.replicas=2
# (broker-side) is never actually consulted, since that check only fires under acks=all.
#
# This script does NOT assume the textbook "acks=1 silently loses acknowledged writes" story is
# exactly what happens here -- it reproduces the real scenario against this real cluster and
# reports what actually happens, same discipline as every other empirical test in this project
# (the 150s quorum-loss re-test, the Traefik live verification, etc.). Modern Kafka defaults
# unclean.leader.election.enable=false, which could mean the real failure mode is a temporary
# availability gap (partition leaderless until the original leader returns) rather than permanent
# silent loss -- worth confirming either way, not assuming.
#
# Usage: load-tests/kafka-acks-gap-repro.sh
# Prerequisites: full stack up, all 3 Kafka brokers healthy.
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1
source scripts/check-no-stray-traffic.sh || exit 1

TOKEN=""

banner() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

# This script stops both followers AND the leader at different points (both are down
# simultaneously between "stopping the leader" and "restarting followers"), so any single
# hardcoded exec target can be, and has been confirmed live to be, the broker that's down at any
# given call site -- silently turning that call into "service is not running" instead of real
# topic state. Same kafka_exec pattern already proven in
# kafka-unclean-election-KAFKA-19148.sh (a sibling script with the identical "every broker gets
# stopped at some point" shape): picks whichever broker Compose actually reports running right
# now, not a fixed one.
kafka_exec() {
  for svc in kafka-1 kafka-2 kafka-3; do
    if docker compose ps --status running --format '{{.Service}}' | grep -qx "$svc"; then
      docker compose exec -T "$svc" /opt/kafka/bin/"$@"
      return $?
    fi
  done
  echo "No running Kafka broker found to exec through." >&2
  return 1
}

login() {
  TOKEN=$(curl -s -X POST http://localhost/api/v1/auth/login \
    -H 'Content-Type: application/json' \
    -d '{"username":"demo","password":"GridMeter!Demo2026"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['accessToken'])")
}

partition_offsets() {
  kafka_exec kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic readings 2>/dev/null | sort
}

describe_topic() {
  kafka_exec kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic readings
}

banner "Logging in and creating a test meter"
login
METER_ID=$(curl -s -X POST http://localhost/api/v1/meters \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"serialNumber":"MTR-ACKS-GAP-'"$(date +%s)"'","location":"acks-gap-test","status":"ACTIVE","installedAt":"2026-01-01T00:00:00Z"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])")
echo "Meter: $METER_ID"

banner "Baseline per-partition offsets"
BEFORE=$(partition_offsets)
echo "$BEFORE"

banner "Sending one baseline reading (value=100.001) to discover this meter's target partition"
curl -s -o /dev/null -w "HTTP %{http_code}\n" -X POST http://localhost/api/v1/readings \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -H "Idempotency-Key: $(python3 -c 'import uuid; print(uuid.uuid4())')" \
  -d '{"meterId":"'"$METER_ID"'","readingTimestamp":"2026-08-28T12:00:00Z","value":100.001}'
sleep 2
AFTER=$(partition_offsets)
echo "$AFTER"

TARGET_PARTITION=$(diff <(echo "$BEFORE") <(echo "$AFTER") | grep '^>' | sed -E 's/.*readings:([0-9]+):.*/\1/')
if [ -z "$TARGET_PARTITION" ]; then
  echo "Could not determine target partition from offset diff -- aborting."
  exit 1
fi
echo "Target partition for meter $METER_ID: $TARGET_PARTITION"

banner "Current leader/replicas for partition $TARGET_PARTITION"
describe_topic
LEADER=$(describe_topic | grep "Partition: $TARGET_PARTITION" | grep -oE 'Leader: [0-9]+' | grep -oE '[0-9]+')
REPLICAS=$(describe_topic | grep "Partition: $TARGET_PARTITION" | grep -oE 'Replicas: [0-9,]+' | grep -oE '[0-9,]+')
echo "Leader broker id: $LEADER, replicas: $REPLICAS"

declare -A BROKER_SVC=( [1]="kafka-1" [2]="kafka-2" [3]="kafka-3" )
LEADER_SVC=${BROKER_SVC[$LEADER]}
FOLLOWER_SVCS=""
for b in ${REPLICAS//,/ }; do
  if [ "$b" != "$LEADER" ]; then
    FOLLOWER_SVCS="$FOLLOWER_SVCS ${BROKER_SVC[$b]}"
  fi
done
echo "Leader service: $LEADER_SVC, follower services:$FOLLOWER_SVCS"

banner "Stopping followers ($FOLLOWER_SVCS) -- ISR for partition $TARGET_PARTITION should shrink to leader-only"
docker compose stop $FOLLOWER_SVCS
sleep 5
describe_topic

banner "Sending the marked reading (value=999.999) while followers are down"
SEND_START=$(python3 -c "import time; print(int(time.time()*1000))")
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 15 -X POST http://localhost/api/v1/readings \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -H "Idempotency-Key: $(python3 -c 'import uuid; print(uuid.uuid4())')" \
  -d '{"meterId":"'"$METER_ID"'","readingTimestamp":"2026-08-28T12:00:01Z","value":999.999}')
SEND_END=$(python3 -c "import time; print(int(time.time()*1000))")
SEND_MS=$(( SEND_END - SEND_START ))
echo "HTTP $HTTP_CODE in ${SEND_MS}ms"
if [ "$HTTP_CODE" != "201" ] || [ "$SEND_MS" -gt 2000 ]; then
  echo "NOTE: this didn't return a fast 201 -- with the current acks setting, that's unexpected"
  echo "unless it's already been changed to acks=all (in which case THIS is the expected new"
  echo "behavior: NotEnoughReplicasException/blocking until min.insync.replicas=2 can't be met)."
fi

banner "Immediately stopping the leader ($LEADER_SVC) too -- followers never received the write"
docker compose stop "$LEADER_SVC"
sleep 3

banner "Restarting followers ONLY (leader still down) -- does the partition get a leader without the write?"
docker compose start $FOLLOWER_SVCS
sleep 15
describe_topic

banner "Checking whether the marked reading (999.999) is visible yet (it shouldn't be if the"
echo "partition is correctly leaderless/unavailable without the original leader's data)"
# The standalone `postgres` container this used to target was retired in Postgres HA Stage 7
# (docs/postgres-ha-scope.md) -- this call was silently, unconditionally broken until now, not
# just fragile under some fault. Routes through Traefik's :55432 entrypoint instead, reusing the
# exact pattern kafka-ha-demo.sh's own Scenario 2 durability check already uses: exec into
# patroni-1 purely to borrow its psql binary (this script never touches Patroni/Postgres nodes,
# so patroni-1 is safe to assume up), but the actual DB connection routes through Traefik to
# whichever node is currently primary, not to patroni-1's own local database.
docker compose exec -T -e PGPASSWORD=gridmeter patroni-1 psql -h traefik -p 55432 -U gridmeter -d gridmeter -t -c \
  "SELECT COUNT(*) FROM readings WHERE meter_id = '$METER_ID' AND value = 999.999;"

banner "Restarting the original leader ($LEADER_SVC) -- it still has the record on its own disk"
# date +%N (bare, no width modifier) is the portable form -- %3N silently produces the literal
# characters "3N" appended on this project's dev Mac (confirmed: its date binary supports bare
# %N but not GNU's field-width digit prefix), which broke bash arithmetic below and, under set -e,
# silently truncated this exact loop after its first true condition without ever printing the
# recovery-time line or executing `break` -- found and fixed 2026-08-31 while building
# docs/postgres-ha-scope.md's Stage 3 script, which had copied the same broken idiom.
RECOVERY_START=$(date +%s%N)
docker compose start "$LEADER_SVC"
for i in $(seq 1 30); do
  CURRENT_LEADER=$(describe_topic | grep "Partition: $TARGET_PARTITION" | grep -oE 'Leader: [0-9]+' | grep -oE '[0-9]+')
  if [ "$CURRENT_LEADER" == "$LEADER" ]; then
    RECOVERY_END=$(date +%s%N)
    echo "Partition $TARGET_PARTITION has a leader again ($CURRENT_LEADER) after $(( (RECOVERY_END - RECOVERY_START) / 1000000 ))ms"
    break
  fi
  sleep 1
done
describe_topic

banner "Final check: is 999.999 present now that the original leader is back?"
sleep 10
docker compose exec -T -e PGPASSWORD=gridmeter patroni-1 psql -h traefik -p 55432 -U gridmeter -d gridmeter -t -c \
  "SELECT COUNT(*) FROM readings WHERE meter_id = '$METER_ID' AND value = 999.999;"

banner "Done. Interpretation:"
echo "If the count above is 1: the write survived (temporary availability gap, not permanent loss --"
echo "  Kafka's unclean.leader.election.enable=false default protected it by refusing to elect a"
echo "  stale replica; recovered once the true leader's disk came back)."
echo "If the count is 0: genuine permanent loss occurred despite the leader coming back -- worth"
echo "  investigating further before assuming the fix below closes the gap."
