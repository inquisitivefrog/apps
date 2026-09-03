#!/usr/bin/env bash
# Redis/Sentinel Stage 4 per docs/redis-ha-scope.md: primary failure, the real test. Kills whichever
# node is CURRENTLY master (found dynamically via `redis-cli ROLE`, not hardcoded as "redis" --
# after a real failover a replica becomes master, and re-running this script must operate against
# the actual live topology, not an assumption). Resets to the canonical topology (redis=primary)
# via --force-recreate at the start of every run, so each invocation starts from the same known
# state and "run this more than once" (the doc's own instruction, echoing the Kafka investigation's
# central lesson) is simply "run this script again."
#
# Checks, per the doc's Stage 4 checklist -- explicitly, not assumed:
#   - Did Sentinel actually promote a replica? (found via ROLE polling, not Sentinel's own status)
#   - Does the promoted node have the last acknowledged write -- direct GET, not inferred
#   - Real measured RTO (kill-to-promotion), not the configured down-after-milliseconds ceiling
#   - Does min-replicas-to-write survive the promotion? (hypothesis: NO -- only the original
#     `redis` service's docker-compose command declared it; Sentinel's promotion mechanism
#     (REPLICAOF NO ONE) does not carry arbitrary CONFIG SET values with it)
#   - Split-brain check: does the restarted old primary have any window where it still answers as
#     master and accepts a write, before Sentinel reconciles it into a replica?
#
# This is a TRACKING/verification script -- always exits 0. A failed check (no promotion, lost
# write, config not surviving, a real split-brain window) is itself the reportable finding, not a
# script bug. Every run's output is saved under
# load-tests/vendor-bug-reports/redis/runs/<timestamp>-stage4/.
#
# Usage: load-tests/redis-primary-failover-rto.sh
# Prerequisites: full stack up, Stage 2/3 topology already built.
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1

RUN_TS="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="load-tests/vendor-bug-reports/redis/runs/${RUN_TS}-stage4"
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

DATA_SVCS="redis redis-replica-1 redis-replica-2"

find_master_service() {
  for svc in $DATA_SVCS; do
    if docker compose ps --status running --format '{{.Service}}' | grep -qx "$svc"; then
      ROLE=$(docker compose exec -T "$svc" redis-cli ROLE 2>/dev/null | head -1)
      if [ "$ROLE" = "master" ]; then
        echo "$svc"
        return 0
      fi
    fi
  done
  return 1
}

banner "Resetting to canonical topology before this run (redis=primary, replicas replicate from it)"
docker compose up -d --force-recreate redis redis-replica-1 redis-replica-2 sentinel-1 sentinel-2 sentinel-3

banner "Actively waiting for Sentinel to discover BOTH replicas before proceeding (root cause of"
echo "Finding B: a fixed sleep here raced Sentinel's own replica-discovery poll -- confirmed"
echo "empirically that discovery normally completes in ~4s but is not reliably bounded by any fixed"
echo "sleep duration under contention, so this polls for the actual condition instead of guessing"
echo "a longer number)."
DISCOVERED=0
for i in $(seq 1 30); do
  # Dynamic query target -- this script's own force-recreate above brings up all 3 Sentinels
  # fresh, but doesn't guarantee sentinel-1 specifically is the first one ready; a hardcoded
  # target here would also still fail for an unrelated reason if it were left down by an earlier,
  # unrelated test run.
  POLL_SENTINEL=""
  for svc in sentinel-1 sentinel-2 sentinel-3; do
    if docker compose exec -T "$svc" redis-cli -p 26379 ping >/dev/null 2>&1; then
      POLL_SENTINEL="$svc"
      break
    fi
  done
  # A plain `&&`/`||` chain around this pipe was tried first and was itself a real, live-caught
  # bug: `grep -c` exits non-zero on a legitimate zero-match count (this project's own standing
  # "grep -c" lesson, docs/cross-project-lessons.md), which made the `||` fallback ALSO fire and
  # print "0" -- producing a two-line "0\n0" value that broke the numeric comparison below. A
  # plain if/else avoids the trap entirely by never treating grep -c's own exit status as
  # meaningful here.
  if [ -n "$POLL_SENTINEL" ]; then
    KNOWN_REPLICAS=$(docker compose exec -T "$POLL_SENTINEL" redis-cli -p 26379 sentinel replicas mymaster 2>/dev/null | grep -c "^ip$")
  else
    KNOWN_REPLICAS=0
  fi
  echo "t+${i}s: ${POLL_SENTINEL:-no reachable sentinel} knows about $KNOWN_REPLICAS replica(s)"
  if [ "$KNOWN_REPLICAS" -ge 2 ]; then
    DISCOVERED=1
    echo "Both replicas discovered at t+${i}s -- safe to proceed"
    break
  fi
  sleep 1
done
if [ "$DISCOVERED" -eq 0 ]; then
  echo "Sentinel still doesn't know about both replicas after 30s -- aborting this run (a setup"
  echo "problem, not a Stage 4 finding; re-run once the stack settles)."
  exit 0
fi

banner "Also waiting for the PRIMARY ITSELF to consider both replicas 'good' for min-replicas-to-write"
echo "A second, related race found while fixing the first: Sentinel discovering a replica (via"
echo "polling INFO) is a different readiness signal than the PRIMARY's own min-replicas-to-write"
echo "gate considering that replica synced/ack'd within min-replicas-max-lag. Confirmed empirically"
echo "-- a marker write attempted right after Sentinel's discovery alone returned NOREPLICAS."
GOOD_SLAVES_READY=0
for i in $(seq 1 15); do
  GOOD_SLAVES=$(docker compose exec -T redis redis-cli INFO replication 2>/dev/null | grep "min_slaves_good_slaves" | tr -d '\r' | cut -d: -f2)
  echo "t+${i}s: primary reports min_slaves_good_slaves=$GOOD_SLAVES"
  if [ "${GOOD_SLAVES:-0}" -ge 1 ]; then
    GOOD_SLAVES_READY=1
    echo "Primary considers replicas good at t+${i}s -- safe to write"
    break
  fi
  sleep 1
done
if [ "$GOOD_SLAVES_READY" -eq 0 ]; then
  echo "Primary still doesn't consider any replica 'good' after 15s -- aborting this run (a setup"
  echo "problem, not a Stage 4 finding; re-run once the stack settles)."
  exit 0
fi

CURRENT_MASTER=$(find_master_service)
echo "Current master service: ${CURRENT_MASTER:-NONE FOUND}"
if [ "$CURRENT_MASTER" != "redis" ]; then
  echo "Reset did not converge on 'redis' as master within the wait -- aborting this run (a setup"
  echo "problem, not a Stage 4 finding). Re-run once the stack settles."
  exit 0
fi

MARKER="stage4-marker-$(date +%s)"
MARKER_EXPECTED="primary-failure-test-value"
banner "Writing marker to primary ($CURRENT_MASTER) BEFORE killing it, confirming acknowledgment"
SET_RESULT=$(docker compose exec -T "$CURRENT_MASTER" redis-cli SET "$MARKER" "$MARKER_EXPECTED" 2>&1)
echo "SET result: $SET_RESULT"
if [ "$SET_RESULT" != "OK" ]; then
  echo "Write was not acknowledged -- aborting this run, nothing to test against."
  exit 0
fi

banner "Confirming the marker is present on BOTH replicas via direct GET before killing anything"
PRE_KILL_OK="yes"
for svc in redis-replica-1 redis-replica-2; do
  for attempt in 1 2 3; do
    VAL=$(docker compose exec -T "$svc" redis-cli GET "$MARKER" 2>&1)
    if [ "$VAL" = "$MARKER_EXPECTED" ]; then
      echo "$svc GET $MARKER -> $VAL (confirmed, attempt $attempt)"
      break
    fi
    sleep 0.3
  done
  if [ "$VAL" != "$MARKER_EXPECTED" ]; then
    echo "$svc GET $MARKER -> $VAL (NOT propagated after 3 attempts -- real finding on its own)"
    PRE_KILL_OK="no"
  fi
done
if [ "$PRE_KILL_OK" = "no" ]; then
  echo "Marker did not propagate to both replicas before the kill -- this is itself worth reporting,"
  echo "but continuing the test anyway since the primary is still healthy and the kill is the point."
fi

KILL_EPOCH=$(date +%s)
KILL_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
banner "Killing the primary ($CURRENT_MASTER) at epoch $KILL_EPOCH"
docker compose stop "$CURRENT_MASTER"

banner "Polling up to 30s for a surviving replica to become master"
NEW_MASTER=""
for i in $(seq 1 30); do
  for svc in redis-replica-1 redis-replica-2; do
    if docker compose ps --status running --format '{{.Service}}' | grep -qx "$svc"; then
      ROLE=$(docker compose exec -T "$svc" redis-cli ROLE 2>/dev/null | head -1)
      if [ "$ROLE" = "master" ]; then
        NEW_MASTER="$svc"
        break 2
      fi
    fi
  done
  sleep 1
done
PROMOTION_EPOCH=$(date +%s)
RTO=$((PROMOTION_EPOCH - KILL_EPOCH))

MARKER_VALUE=""
if [ -z "$NEW_MASTER" ]; then
  banner "VERDICT: NO PROMOTION DETECTED within 30s -- this is itself a real, reportable finding"
else
  banner "Promotion detected: $NEW_MASTER is now master. Measured RTO ~= ${RTO}s (kill-to-promotion, 1s polling granularity)"

  banner "Checking $NEW_MASTER actually has the marker write (direct GET, not inferred)"
  MARKER_VALUE=$(docker compose exec -T "$NEW_MASTER" redis-cli GET "$MARKER" 2>&1)
  echo "$NEW_MASTER GET $MARKER -> $MARKER_VALUE (expect: primary-failure-test-value)"

  banner "Checking whether min-replicas-to-write / min-replicas-max-lag survived the promotion"
  echo "Hypothesis: NO -- only the original 'redis' service's docker-compose command declared these;"
  echo "Sentinel's promotion (REPLICAOF NO ONE) does not carry arbitrary CONFIG SET values with it."
  docker compose exec -T "$NEW_MASTER" redis-cli CONFIG GET min-replicas-to-write
  docker compose exec -T "$NEW_MASTER" redis-cli CONFIG GET min-replicas-max-lag

  banner "Checking the other surviving replica now follows $NEW_MASTER"
  for svc in redis-replica-1 redis-replica-2; do
    if [ "$svc" != "$NEW_MASTER" ]; then
      echo "--- $svc ---"
      docker compose exec -T "$svc" redis-cli INFO replication | grep -E "^role|master_host|master_link_status"
    fi
  done
fi

banner "Restarting the old primary ($CURRENT_MASTER) -- probing for a split-brain window at sub-second resolution"
echo "Confirming it demotes and starts replicating from the new primary BEFORE it could accept any"
echo "writes -- not just that it eventually shows up as a replica in INFO replication."
RESTART_EPOCH=$(date +%s.%N)
docker compose start "$CURRENT_MASTER" >/dev/null
SPLIT_BRAIN_DETECTED="no"
DEMOTED_AT=""
for sample in $(seq 1 25); do
  NOW=$(date +%s.%N)
  ELAPSED=$(echo "$NOW $RESTART_EPOCH" | awk '{printf "%.2f", $1-$2}')
  ROLE_NOW=$(docker compose exec -T "$CURRENT_MASTER" redis-cli ROLE 2>/dev/null | head -1)
  WRITE_NOW=$(docker compose exec -T "$CURRENT_MASTER" redis-cli SET "splitbrain-probe-${sample}" "$(date +%s.%N)" 2>&1)
  echo "t+${ELAPSED}s after restart: role=$ROLE_NOW  write-attempt-result=$WRITE_NOW"
  if [ "$ROLE_NOW" = "master" ] && [ "$WRITE_NOW" = "OK" ]; then
    SPLIT_BRAIN_DETECTED="yes"
  fi
  if [ "$ROLE_NOW" = "slave" ] && [ -z "$DEMOTED_AT" ]; then
    DEMOTED_AT="$ELAPSED"
    echo "-> demoted to replica at t+${ELAPSED}s; sampling a couple more points then stopping the probe"
    # keep sampling 2 more rounds to make sure it doesn't flip back, then stop
    sleep 0.2
    continue
  fi
  if [ -n "$DEMOTED_AT" ]; then
    break
  fi
  sleep 0.2
done
echo "Demoted at: ${DEMOTED_AT:-not observed within the probe window}"

banner "Final state after reconciliation"
for svc in $DATA_SVCS; do
  echo "--- $svc ---"
  docker compose exec -T "$svc" redis-cli INFO replication | grep -E "^role|master_host|master_link_status|connected_slaves"
done

banner "Saving full Sentinel logs from the kill window (for post-hoc failover-mechanism analysis)"
for svc in sentinel-1 sentinel-2 sentinel-3; do
  docker compose logs "$svc" --since "$KILL_ISO" > "${RUN_DIR}/${svc}.log" 2>&1
  echo "Saved ${RUN_DIR}/${svc}.log ($(wc -l < "${RUN_DIR}/${svc}.log") lines)"
done
FAILOVER_COMPLETED="no"
if grep -q "+switch-master" "${RUN_DIR}/sentinel-1.log" 2>/dev/null; then
  FAILOVER_COMPLETED="yes"
fi
DNS_FAILURES_DURING_KILL=$(grep -c "Failed to resolve hostname" "${RUN_DIR}/sentinel-1.log" 2>/dev/null || echo 0)
echo "Did a real +switch-master event ever occur (per sentinel-1's log): $FAILOVER_COMPLETED"
echo "'Failed to resolve hostname' occurrences in sentinel-1's log during this window: $DNS_FAILURES_DURING_KILL"

banner "VERDICT SUMMARY"
echo "Pre-kill: marker acknowledged (SET -> $SET_RESULT) and confirmed on both replicas via direct GET: $([ "$PRE_KILL_OK" = "yes" ] && echo YES || echo NO)"
echo "Kill target (old primary): $CURRENT_MASTER"
echo "Promoted: ${NEW_MASTER:-NONE}"
echo "Measured RTO (kill-to-promotion): ${RTO}s (1s polling granularity -- a floor, not a precise number)"
echo "Marker write survived on promoted node (direct GET, not inferred): $([ "$MARKER_VALUE" = "$MARKER_EXPECTED" ] && echo YES || echo "NO / not applicable")"
echo "min-replicas-to-write survived promotion: see CONFIG GET output above"
echo "Old primary demoted to replica at: t+${DEMOTED_AT:-NOT OBSERVED}s after restart (sub-second polling)"
echo "Real failover completed this run (+switch-master seen): $FAILOVER_COMPLETED"
if [ "$FAILOVER_COMPLETED" = "yes" ] && [ "$SPLIT_BRAIN_DETECTED" = "yes" ]; then
  echo "SPLIT-BRAIN: YES -- a real promotion completed AND the old primary still answered as master and"
  echo "accepted a write after restart. This is the genuine two-writers scenario the doc warns about."
elif [ "$FAILOVER_COMPLETED" = "no" ] && [ "$SPLIT_BRAIN_DETECTED" = "yes" ]; then
  echo "SPLIT-BRAIN: NO (this run's role+write check alone would have wrongly said yes -- exactly the"
  echo "kind of tool-report-vs-actual-mechanism gap this project's methodology exists to catch). No"
  echo "promotion ever completed, so the 'old' primary was never actually demoted -- it just resumed"
  echo "being the only primary that ever existed. The real finding this run is FAILOVER NON-COMPLETION,"
  echo "not split-brain -- see sentinel-1.log for why (DNS-resolution failures during the outage window)."
else
  echo "SPLIT-BRAIN: NO"
fi
