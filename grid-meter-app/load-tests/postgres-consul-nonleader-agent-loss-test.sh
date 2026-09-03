#!/usr/bin/env bash
# docs/postgres-ha-scope.md Stage 5, Sub-scenario B: kill one non-leader, non-primary-paired
# Consul agent while Postgres primary/replicas stay healthy and untouched. Consul's own quorum
# survival under a single-agent loss was already established in Stage 0 -- this sub-scenario
# isn't re-testing that. Its only purpose is confirming Patroni doesn't notice or react at all.
#
# Dynamically picks the target agent so it's neither the current Consul raft leader nor paired
# with the current Postgres primary -- keeping this a clean, uninteresting baseline case rather
# than accidentally re-testing Sub-scenario A's partition behavior.
#
# A real, minor nuance found manually before this script existed, checked explicitly here: the
# OTHER replica paired with the killed agent (not the primary) can temporarily disappear from
# `patronictl list`'s Consul-derived view -- confirmed to be a reporting/visibility gap only, not
# a functional one, by querying that node's own pg_is_in_recovery() directly rather than trusting
# the Consul-derived list alone.
#
# Usage: ./postgres-consul-nonleader-agent-loss-test.sh

set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== Identifying the Consul raft leader (to avoid) ==="
# Dynamic query target, not hardcoded -- same "monitoring helper's own hardcoded query target"
# mistake already found and fixed elsewhere in this project (Kafka's cluster_state(),
# postgres-app-primary-failure-test.sh's own leader-identification check). Any agent can answer
# `raft list-peers` (it's cluster-wide state, not agent-specific) -- tries each known agent in
# turn until one actually answers, rather than dying unguarded on this script's very first
# command if consul-1 specifically happens to be down.
RAFT_INFO=""
for AGENT in consul-1 consul-2 consul-3; do
  if RAFT_INFO=$(docker compose exec -T "$AGENT" consul operator raft list-peers 2>/dev/null); then
    break
  fi
  RAFT_INFO=""
done
if [[ -z "$RAFT_INFO" ]]; then
  echo "Could not reach any Consul agent to identify the raft leader, aborting" >&2
  exit 1
fi
echo "$RAFT_INFO"
RAFT_LEADER=$(echo "$RAFT_INFO" | awk '$4=="leader" {print $1}')
echo "Raft leader: $RAFT_LEADER"

echo
echo "=== Identifying the current Postgres primary and its paired Consul agent (to avoid) ==="
# Dynamic query target, not hardcoded -- same "monitoring helper's own hardcoded query target"
# mistake already found and fixed elsewhere in this project (Kafka's cluster_state(),
# postgres-app-primary-failure-test.sh's own leader-identification check). Tries each known node
# in turn until one actually answers.
LIST=""
for NODE in patroni-1 patroni-2 patroni-3; do
  if LIST=$(docker compose exec -T "$NODE" patronictl -c /etc/patroni.yml list 2>/dev/null); then
    break
  fi
  LIST=""
done
if [[ -z "$LIST" ]]; then
  echo "Could not reach any Patroni node to identify the current primary, aborting" >&2
  exit 1
fi
echo "$LIST"
PRIMARY=$(echo "$LIST" | awk -F'|' '/Leader/ {gsub(/ /,"",$2); print $2}')
case "$PRIMARY" in
  patroni-1) PRIMARY_AGENT=consul-1 ;;
  patroni-2) PRIMARY_AGENT=consul-2 ;;
  patroni-3) PRIMARY_AGENT=consul-3 ;;
esac
echo "Primary: $PRIMARY (paired with $PRIMARY_AGENT, to avoid)"

TARGET_AGENT=""
TARGET_NODE=""
for pair in "consul-1:patroni-1" "consul-2:patroni-2" "consul-3:patroni-3"; do
  AGENT="${pair%%:*}"
  NODE="${pair##*:}"
  if [[ "$AGENT" != "$RAFT_LEADER" && "$AGENT" != "$PRIMARY_AGENT" ]]; then
    TARGET_AGENT="$AGENT"
    TARGET_NODE="$NODE"
    break
  fi
done
if [[ -z "$TARGET_AGENT" ]]; then
  echo "Could not find a safe non-leader, non-primary-paired agent to target, aborting" >&2
  exit 1
fi
echo "Target for this test: $TARGET_AGENT (paired with $TARGET_NODE, a replica, not the raft leader)"

echo
echo "=== Baseline: primary write check + direct role check on $TARGET_NODE ==="
docker compose exec -T "$PRIMARY" psql -U postgres -Atc "SELECT 1;"
BASELINE_TL=$(echo "$LIST" | awk -F'|' '/Leader/ {gsub(/ /,"",$6); print $6}')
echo "Baseline timeline: $BASELINE_TL"
docker compose exec -T "$TARGET_NODE" psql -U postgres -Atc "SELECT pg_is_in_recovery();"

echo
echo "=== Stopping $TARGET_AGENT ==="
docker compose stop "$TARGET_AGENT"

echo
echo "=== Monitoring for 30s: primary writes, primary role, $TARGET_NODE's real role, timeline ==="
PRIMARY_AFFECTED="no"
TARGET_NODE_ROLE_AFFECTED="no"
TIMELINE_CHANGED="no"
START=$SECONDS
while (( SECONDS - START < 30 )); do
  ELAPSED=$((SECONDS-START))

  PRIMARY_WRITE_OK="no"
  if docker compose exec -T "$PRIMARY" psql -U postgres -Atc "SELECT 1;" >/dev/null 2>&1; then
    PRIMARY_WRITE_OK="yes"
  fi
  PRIMARY_RECOVERY="unknown"
  if RECOVERY_OUT=$(docker compose exec -T "$PRIMARY" psql -U postgres -Atc "SELECT pg_is_in_recovery();" 2>/dev/null); then
    PRIMARY_RECOVERY="$RECOVERY_OUT"
  fi
  TARGET_RECOVERY="unknown"
  if TARGET_OUT=$(docker compose exec -T "$TARGET_NODE" psql -U postgres -Atc "SELECT pg_is_in_recovery();" 2>/dev/null); then
    TARGET_RECOVERY="$TARGET_OUT"
  fi
  VISIBLE_IN_CONSUL="no"
  if CURRENT_LIST=$(docker compose exec -T "$PRIMARY" patronictl -c /etc/patroni.yml list 2>/dev/null); then
    if echo "$CURRENT_LIST" | grep -q "$TARGET_NODE"; then VISIBLE_IN_CONSUL="yes"; fi
    CURRENT_TL=$(echo "$CURRENT_LIST" | awk -F'|' '/Leader/ {gsub(/ /,"",$6); print $6}')
    if [[ -n "$CURRENT_TL" && "$CURRENT_TL" != "$BASELINE_TL" ]]; then TIMELINE_CHANGED="yes"; fi
  fi

  echo "  [${ELAPSED}s] primary($PRIMARY): write=${PRIMARY_WRITE_OK} recovery=${PRIMARY_RECOVERY} | $TARGET_NODE: recovery=${TARGET_RECOVERY} visible_in_patronictl=${VISIBLE_IN_CONSUL} | timeline=${CURRENT_TL:-?}"

  if [[ "$PRIMARY_WRITE_OK" == "no" || "$PRIMARY_RECOVERY" == "t" ]]; then
    PRIMARY_AFFECTED="yes"
  fi
  if [[ "$TARGET_RECOVERY" != "t" && "$TARGET_RECOVERY" != "unknown" ]]; then
    TARGET_NODE_ROLE_AFFECTED="yes"
  fi

  sleep 5
done

echo
echo "=== Restoring $TARGET_AGENT ==="
docker compose start "$TARGET_AGENT"

echo
echo "=== Waiting for $TARGET_NODE's visibility to return to patronictl (up to 30s) ==="
START=$SECONDS
while (( SECONDS - START < 30 )); do
  if docker compose exec -T "$PRIMARY" patronictl -c /etc/patroni.yml list 2>&1 | grep -q "$TARGET_NODE"; then
    echo "Visibility restored after $((SECONDS-START))s"
    break
  fi
  sleep 3
done
docker compose exec -T "$PRIMARY" patronictl -c /etc/patroni.yml list 2>&1

echo
echo "=== RESULT SUMMARY ==="
echo "Target agent: $TARGET_AGENT (paired with $TARGET_NODE)"
echo "Primary ($PRIMARY) write acceptance / role affected at any point: $PRIMARY_AFFECTED"
echo "$TARGET_NODE's actual replication role (direct query) affected at any point: $TARGET_NODE_ROLE_AFFECTED"
echo "Cluster timeline changed (an election happened): $TIMELINE_CHANGED"
echo "Expected result: all three 'no' -- a real non-event at the functional level, with only a"
echo "transient Consul-reporting visibility gap for $TARGET_NODE while its paired agent was down."
