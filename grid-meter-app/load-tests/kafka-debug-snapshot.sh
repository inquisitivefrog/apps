#!/usr/bin/env bash
# Captures a point-in-time diagnostic snapshot of the Kafka cluster: effective config, the
# `readings` topic's replica/ISR state, which broker is the active controller, and the JMX
# counters most relevant to the unclean-leader-election investigation (see
# docs/testing-strategy-ha-supplement.md's Finding 2). Meant to be run before and after a chaos
# scenario (e.g. kafka-unclean-election-dynamic-override.sh) so a run produces real before/after
# evidence for an upstream bug report, not just a single post-hoc description.
#
# Requires the debug overlay to be up for the JMX section to work:
#   docker compose -f docker-compose.yml -f docker-compose.kafka-debug.yml up -d
# Runs fine without it too -- the config/topic-state sections don't need JMX, only the counters
# section does, and it says so plainly if JMX isn't reachable rather than failing the whole script.
#
# Usage: load-tests/kafka-debug-snapshot.sh [label]
#   label - optional tag included in the output banner (e.g. "before", "after") to make a
#           before/after pair easy to diff visually. Also used in the output filename.
#
# Every run's full output is also saved to
# load-tests/vendor-bug-reports/kafka/runs/<timestamp>-<label>.txt -- this is the evidence archive
# for the eventual upstream JIRA submission (account requested, pending approval as of
# 2026-08-29), so runs need to land in files, not just terminal scrollback. See
# load-tests/vendor-bug-reports/README.md for the directory convention (this project also runs
# equivalent HA investigations for other technologies -- Redis/Sentinel, Postgres clustering -- in
# sibling directories there, not just Kafka).
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1

LABEL="${1:-snapshot}"
mkdir -p load-tests/vendor-bug-reports/kafka/runs
OUTFILE="load-tests/vendor-bug-reports/kafka/runs/$(date +%Y%m%d-%H%M%S)-${LABEL}.txt"
exec > >(tee "$OUTFILE") 2>&1
echo "Saving this snapshot to $OUTFILE"

kafka_exec() {
  local svc="$1"; shift
  docker compose exec -T "$svc" /opt/kafka/bin/"$@"
}

any_running_broker() {
  for svc in kafka-1 kafka-2 kafka-3; do
    if docker compose ps --status running --format '{{.Service}}' | grep -qx "$svc"; then
      echo "$svc"
      return 0
    fi
  done
  return 1
}

banner() {
  echo
  echo "================================================================"
  echo "[$LABEL] $1"
  echo "================================================================"
}

EXEC_SVC=$(any_running_broker) || { echo "No running Kafka broker found -- nothing to snapshot."; exit 1; }

banner "readings topic: effective config"
kafka_exec "$EXEC_SVC" kafka-configs.sh --bootstrap-server localhost:9092 \
  --entity-type topics --entity-name readings --describe --all 2>/dev/null | grep -i -E "unclean|min.insync"

banner "readings topic: partition/replica/ISR state"
kafka_exec "$EXEC_SVC" kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic readings

banner "Active controller"
QUORUM_STATUS=$(kafka_exec "$EXEC_SVC" kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status 2>&1)
echo "$QUORUM_STATUS"
ACTIVE_CONTROLLER_ID=$(echo "$QUORUM_STATUS" | grep -i "LeaderId" | grep -oE '[0-9]+' | head -1)
declare -A SVC=( [1]="kafka-1" [2]="kafka-2" [3]="kafka-3" )
ACTIVE_CONTROLLER_SVC="${SVC[$ACTIVE_CONTROLLER_ID]:-}"
echo "Active controller broker: ${ACTIVE_CONTROLLER_SVC:-unknown (id=$ACTIVE_CONTROLLER_ID)}"

banner "JMX counters (only meaningful on the active controller: $ACTIVE_CONTROLLER_SVC)"
if [ -z "$ACTIVE_CONTROLLER_SVC" ] || ! docker compose ps --status running --format '{{.Service}}' | grep -qx "$ACTIVE_CONTROLLER_SVC"; then
  echo "Active controller broker not running or not determined -- skipping JMX counters."
else
  for mbean in \
    'kafka.controller:type=ControllerStats,name=UncleanLeaderElectionsPerSec' \
    'kafka.controller:type=ControllerStats,name=ElectionFromEligibleLeaderReplicasPerSec' \
    'kafka.controller:type=KafkaController,name=OfflinePartitionsCount' \
    'kafka.server:type=ReplicaManager,name=UnderMinIsrPartitionCount' \
    'kafka.server:type=ReplicaManager,name=IsrShrinksPerSec' \
    'kafka.server:type=ReplicaManager,name=IsrExpandsPerSec' \
    'kafka.server:type=ReplicaManager,name=UnderReplicatedPartitions'; do
    RESULT=$(docker compose exec -T "$ACTIVE_CONTROLLER_SVC" /opt/kafka/bin/kafka-run-class.sh org.apache.kafka.tools.JmxTool \
      --jmx-url service:jmx:rmi:///jndi/rmi://localhost:9999/jmxrmi --one-time true \
      --object-name "$mbean" 2>&1)
    if echo "$RESULT" | grep -qi "could not connect\|refused\|Exception"; then
      echo "$mbean: JMX not reachable (is the debug overlay up? see docker-compose.kafka-debug.yml)"
      break
    fi
    echo "$mbean:"
    echo "$RESULT" | tail -1
  done
fi
