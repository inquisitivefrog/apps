#!/usr/bin/env bash
# Redis/Sentinel HA testing per docs/redis-ha-scope.md. Stage 3 only (single-replica failure,
# expected-safe case), run as two sub-tests -- one per replica -- rather than assuming they're
# interchangeable just because their config is identical. min-replicas-to-write is a pure COUNT
# check (not identity-based), so both *should* behave the same, but this project's whole
# methodology this pass is "verify, don't assume even when it should be symmetric by config" --
# see the Kafka investigation's Run 2/Run 3 divergence for why a single clean result isn't treated
# as proof here.
#
# Per Stage 3's checklist (docs/redis-ha-scope.md), for each replica killed:
#   - Sentinel detects it but attempts no failover (nothing to fail over to/from -- primary is fine)
#   - Primary continues accepting writes throughout (min-replicas-to-write=1 still satisfied by the
#     one remaining replica)
#   - The killed replica rejoins and catches up cleanly on restart
#
# This is a TRACKING/verification script -- always exits 0 (Stage 3 failing is itself a real,
# reportable finding, not a script bug). Every run's output is saved under
# load-tests/vendor-bug-reports/redis/runs/<timestamp>-stage3/.
#
# Usage: load-tests/redis-ha-demo.sh
# Prerequisites: full stack up, redis + redis-replica-1 + redis-replica-2 + sentinel-1/2/3 healthy
# (docs/redis-ha-scope.md Stage 2). Debug-level logging already enabled per Stage 2's own checklist.
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1

RUN_TS="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="load-tests/vendor-bug-reports/redis/runs/${RUN_TS}-stage3"
mkdir -p "$RUN_DIR"
OUTFILE="${RUN_DIR}/run-transcript.txt"
exec > >(tee "$OUTFILE") 2>&1
echo "Saving this run's output to $OUTFILE"

banner() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

sentinel_master_view() {
  docker compose exec -T sentinel-1 redis-cli -p 26379 sentinel master mymaster 2>&1
}

primary_replication_info() {
  docker compose exec -T redis redis-cli INFO replication 2>&1
}

# Runs one sub-test: kill $1 (a replica service name), verify Stage 3's checklist, restore it.
run_subtest() {
  local TARGET="$1"
  local MARKER="stage3-marker-${TARGET}-$(date +%s)"

  banner "SUB-TEST: $TARGET -- baseline before kill"
  primary_replication_info | grep -E "connected_slaves|slave[0-9]|min_slaves_good"
  sentinel_master_view | grep -A1 "^flags"

  banner "SUB-TEST: $TARGET -- killing it"
  docker compose stop "$TARGET"
  sleep 6

  banner "SUB-TEST: $TARGET -- checking Sentinel did NOT attempt a failover"
  MASTER_VIEW=$(sentinel_master_view)
  echo "$MASTER_VIEW"
  MASTER_FLAGS=$(echo "$MASTER_VIEW" | grep -A1 "^flags" | tail -1)
  if [ "$MASTER_FLAGS" = "master" ]; then
    echo "OK: master still flagged plain 'master' (no failover attempted, no s_down/o_down escalation stuck)."
  else
    echo "UNEXPECTED: master flags are '$MASTER_FLAGS', not plain 'master' -- investigate before continuing."
  fi

  banner "SUB-TEST: $TARGET -- confirming primary still accepts writes with min-replicas-to-write=1"
  WRITE_RESULT=$(docker compose exec -T redis redis-cli SET "$MARKER" "written-while-$TARGET-down" 2>&1)
  echo "SET result: $WRITE_RESULT"
  primary_replication_info | grep -E "connected_slaves|slave[0-9]|min_slaves_good"

  banner "SUB-TEST: $TARGET -- restarting it, confirming clean rejoin"
  docker compose start "$TARGET"
  sleep 8
  primary_replication_info | grep -E "connected_slaves|slave[0-9]|min_slaves_good"
  REJOIN_VALUE=$(docker compose exec -T "$TARGET" redis-cli GET "$MARKER" 2>&1)
  echo "$TARGET GET $MARKER -> $REJOIN_VALUE (expect: written-while-$TARGET-down)"

  banner "SUB-TEST $TARGET -- VERDICT"
  if [ "$MASTER_FLAGS" = "master" ] && [ "$WRITE_RESULT" = "OK" ] && [ "$REJOIN_VALUE" = "written-while-$TARGET-down" ]; then
    echo "PASS: no failover attempted, primary kept accepting writes, $TARGET rejoined and caught up cleanly."
  else
    echo "FAIL or UNEXPECTED -- review the transcript above; this is a real finding, not a script bug."
  fi
}

run_subtest "redis-replica-1"
run_subtest "redis-replica-2"

banner "Both sub-tests complete"
echo "Full transcript saved to $OUTFILE"
