#!/usr/bin/env bash
# Variant of kafka-unclean-election-KAFKA-19148.sh that tests whether an EXPLICIT DYNAMIC
# topic-level unclean.leader.election.enable=false override changes the outcome, vs. relying on
# the unset broker DEFAULT_CONFIG (which is what the original script's baseline reproduction used).
#
# Why this matters: KAFKA-19148 (previously cited in docs/testing-strategy-ha-supplement.md) was
# confirmed WRONG -- it's resolved in 4.1.0 and describes a different mechanism than what was
# reproduced here. KAFKA-19552 ("Unclean leader election fails due to precedence issue") is a
# candidate instead, but its documented mechanism is a STATIC broker-vs-controller config
# precedence bug, opposite polarity from our case (their bug: wanting unclean election *enabled*
# but the controller ignores it; ours: unclean election happening despite wanting it *disabled*).
# This script isolates one more variable: does the election-safety check even consult a topic's own
# DYNAMIC config at all, or does it fall back to some other value regardless of what's configured
# and how? If it still reproduces with an explicit dynamic override in place, that's a materially
# stronger finding than reproducing against an unset default -- it would mean the effective,
# confirmed-live config is being outright ignored during the actual election decision, not just
# defaulted. If it does NOT reproduce here, the mechanism is likely specific to relying on the
# implicit default rather than "config is ignored" in general.
#
# This is a TRACKING/experiment script, not a merge gate -- same treatment as the sibling
# KAFKA-19148 script. Always exits 0. Cleans up its own dynamic override at the end either way, so
# it doesn't leave permanent state behind (this override was never meant to be permanent -- the fix
# for the underlying undeclared-default gap is a static docker-compose.yml change, tracked
# separately).
#
# Usage: load-tests/kafka-unclean-election-dynamic-override.sh
# Prerequisites: full stack up, all 3 Kafka brokers healthy. For full internal-state evidence
# (TRACE-level controller/state-change logs, JMX counters), bring the debug overlay up first:
#   docker compose -f docker-compose.yml -f docker-compose.kafka-debug.yml up -d
#
# Every run's full output, plus each broker's controller.log/state-change.log if the debug overlay
# is active, is saved under load-tests/vendor-bug-reports/kafka/runs/<timestamp>-dynamic-override/
# -- this is the evidence archive for the eventual upstream JIRA submission (account requested,
# pending approval as of 2026-08-29), so runs need to land in files, not just terminal scrollback.
# Update load-tests/vendor-bug-reports/kafka/NOTES.md's run table after a run worth keeping.
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1

RUN_TS="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="load-tests/vendor-bug-reports/kafka/runs/${RUN_TS}-dynamic-override"
mkdir -p "$RUN_DIR"
OUTFILE="${RUN_DIR}/run-transcript.txt"
exec > >(tee "$OUTFILE") 2>&1
echo "Saving this run's output to $OUTFILE"

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
MARKER="dynamic-override-marker-$(date +%s)"

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

cleanup() {
  banner "Cleanup: removing the dynamic topic-level override (never meant to be permanent)"
  kafka_exec kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name readings \
    --alter --delete-config unclean.leader.election.enable 2>&1 | tail -5
}
trap cleanup EXIT

banner "Setting an EXPLICIT DYNAMIC topic-level override: unclean.leader.election.enable=false"
kafka_exec kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name readings \
  --alter --add-config unclean.leader.election.enable=false 2>&1 | tail -5

banner "Confirming the dynamic override is genuinely in effect (not assumed)"
CONFIRM=$(kafka_exec kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name readings --describe --all 2>/dev/null | grep -i unclean)
echo "$CONFIRM"
if ! echo "$CONFIRM" | grep -q "DYNAMIC_TOPIC_CONFIG"; then
  echo "Dynamic override did not take effect as DYNAMIC_TOPIC_CONFIG -- aborting (not a finding either way)."
  exit 0
fi

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

banner "Producing the marked record directly to Kafka with acks=1 (bypassing this app entirely)"
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

banner "Restoring $LEADER_SVC"
docker compose start "$LEADER_SVC"
sleep 15
describe_topic

banner "VERDICT"
if [ -n "$NEW_LEADER" ] && [ "$NEW_LEADER" != "$LEADER" ] && [ "$NEW_LEADER" != "-1" ]; then
  echo "REPRODUCED WITH AN EXPLICIT DYNAMIC OVERRIDE IN PLACE: broker $NEW_LEADER (a follower with no"
  echo "copy of the marked record) was elected leader for partition $TARGET_PARTITION while broker"
  echo "$LEADER (the only broker holding the record) was down -- despite a confirmed-live DYNAMIC"
  echo "topic-level unclean.leader.election.enable=false override, not just an unset default. This is"
  echo "a stronger finding than the original default-config reproduction: the election-safety check"
  echo "is ignoring the topic's own live effective config outright."
else
  echo "NOT REPRODUCED this run with the dynamic override in place (new leader for partition"
  echo "$TARGET_PARTITION: ${NEW_LEADER:-none/leaderless}). Suggests the original reproduction may be"
  echo "specific to relying on the implicit/unset default rather than the election check ignoring"
  echo "config outright -- worth re-running the ORIGINAL default-config script again on this same"
  echo "cluster state to confirm the default-config case still reproduces, isolating override-vs-default"
  echo "as the actual variable rather than run-to-run timing noise."
fi

banner "Pulling per-broker controller.log / state-change.log (debug overlay TRACE output, if active)"
for svc in kafka-1 kafka-2 kafka-3; do
  if docker compose ps --status running --format '{{.Service}}' | grep -qx "$svc"; then
    for f in controller.log state-change.log; do
      DEST="${RUN_DIR}/${svc}-${f}"
      if docker compose cp "${svc}:/opt/kafka/logs/${f}" "$DEST" 2>/dev/null; then
        echo "Saved $DEST"
      else
        echo "Could not pull ${f} from ${svc} (debug overlay not active, or file not present yet)"
      fi
    done
  else
    echo "${svc} not running -- skipped"
  fi
done
