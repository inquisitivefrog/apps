#!/usr/bin/env bash
# Tracks KAFKA-19148 ("Potential Unclean Leader Election in KRaft Despite
# unclean.leader.election.enable=false") against this project's actual pinned Kafka version
# (4.3.1, apache/kafka image, KRaft mode) -- an UPSTREAM Kafka bug, not something this project's
# own config can fix. Reported against 4.0.0 and 3.9.0 in KRaft mode; the same scenario in
# ZooKeeper mode did not trigger an unclean election, so it's KRaft-specific. No fix version
# listed as of this writing; a related, separately-tracked issue (KAFKA-19552) is also still open
# against 3.9.0 with no fix version.
#
# Found by accident while verifying the acks=all fix (see application.yml's own comment and
# docs/resilience-scope.md): during that verification, a follower broker with NO copy of an
# acknowledged write was elected leader for its partition while the true leader (the only broker
# that had the write) was down -- despite unclean.leader.election.enable=false being the real,
# confirmed-live effective config (not an oversight -- see the `kafka-configs.sh --describe`
# check this script also runs). This script isolates that exact mechanism, independent of this
# app's own acks setting: it talks to Kafka directly via kafka-console-producer.sh with an
# explicit acks override, bypassing the Spring app entirely, so a reproduction here is
# unambiguously a Kafka/KRaft-level issue, not an artifact of anything in application.yml.
#
# This is a TRACKING script, not a merge gate -- same "load tests never block a PR" treatment
# testing-strategy.md already gives load-tests/, because whether this reproduces is a statement
# about upstream Kafka's current state, not about a regression in this codebase. It always exits
# 0. What matters is the printed verdict: REPRODUCED (the bug is still present, matching JIRA's
# current unresolved status) or NOT REPRODUCED THIS RUN (either fixed upstream -- check JIRA
# before assuming so, since this is a timing-sensitive race -- or this particular run didn't hit
# the exact race window; re-run before concluding anything from a single non-reproduction).
#
# Usage: load-tests/kafka-unclean-election-KAFKA-19148.sh
# Prerequisites: full stack up, all 3 Kafka brokers healthy.
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1

# Every broker gets stopped at some point in this script (that's the whole point), so exec target
# must be picked dynamically -- hardcoding kafka-1 silently fails ("service is not running") for
# any step that happens to run while kafka-1 specifically is down, invalidating whatever that step
# was supposed to prove.
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
MARKER="KAFKA-19148-marker-$(date +%s)"

banner() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

describe_topic() {
  kafka_exec kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic readings
}

partition_offsets() {
  kafka_exec kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic readings 2>/dev/null | sort
}

banner "Confirming unclean.leader.election.enable=false is genuinely in effect (not assumed)"
kafka_exec kafka-configs.sh --bootstrap-server localhost:9092 \
  --entity-type brokers --entity-name 1 --describe --all 2>/dev/null | grep -i unclean

banner "Discovering a target partition via a throwaway raw record"
BEFORE=$(partition_offsets)
echo "discovery-record" | kafka_exec kafka-console-producer.sh --bootstrap-server localhost:9092 --topic readings >/dev/null 2>&1
sleep 2
AFTER=$(partition_offsets)
TARGET_PARTITION=$(diff <(echo "$BEFORE") <(echo "$AFTER") | grep '^>' | sed -E 's/.*readings:([0-9]+):.*/\1/' | head -1)
if [ -z "$TARGET_PARTITION" ]; then
  echo "Could not determine target partition -- aborting (not a bug finding either way)."
  exit 0
fi
echo "Target partition: $TARGET_PARTITION"

DESC=$(describe_topic)
echo "$DESC"
LEADER=$(echo "$DESC" | grep "Partition: $TARGET_PARTITION" | grep -oE 'Leader: [0-9]+' | grep -oE '[0-9]+')
REPLICAS=$(echo "$DESC" | grep "Partition: $TARGET_PARTITION" | grep -oE 'Replicas: [0-9,]+' | grep -oE '[0-9,]+')
declare -A SVC=( [1]="kafka-1" [2]="kafka-2" [3]="kafka-3" )
LEADER_SVC=${SVC[$LEADER]}
FOLLOWER_SVCS=""
for b in ${REPLICAS//,/ }; do
  [ "$b" != "$LEADER" ] && FOLLOWER_SVCS="$FOLLOWER_SVCS ${SVC[$b]}"
done
echo "Leader: $LEADER_SVC, followers:$FOLLOWER_SVCS"

banner "Stopping followers ($FOLLOWER_SVCS) -- ISR should shrink to leader-only"
docker compose stop $FOLLOWER_SVCS
sleep 5

banner "Producing the marked record directly to Kafka with acks=1 (bypassing this app entirely --"
echo "this is deliberately NOT going through the Spring app or its acks=all config, to isolate"
echo "the KRaft election mechanism itself from anything this project controls)"
echo "$MARKER" | kafka_exec kafka-console-producer.sh --bootstrap-server localhost:9092 --topic readings \
  --request-required-acks 1 --timeout 10000 2>&1 | tail -5

banner "Immediately stopping the leader ($LEADER_SVC) too -- followers never received the marker"
docker compose stop "$LEADER_SVC"
sleep 3

banner "Restarting followers ONLY (leader still down)"
docker compose start $FOLLOWER_SVCS
sleep 15
DESC_AFTER=$(describe_topic)
echo "$DESC_AFTER"

NEW_LEADER=$(echo "$DESC_AFTER" | grep "Partition: $TARGET_PARTITION" | grep -oE 'Leader: [0-9]+' | grep -oE '[0-9]+')

banner "Restoring $LEADER_SVC and cleaning up"
docker compose start "$LEADER_SVC"
sleep 15
describe_topic

banner "VERDICT"
if [ -n "$NEW_LEADER" ] && [ "$NEW_LEADER" != "$LEADER" ] && [ "$NEW_LEADER" != "-1" ]; then
  echo "REPRODUCED: broker $NEW_LEADER (a follower with no copy of the marked record) was elected"
  echo "leader for partition $TARGET_PARTITION while broker $LEADER (the only broker holding the"
  echo "record) was down -- despite unclean.leader.election.enable=false. This matches KAFKA-19148's"
  echo "reported signature. Known upstream issue, no fix version as of this writing -- see"
  echo "docs/resilience-scope.md for how this project responded (acks=all closes the 'accepted a"
  echo "write nobody else has' half of the risk; this specific election-safety gap is upstream and"
  echo "out of this project's control to close directly)."
else
  echo "NOT REPRODUCED this run (new leader for partition $TARGET_PARTITION: ${NEW_LEADER:-none/leaderless})."
  echo "This is a timing-sensitive race -- don't conclude the bug is fixed from one non-reproducing"
  echo "run. Re-run this script, and separately check KAFKA-19148's live JIRA status before updating"
  echo "any documentation that currently describes it as unresolved."
fi
