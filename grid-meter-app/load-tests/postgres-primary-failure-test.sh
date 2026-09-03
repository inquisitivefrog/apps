#!/usr/bin/env bash
# docs/postgres-ha-scope.md Stage 4: kill the primary under real write load. Measures:
#   1. Real promotion RTO (not the configured ceiling)
#   2. Whether the promoted primary has the last acknowledged write (direct query, not inferred)
#   3. The split-brain window when the old primary rejoins -- probed via direct writes against
#      that SPECIFIC node's own Postgres port at high frequency from the instant it restarts,
#      bypassing Traefik/Consul routing entirely, so a brief writable window (if one exists) is
#      actually caught rather than averaged away by a coarser poll interval. This is the specific
#      measurement docs/postgres-ha-scope.md's "Fencing decision" conditional risk-acceptance
#      depends on -- rely on Patroni's built-in self-demotion, verified here rather than assumed.
#
# Dynamically detects the current leader (don't assume patroni-1 -- this script is meant to be
# run more than once in a row, per the doc's own "don't trust a single clean run" instruction,
# and roles rotate between runs).
#
# Polls for actual readiness conditions throughout, never a fixed sleep, per this project's
# standing test-infrastructure discipline (docs/testing-strategy.md).
#
# Usage: ./postgres-primary-failure-test.sh

set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== Identifying current leader ==="
# The query TARGET itself must also be dynamic, not just the leader value read from its output --
# a fixed query target would fail this whole check for a reason unrelated to the actual scenario
# under test (e.g. that one node left stopped by an earlier run). Same "monitoring helper's own
# hardcoded query target" mistake already found and fixed elsewhere in this project (Kafka's
# cluster_state(), postgres-app-primary-failure-test.sh's own leader-identification check) --
# tries each known node in turn until one actually answers.
LIST=""
for NODE in patroni-1 patroni-2 patroni-3; do
  if LIST=$(docker compose exec -T "$NODE" patronictl -c /etc/patroni.yml list 2>/dev/null); then
    break
  fi
  LIST=""
done
if [[ -z "$LIST" ]]; then
  echo "Could not reach any Patroni node to identify the current leader, aborting" >&2
  exit 1
fi
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
echo "Witness node for patronictl (stays up throughout): $WITNESS"

echo
echo "=== Marker table + the last acknowledged write, sent immediately before killing $LEADER ==="
docker compose exec -T "$LEADER" psql -U postgres -c \
  "CREATE TABLE IF NOT EXISTS stage4_marker (id serial primary key, note text, written_at timestamptz default now());"
MARKER="stage4-$(date +%s%N)"
docker compose exec -T "$LEADER" psql -U postgres -c \
  "INSERT INTO stage4_marker (note) VALUES ('${MARKER}') RETURNING id, note, written_at;" 2>&1

echo
echo "=== Killing $LEADER ==="
T0=$(date +%s%N)
docker compose stop "$LEADER"

echo
echo "=== Polling for a new leader (up to 60s) ==="
NEW_LEADER=""
START=$SECONDS
while (( SECONDS - START < 60 )); do
  LIST2=$(docker compose exec -T "$WITNESS" patronictl -c /etc/patroni.yml list 2>&1)
  CANDIDATE=$(echo "$LIST2" | awk -F'|' -v old="$LEADER" '/Leader/ {gsub(/ /,"",$2); if ($2 != old) print $2}')
  if [[ -n "$CANDIDATE" ]]; then
    T1=$(date +%s%N)
    NEW_LEADER="$CANDIDATE"
    echo "  New leader: $NEW_LEADER -- RTO: $(( (T1-T0) / 1000000 ))ms"
    break
  fi
  sleep 0.5
done
if [[ -z "$NEW_LEADER" ]]; then
  echo "!!! No new leader elected within 60s -- real failure, not a timing artifact" >&2
  exit 1
fi

echo
echo "=== Confirming the promoted primary ($NEW_LEADER) has the last acknowledged write ==="
docker compose exec -T "$NEW_LEADER" psql -U postgres -c \
  "SELECT * FROM stage4_marker WHERE note = '${MARKER}';" 2>&1

echo
echo "=== Client-observed failover check: does the real routing path (Traefik :55432, Consul"
echo "    Catalog health-check-based, per the routing spike) actually reach the NEW primary?"
echo "    Retries for up to 20s -- Traefik/Consul's own health-check propagation is real, bounded"
echo "    latency, not something to fail the whole test on a single early attempt. ==="
NEW_LEADER_IP=$(docker compose exec -T "$NEW_LEADER" hostname -i 2>&1 | tr -d '\r\n ')
CLIENT_PATH_NODE=""
CLIENT_START=$SECONDS
while (( SECONDS - CLIENT_START < 20 )); do
  if ATTEMPT=$(docker compose exec -T -e PGPASSWORD=gridmeter "$WITNESS" \
    psql -h traefik -p 55432 -U postgres -Atc "SELECT inet_server_addr()::text;" 2>&1); then
    :
  fi
  # inet_server_addr()::text returns CIDR notation (e.g. "172.18.0.21/32"), not a bare IP --
  # strip any /NN suffix before comparing, or the very fix would falsely report a mismatch.
  ATTEMPT_IP="${ATTEMPT%%/*}"
  echo "  [$((SECONDS-CLIENT_START))s] attempt: $ATTEMPT"
  if [[ "$ATTEMPT_IP" == "$NEW_LEADER_IP" ]]; then
    CLIENT_PATH_NODE="$ATTEMPT_IP"
    break
  fi
  sleep 2
done
echo "  Traefik routed the client to: ${CLIENT_PATH_NODE:-<never resolved within 20s>}"
echo "  New leader's real IP:         $NEW_LEADER_IP"
if [[ "$CLIENT_PATH_NODE" == "$NEW_LEADER_IP" ]]; then
  echo "  -> MATCH: the real client-facing routing path correctly follows the failover"
else
  echo "  -> MISMATCH or unresolved: client routing did NOT confirm following the failover within 20s -- real finding, not assumed fine"
fi

echo
echo "=== Restoring $LEADER and probing for a split-brain window ==="
docker compose start "$LEADER"

echo "Probing $LEADER directly (bypassing Traefik/routing entirely) every ~200ms..."
T2=$(date +%s%N)
SPLIT_BRAIN_DETECTED="no"
DEMOTED_AT_MS=""
for i in $(seq 1 150); do
  NOW=$(date +%s%N)
  ELAPSED_MS=$(( (NOW - T2) / 1000000 ))
  RECOVERY="unreachable"
  if RECOVERY_OUT=$(docker compose exec -T "$LEADER" psql -U postgres -Atc "SELECT pg_is_in_recovery();" 2>/dev/null); then
    RECOVERY="$RECOVERY_OUT"
  fi
  if [[ "$RECOVERY" == "unreachable" || -z "$RECOVERY" ]]; then
    echo "  [${ELAPSED_MS}ms] not yet reachable"
  else
    WROTE="write-rejected"
    if WRITE_OUTPUT=$(docker compose exec -T "$LEADER" psql -U postgres -c \
      "INSERT INTO stage4_marker (note) VALUES ('splitbrain-probe-${i}');" 2>&1); then
      if echo "$WRITE_OUTPUT" | grep -q "INSERT 0 1"; then
        WROTE="write-succeeded"
        if [[ "$RECOVERY" == "f" ]]; then
          SPLIT_BRAIN_DETECTED="yes"
        fi
      fi
    fi
    echo "  [${ELAPSED_MS}ms] pg_is_in_recovery=${RECOVERY} write=${WROTE}"
    if [[ "$RECOVERY" == "t" ]]; then
      DEMOTED_AT_MS="$ELAPSED_MS"
      echo "  -> $LEADER correctly reports itself as a replica after ${ELAPSED_MS}ms"
      break
    fi
  fi
  sleep 0.2
done

echo
echo "=== RESULT SUMMARY ==="
echo "Old leader: $LEADER -> New leader: $NEW_LEADER"
echo "Old leader correctly demoted (pg_is_in_recovery=true) at: ${DEMOTED_AT_MS:-NEVER within the probe window -- real problem}ms after restart"
echo "SPLIT-BRAIN DETECTED (a write succeeded while $LEADER still reported itself as primary post-restart): ${SPLIT_BRAIN_DETECTED}"

echo
echo "=== Final cluster state ==="
docker compose exec -T "$WITNESS" patronictl -c /etc/patroni.yml list 2>&1

echo
echo "=== Cleanup: dropping any duplicate/conflicting rows from the split-brain probe loop ==="
docker compose exec -T "$NEW_LEADER" psql -U postgres -c "DELETE FROM stage4_marker WHERE note LIKE 'splitbrain-probe-%';" 2>&1
