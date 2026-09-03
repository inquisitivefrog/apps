#!/usr/bin/env bash
# docs/postgres-ha-scope.md Stage 5, Sub-scenario A: partition the CURRENT PRIMARY from its own
# Consul agent specifically -- Postgres itself keeps running and accepting client connections the
# entire time, nothing is killed or restarted. This is deliberately different from Stage 4 (which
# tested a node that actually died and restarted, measuring its local self-demotion in ~310-345ms).
# This sub-scenario tests the doc's actually-named worst case: a primary that is NEVER dead, just
# cut off from consensus, exposed for up to the live `ttl` value (confirmed 30s) rather than
# Stage 4's sub-second window.
#
# Mechanism: append a blackhole entry to the primary's own /etc/hosts, redirecting its configured
# Consul hostname to an unroutable IP (10.255.255.1) -- verified via a dry run on a non-leader node
# to produce a real connection timeout (not an instant refusal) while leaving the container's own
# listening ports (5432 Postgres, 8008 Patroni REST) completely untouched. Removal uses a
# truncate-and-rewrite (python3, open(...,'w')) rather than `sed -i`, since /etc/hosts is a
# bind-mounted file and sed's rename-based in-place edit fails on it ("Device or resource busy").
#
# CRITICAL, found the hard way on the first real attempt: the /etc/hosts blackhole ALONE has no
# effect on Patroni's already-open, pooled HTTP connection to Consul (urllib3 reuses an existing
# TCP socket without re-resolving DNS) -- a first run left the blackhole in place for a full 60s
# with zero reaction from Patroni, which looked like (but was not) a real absence of self-
# protection. Confirmed via direct log inspection: Patroni kept successfully renewing its Consul
# session over the stale connection the entire time. The blackhole only takes effect once the
# EXISTING connection is actually forced closed -- this script also restarts the target Consul
# agent immediately after applying the blackhole, which closes Patroni's live socket and forces
# its next request to attempt a genuinely new connection, which the blackhole then correctly
# blocks. Restarting one of three Consul agents doesn't threaten Consul's own quorum (the other
# two remain untouched, matching Stage 0's own validated non-disruptive-agent-restart baseline),
# so this stays a surgical test of the primary-to-Consul path specifically, not a broader partition.
#
# Tracks two independent timers and reports the gap, if any:
#   - When does the PARTITIONED primary itself self-demote (pg_is_in_recovery() flips true, or it
#     starts rejecting writes) -- driven by its own retry_timeout/loop_wait noticing it can't
#     confirm its lock, not by loss of TTL directly.
#   - When does a WITNESS node (unaffected) observe a NEW leader promoted -- driven by the lock's
#     TTL actually expiring from Consul's perspective.
# If the new leader is promoted BEFORE the old primary self-demotes, that gap is a real,
# measured split-brain window -- during it, this script attempts writes against BOTH nodes to
# confirm whether both actually accept writes simultaneously, not just that the window exists.
#
# Usage: ./postgres-consul-partition-test.sh

set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== Confirming live ttl/loop_wait/retry_timeout (per this stage's own prerequisite) ==="
# Dynamic query target for REACHING a node, not hardcoded -- same "monitoring helper's own
# hardcoded query target" mistake already found and fixed elsewhere in this project. Deliberately
# keeps the grep itself fatal if a successfully-reached node's config is missing these settings --
# that's a real config problem worth stopping over, not something to paper over by trying another
# node, so only the "which node do we ask" step gets the retry/fallthrough treatment.
CONFIG=""
for NODE in patroni-1 patroni-2 patroni-3; do
  if CONFIG=$(docker compose exec -T "$NODE" patronictl -c /etc/patroni.yml show-config 2>/dev/null); then
    break
  fi
  CONFIG=""
done
if [[ -z "$CONFIG" ]]; then
  echo "Could not reach any Patroni node to confirm live ttl/loop_wait/retry_timeout, aborting" >&2
  exit 1
fi
echo "$CONFIG" | grep -E "ttl|loop_wait|retry_timeout"

echo
echo "=== Identifying current leader and its paired Consul agent ==="
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
  echo "Could not reach any Patroni node to identify the current leader, aborting" >&2
  exit 1
fi
echo "$LIST"
LEADER=$(echo "$LIST" | awk -F'|' '/Leader/ {gsub(/ /,"",$2); print $2}')
if [[ -z "$LEADER" ]]; then
  echo "Could not identify current leader, aborting" >&2
  exit 1
fi
case "$LEADER" in
  patroni-1) CONSUL_AGENT=consul-1; WITNESS=patroni-2 ;;
  patroni-2) CONSUL_AGENT=consul-2; WITNESS=patroni-1 ;;
  patroni-3) CONSUL_AGENT=consul-3; WITNESS=patroni-1 ;;
esac
echo "Current leader: $LEADER (paired with $CONSUL_AGENT), witness: $WITNESS"

echo
echo "=== Marker table + baseline write on $LEADER before partitioning ==="
docker compose exec -T "$LEADER" psql -U postgres -c \
  "CREATE TABLE IF NOT EXISTS stage5_marker (id serial primary key, note text, written_at timestamptz default now());"
MARKER="stage5a-$(date +%s%N)"
docker compose exec -T "$LEADER" psql -U postgres -c \
  "INSERT INTO stage5_marker (note) VALUES ('${MARKER}-baseline');" 2>&1

echo
echo "=== Applying the blackhole: $LEADER can no longer resolve $CONSUL_AGENT ==="
docker compose exec -T -u root "$LEADER" sh -c "echo '10.255.255.1 ${CONSUL_AGENT}' >> /etc/hosts"
docker compose exec -T "$LEADER" tail -1 /etc/hosts

echo
echo "=== Restarting $CONSUL_AGENT to force $LEADER's existing pooled connection closed ==="
echo "    (the blackhole alone does nothing to an already-open connection -- confirmed the hard"
echo "    way; this restart is what actually makes the partition real from Patroni's perspective)"
docker compose restart "$CONSUL_AGENT"
T0=$(date +%s%N)

DEMOTED_AT_MS=""
NEW_LEADER=""
NEW_LEADER_AT_MS=""
SPLIT_BRAIN_DETECTED="no"

echo
echo "=== Monitoring both timers for up to 60s (ttl=30s expected ceiling) ==="
i=0
while (( $(( $(date +%s%N) - T0 )) / 1000000 < 60000 )); do
  i=$((i+1))
  NOW_MS=$(( ($(date +%s%N) - T0) / 1000000 ))

  # Check 1: has the partitioned primary itself self-demoted or started rejecting writes?
  if [[ -z "$DEMOTED_AT_MS" ]]; then
    RECOVERY="unknown"
    if RECOVERY_OUT=$(docker compose exec -T "$LEADER" psql -U postgres -Atc "SELECT pg_is_in_recovery();" 2>/dev/null); then
      RECOVERY="$RECOVERY_OUT"
    fi
    WRITE_OK="unknown"
    if WRITE_OUT=$(docker compose exec -T "$LEADER" psql -U postgres -c \
        "INSERT INTO stage5_marker (note) VALUES ('${MARKER}-primary-probe-${i}');" 2>&1); then
      if echo "$WRITE_OUT" | grep -q "INSERT 0 1"; then WRITE_OK="yes"; else WRITE_OK="no"; fi
    else
      WRITE_OK="no"
    fi
    echo "  [${NOW_MS}ms] $LEADER (partitioned): pg_is_in_recovery=${RECOVERY} write=${WRITE_OK}"
    if [[ "$RECOVERY" == "t" || "$WRITE_OK" == "no" ]]; then
      DEMOTED_AT_MS="$NOW_MS"
      echo "  -> $LEADER stopped accepting writes / reports non-primary at ${NOW_MS}ms"
    fi
  fi

  # Check 2: has a witness node observed a NEW leader?
  if [[ -z "$NEW_LEADER" ]]; then
    if LIST2=$(docker compose exec -T "$WITNESS" patronictl -c /etc/patroni.yml list 2>/dev/null); then
      CANDIDATE=$(echo "$LIST2" | awk -F'|' -v old="$LEADER" '/Leader/ {gsub(/ /,"",$2); if ($2 != old) print $2}')
      if [[ -n "$CANDIDATE" ]]; then
        NEW_LEADER="$CANDIDATE"
        NEW_LEADER_AT_MS="$NOW_MS"
        echo "  -> Witness observes NEW leader ($NEW_LEADER) at ${NOW_MS}ms"
      fi
    fi
  fi

  # The actual split-brain check: if a new leader exists AND the old one hasn't self-demoted yet,
  # try a write against the NEW leader too, right now, to see if both genuinely accept writes
  # concurrently -- not just that the window exists in principle.
  if [[ -n "$NEW_LEADER" && -z "$DEMOTED_AT_MS" ]]; then
    if NEW_WRITE_OUT=$(docker compose exec -T "$NEW_LEADER" psql -U postgres -c \
        "INSERT INTO stage5_marker (note) VALUES ('${MARKER}-newleader-probe-${i}');" 2>&1); then
      if echo "$NEW_WRITE_OUT" | grep -q "INSERT 0 1"; then
        echo "  !!! SPLIT-BRAIN: write succeeded on NEW leader ($NEW_LEADER) while $LEADER had not yet self-demoted !!!"
        SPLIT_BRAIN_DETECTED="yes"
      fi
    fi
  fi

  if [[ -n "$DEMOTED_AT_MS" && -n "$NEW_LEADER" ]]; then
    echo "  Both timers resolved -- stopping monitoring loop."
    break
  fi

  sleep 1
done

echo
echo "=== Removing the blackhole from $LEADER ==="
docker compose exec -T -u root "$LEADER" python3 -c "
with open('/etc/hosts') as f:
    lines = [l for l in f if '10.255.255.1 ${CONSUL_AGENT}' not in l]
with open('/etc/hosts', 'w') as f:
    f.writelines(lines)
"
docker compose exec -T "$LEADER" tail -3 /etc/hosts

echo
echo "=== Waiting for full cluster recovery (up to 60s) ==="
START=$SECONDS
while (( SECONDS - START < 60 )); do
  RESULT=$(docker compose exec -T "$WITNESS" patronictl -c /etc/patroni.yml list 2>&1)
  if echo "$RESULT" | grep -c "streaming" | grep -q "^2$"; then
    echo "$RESULT"
    echo "Fully recovered after $((SECONDS-START))s"
    break
  fi
  sleep 3
done

echo
echo "=== RESULT SUMMARY ==="
echo "Partitioned primary: $LEADER (paired with $CONSUL_AGENT)"
echo "Old primary self-demoted / stopped accepting writes at: ${DEMOTED_AT_MS:-NEVER within 60s} ms after partition start"
echo "New leader ($NEW_LEADER) observed by witness at: ${NEW_LEADER_AT_MS:-NEVER within 60s} ms after partition start"
if [[ -n "$DEMOTED_AT_MS" && -n "$NEW_LEADER_AT_MS" ]]; then
  GAP=$(( NEW_LEADER_AT_MS - DEMOTED_AT_MS ))
  echo "Gap (new-leader-time minus old-primary-demotion-time): ${GAP}ms (negative = new leader appeared BEFORE old primary demoted -- a real window)"
fi
echo "SPLIT-BRAIN DETECTED (a write actually succeeded on both nodes concurrently): ${SPLIT_BRAIN_DETECTED}"

echo
echo "=== Cleanup: removing probe rows, keeping only the baseline marker ==="
CURRENT_LEADER_FOR_CLEANUP=$(docker compose exec -T "$WITNESS" patronictl -c /etc/patroni.yml list 2>&1 | awk -F'|' '/Leader/ {gsub(/ /,"",$2); print $2}')
docker compose exec -T "${CURRENT_LEADER_FOR_CLEANUP:-$WITNESS}" psql -U postgres -c "DELETE FROM stage5_marker WHERE note LIKE '%-probe-%';" 2>&1
