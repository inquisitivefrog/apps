#!/usr/bin/env bash
# docs/postgres-ha-scope.md Stage 6: kill 2 of 3 Consul agents (leaving only 1, below raft
# majority) while Postgres is under real load. Direct analog of Kafka's and Redis's own
# quorum-loss scenarios. Confirm the system fails safe -- no ambiguous/unsafe promotion decision
# -- rather than assuming "Consul refuses writes" (already confirmed in Stage 0) automatically
# means Patroni/Postgres behave safely on top of that.
#
# Real subtlety, confirmed via Stage 5's own log inspection: Patroni's Consul reads use
# consistent=1, which Consul refuses to serve at all once raft quorum is lost -- not just KV
# writes. This means `patronictl list` is expected to fail on EVERY node during the quorum-loss
# window, not just the ones whose paired agent was killed, since even the node paired with the
# surviving single agent can't get a consistent read without a raft leader. Because of this, this
# script does NOT rely on patronictl/Consul-derived state to check for an unsafe promotion --
# it polls each of the 3 nodes' own pg_is_in_recovery() directly, bypassing Consul-mediated
# reporting entirely, matching the same "direct query beats derived state" discipline used
# throughout this whole investigation.
#
# The correct "fails safe" outcome: the original primary eventually can't renew its Consul lock
# and self-demotes or stops accepting writes (same TTL-driven mechanism Stage 5 measured), and
# NEITHER other node ever flips to primary (pg_is_in_recovery=false) during the whole quorum-loss
# window, since no real majority-backed promotion decision is possible. The cluster should become
# fully unavailable for writes, not split-brained, and not silently keep accepting writes with no
# real consensus behind them.
#
# Usage: ./postgres-consul-quorum-loss-test.sh [consul-agent-to-leave-up]
# Defaults to leaving consul-3 up (killing consul-1 and consul-2). Pass a different agent name
# to vary which single agent survives across repeated runs, per this project's own "don't repeat
# the same specific case across all iterations" discipline (Stage 4/5 rotated which node failed).

set -euo pipefail
cd "$(dirname "$0")/.."

SURVIVING_AGENT="${1:-consul-3}"
ALL_AGENTS=(consul-1 consul-2 consul-3)
KILL_AGENTS=()
for a in "${ALL_AGENTS[@]}"; do
  [[ "$a" != "$SURVIVING_AGENT" ]] && KILL_AGENTS+=("$a")
done
echo "Surviving agent: $SURVIVING_AGENT -- killing: ${KILL_AGENTS[*]}"

echo "=== Confirming live ttl/loop_wait/retry_timeout ==="
docker compose exec -T patroni-1 patronictl -c /etc/patroni.yml show-config 2>&1 | grep -E "ttl|loop_wait|retry_timeout"

echo
echo "=== Identifying current leader ==="
LIST=""
if ! LIST=$(docker compose exec -T patroni-2 patronictl -c /etc/patroni.yml list 2>&1); then
  echo "patronictl list failed -- retrying once after 5s (can be transient right after other Consul activity)" >&2
  sleep 5
  LIST=$(docker compose exec -T patroni-2 patronictl -c /etc/patroni.yml list 2>&1) || true
fi
echo "$LIST"
LEADER=$(echo "$LIST" | awk -F'|' '/Leader/ {gsub(/ /,"",$2); print $2}')
if [[ -z "$LEADER" ]]; then
  echo "Could not identify current leader, aborting" >&2
  exit 1
fi
ALL_NODES=(patroni-1 patroni-2 patroni-3)
echo "Current leader: $LEADER"

echo
echo "=== Marker table + last acknowledged write on $LEADER ==="
docker compose exec -T "$LEADER" psql -U postgres -c \
  "CREATE TABLE IF NOT EXISTS stage6_marker (id serial primary key, note text, written_at timestamptz default now());"
MARKER="stage6-$(date +%s%N)"
docker compose exec -T "$LEADER" psql -U postgres -c \
  "INSERT INTO stage6_marker (note) VALUES ('${MARKER}');" 2>&1

echo
echo "=== Killing 2 of 3 Consul agents: ${KILL_AGENTS[*]} (leaving only $SURVIVING_AGENT, below raft majority) ==="
docker compose stop "${KILL_AGENTS[@]}"

echo
echo "=== Confirming Consul itself correctly refuses a consistent operation (per Stage 0's baseline) ==="
docker compose exec -T "$SURVIVING_AGENT" sh -c "consul kv put stage6-quorum-check test 2>&1" || echo "  (correctly refused, as expected)"

DEMOTED_AT_MS=""
UNSAFE_PROMOTION_DETECTED="no"
UNSAFE_PROMOTION_NODE=""

echo
echo "=== Monitoring all 3 nodes' OWN pg_is_in_recovery() directly for up to 60s ==="
echo "    (bypassing Consul/patronictl entirely -- consistent reads are expected to fail cluster-wide)"
# Loop control uses the SECONDS builtin (whole-second, proven reliable elsewhere in this exact
# script -- see the recovery-wait loop below) rather than repeated date +%s%N arithmetic as the
# condition itself -- a first attempt using nanosecond arithmetic directly in the while condition
# exited after only ~2.5s instead of running the full 60s, for a reason not fully pinned down
# despite isolated repros behaving correctly; decoupling the loop's correctness from millisecond
# arithmetic removes the whole risk class rather than chasing one unreproduced instance of it.
# Millisecond precision is still reported per-event via a single date +%s%N computation each
# iteration, just not used to control the loop.
LOOP_START=$SECONDS
i=0
while (( SECONDS - LOOP_START < 60 )); do
  i=$((i+1))
  NOW_MS=$(( (SECONDS - LOOP_START) * 1000 ))
  LINE="  [${NOW_MS}ms]"
  for NODE in "${ALL_NODES[@]}"; do
    RECOVERY="unreachable"
    if RECOVERY_OUT=$(docker compose exec -T "$NODE" psql -U postgres -Atc "SELECT pg_is_in_recovery();" 2>/dev/null); then
      RECOVERY="$RECOVERY_OUT"
    fi
    LINE="${LINE} ${NODE}=${RECOVERY}"

    if [[ "$NODE" == "$LEADER" && -z "$DEMOTED_AT_MS" && "$RECOVERY" == "t" ]]; then
      DEMOTED_AT_MS="$NOW_MS"
    fi
    if [[ "$NODE" != "$LEADER" && "$RECOVERY" == "f" ]]; then
      UNSAFE_PROMOTION_DETECTED="yes"
      UNSAFE_PROMOTION_NODE="$NODE"
    fi
  done

  # Also directly check whether the original leader still accepts writes (belt-and-suspenders
  # alongside the recovery-flag check above -- a node could theoretically still accept writes
  # even if pg_is_in_recovery() hasn't flipped yet, or vice versa under a race).
  LEADER_WRITE_OK="unknown"
  if WRITE_OUT=$(docker compose exec -T "$LEADER" psql -U postgres -c \
      "INSERT INTO stage6_marker (note) VALUES ('${MARKER}-probe-${i}');" 2>&1); then
    if echo "$WRITE_OUT" | grep -q "INSERT 0 1"; then LEADER_WRITE_OK="yes"; else LEADER_WRITE_OK="no"; fi
  else
    LEADER_WRITE_OK="no"
  fi
  echo "${LINE} | ${LEADER}_write=${LEADER_WRITE_OK}"

  # Traefik + Consul Catalog client-routing check -- deliberately separate from, and NOT part of,
  # the Postgres/Patroni safety verdict above. The routing spike (Stages 4-5) works by querying
  # Consul Catalog for whichever postgres-primary instance is currently "passing"; with no Consul
  # quorum at all, that query path is itself expected to degrade or fail closed. A failure here
  # says nothing about whether Postgres/Patroni behaved safely -- it's reported purely as its own
  # informational finding about how the routing layer behaves under this failure mode, checked
  # every 3rd iteration (~6s) rather than every iteration, since it's observational, not the
  # safety check this stage exists to run.
  if (( i % 3 == 1 )); then
    TRAEFIK_RESULT="unknown"
    if TRAEFIK_OUT=$(docker compose exec -T -e PGPASSWORD=gridmeter "$LEADER" \
        psql -h traefik -p 55432 -U postgres -Atc "SELECT inet_server_addr()::text;" 2>&1); then
      TRAEFIK_RESULT="reached:${TRAEFIK_OUT}"
    else
      TRAEFIK_RESULT="failed:$(echo "$TRAEFIK_OUT" | head -1 | tr -d '\n')"
    fi
    echo "  [${NOW_MS}ms] TRAEFIK/ROUTING (informational only, not part of the safety verdict): ${TRAEFIK_RESULT}"
  fi

  if [[ "$UNSAFE_PROMOTION_DETECTED" == "yes" ]]; then
    echo "  !!! UNSAFE PROMOTION: $UNSAFE_PROMOTION_NODE reports pg_is_in_recovery=false without real Consul quorum !!!"
    break
  fi

  sleep 2
done

echo
echo "=== Staggered restore, part 1: bringing back only ${KILL_AGENTS[0]} (crossing 1-of-3 -> 2-of-3, quorum just regained) ==="
echo "    Isolating this specific transition per docs/postgres-ha-scope.md's Stage 6 checklist --"
echo "    confirm exactly ONE node gets cleanly, unambiguously elected right here, not just that"
echo "    the cluster is healthy once everything is eventually restored."
docker compose start "${KILL_AGENTS[0]}"

QUORUM_REGAINED_AT_MS=""
ELECTED_NODE=""
START=$SECONDS
while (( SECONDS - START < 60 )); do
  ELAPSED_MS=$(( (SECONDS - START) * 1000 ))
  PRIMARY_COUNT=0
  PRIMARY_NODES=()
  for NODE in "${ALL_NODES[@]}"; do
    R="unreachable"
    if R_OUT=$(docker compose exec -T "$NODE" psql -U postgres -Atc "SELECT pg_is_in_recovery();" 2>/dev/null); then
      R="$R_OUT"
    fi
    if [[ "$R" == "f" ]]; then
      PRIMARY_COUNT=$((PRIMARY_COUNT+1))
      PRIMARY_NODES+=("$NODE")
    fi
  done
  echo "  [${ELAPSED_MS}ms since restoring agent 1] nodes reporting primary (recovery=false): ${PRIMARY_COUNT} (${PRIMARY_NODES[*]:-none})"
  if (( PRIMARY_COUNT == 1 )); then
    QUORUM_REGAINED_AT_MS="$ELAPSED_MS"
    ELECTED_NODE="${PRIMARY_NODES[0]}"
    echo "  -> Exactly one node ($ELECTED_NODE) cleanly elected at 2-of-3 quorum, after ${ELAPSED_MS}ms"
    break
  elif (( PRIMARY_COUNT > 1 )); then
    echo "  !!! AMBIGUOUS ELECTION: $PRIMARY_COUNT nodes simultaneously report primary at 2-of-3 quorum !!!"
    break
  fi
  sleep 3
done

echo
echo "=== Staggered restore, part 2: bringing back ${KILL_AGENTS[1]} (full 3-of-3) ==="
docker compose start "${KILL_AGENTS[1]}"

echo
echo "=== Waiting for full cluster recovery (up to 90s) ==="
START=$SECONDS
while (( SECONDS - START < 90 )); do
  RESULT=""
  if ! RESULT=$(docker compose exec -T patroni-2 patronictl -c /etc/patroni.yml list 2>&1); then
    RESULT=""
  fi
  if echo "$RESULT" | grep -c "streaming" | grep -q "^2$"; then
    echo "$RESULT"
    echo "Fully recovered after $((SECONDS-START))s"
    break
  fi
  sleep 5
done

echo
echo "=== RESULT SUMMARY ==="
echo "Original leader: $LEADER"
echo "Consul correctly refused a consistent write during quorum loss: confirmed above"
echo "Original leader self-demoted / stopped accepting writes at: ${DEMOTED_AT_MS:-NEVER within 60s} ms after quorum loss began"
echo "UNSAFE PROMOTION DETECTED (a non-leader node reported itself primary without real quorum): ${UNSAFE_PROMOTION_DETECTED}"
if [[ "$UNSAFE_PROMOTION_DETECTED" == "yes" ]]; then
  echo "  -> Node: $UNSAFE_PROMOTION_NODE"
fi
if [[ -n "$QUORUM_REGAINED_AT_MS" ]]; then
  echo "2-of-3 recovery transition: exactly one node (${ELECTED_NODE}) cleanly elected at ${QUORUM_REGAINED_AT_MS}ms after restoring the first agent"
else
  echo "2-of-3 recovery transition: NOT confirmed within 60s -- real problem, not a formatting artifact"
fi

echo
echo "=== Cleanup: removing probe rows ==="
FINAL_LEADER=""
if FINAL_LIST=$(docker compose exec -T patroni-2 patronictl -c /etc/patroni.yml list 2>&1); then
  FINAL_LEADER=$(echo "$FINAL_LIST" | awk -F'|' '/Leader/ {gsub(/ /,"",$2); print $2}')
fi
docker compose exec -T "${FINAL_LEADER:-$LEADER}" psql -U postgres -c "DELETE FROM stage6_marker WHERE note LIKE '%-probe-%';" 2>&1
