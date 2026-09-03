#!/usr/bin/env bash
# Redis/Sentinel Stage 5 per docs/redis-ha-scope.md: quorum-loss equivalent -- kill 2 of 3
# Sentinels. Mirrors Kafka's quorum-loss test: confirm the system fails safe rather than doing
# anything unsafe when the consensus layer can't reach majority.
#
# Two sub-tests:
#   A) Kill 2 Sentinels while primary+replicas stay healthy -- confirm nothing changes: primary
#      keeps serving, no failover attempted, and the lone surviving Sentinel correctly reports it
#      cannot reach quorum/failover-authorization.
#   B) The real test: with only 1 Sentinel left, ALSO kill the primary. A lone Sentinel lacks the
#      majority (2 of 3) required to authorize a failover -- confirm it does NOT unilaterally
#      promote a replica anyway. The correct, safe outcome is staying leaderless/unavailable, not
#      an unsafe minority-authorized promotion.
#
# Applies the readiness-polling discipline learned fixing Finding B
# (load-tests/vendor-bug-reports/redis/NOTES.md): no fixed sleeps standing in for "is the topology
# actually ready" -- every wait polls the real condition.
#
# This is a TRACKING/verification script -- always exits 0. An unsafe promotion IS the reportable
# finding, not a script bug. Every run's output, plus sentinel-1's full log from the incident
# window, is saved under load-tests/vendor-bug-reports/redis/runs/<timestamp>-stage5/.
#
# Usage: load-tests/redis-quorum-loss.sh
# Prerequisites: full stack up, Stage 2/3/4 topology already built (Findings A and B fixed).
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1

RUN_TS="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="load-tests/vendor-bug-reports/redis/runs/${RUN_TS}-stage5"
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

banner "Resetting to canonical topology before this run"
docker compose up -d --force-recreate redis redis-replica-1 redis-replica-2 sentinel-1 sentinel-2 sentinel-3

banner "Waiting for Sentinel to discover both replicas (Finding B's fix)"
DISCOVERED=0
for i in $(seq 1 30); do
  KNOWN=$(docker compose exec -T sentinel-1 redis-cli -p 26379 sentinel replicas mymaster 2>/dev/null | grep -c "^ip$")
  if [ "$KNOWN" -ge 2 ]; then
    DISCOVERED=1
    echo "Both replicas discovered at t+${i}s"
    break
  fi
  sleep 1
done
if [ "$DISCOVERED" -eq 0 ]; then
  echo "Sentinel never discovered both replicas -- aborting this run (setup problem, not a Stage 5 finding)."
  exit 0
fi

banner "Waiting for the primary to consider both replicas 'good' for min-replicas-to-write"
GOOD=0
for i in $(seq 1 15); do
  GOOD_SLAVES=$(docker compose exec -T redis redis-cli INFO replication 2>/dev/null | grep "min_slaves_good_slaves" | tr -d '\r' | cut -d: -f2)
  if [ "${GOOD_SLAVES:-0}" -ge 1 ]; then
    GOOD=1
    echo "Primary considers replicas good at t+${i}s"
    break
  fi
  sleep 1
done
if [ "$GOOD" -eq 0 ]; then
  echo "Primary never considered a replica good -- aborting this run (setup problem, not a Stage 5 finding)."
  exit 0
fi

CURRENT_MASTER=$(find_master_service)
echo "Current master service: ${CURRENT_MASTER:-NONE FOUND}"
if [ "$CURRENT_MASTER" != "redis" ]; then
  echo "Reset did not converge on 'redis' as master -- aborting this run (setup problem)."
  exit 0
fi

banner "Baseline: quorum reachable with all 3 Sentinels healthy"
# Dynamic query target -- unlike every other sentinel-1 reference below (which is this test's own
# deliberately-designated survivor, kept alive by construction once Sub-test A starts), this
# baseline check runs BEFORE anything is killed, when all 3 Sentinels are still arbitrary,
# interchangeable healthy peers -- a hardcoded target here would still fail for an unrelated
# reason if sentinel-1 specifically were left down by an earlier test run.
for AGENT in sentinel-1 sentinel-2 sentinel-3; do
  if docker compose exec -T "$AGENT" redis-cli -p 26379 sentinel ckquorum mymaster; then
    break
  fi
done

KILL_ISO_A=$(date -u +%Y-%m-%dT%H:%M:%SZ)
banner "SUB-TEST A: killing sentinel-2 and sentinel-3 (2 of 3) -- primary/replicas stay healthy"
docker compose stop sentinel-2 sentinel-3

banner "Actively polling for sentinel-1 to detect its peers are gone (a fixed sleep here raced"
echo "peer-liveness detection the same way Finding B's fixed sleep raced replica discovery --"
echo "polling for the real condition instead of guessing a duration)."
QUORUM_AFTER_A=""
for i in $(seq 1 20); do
  QUORUM_AFTER_A=$(docker compose exec -T sentinel-1 redis-cli -p 26379 sentinel ckquorum mymaster 2>&1)
  echo "t+${i}s: $QUORUM_AFTER_A"
  if echo "$QUORUM_AFTER_A" | grep -q "NOQUORUM"; then
    echo "Quorum loss detected at t+${i}s"
    break
  fi
  sleep 1
done

banner "Confirming the primary is unaffected -- still serves writes normally"
MARKER_A="stage5a-marker-$(date +%s)"
WRITE_A=$(docker compose exec -T "$CURRENT_MASTER" redis-cli SET "$MARKER_A" "quorum-loss-safe-case" 2>&1)
echo "SET result: $WRITE_A"
ROLE_A=$(docker compose exec -T "$CURRENT_MASTER" redis-cli ROLE 2>/dev/null | head -1)
echo "Primary role after 2-Sentinel loss: $ROLE_A (expect: master, unchanged)"

banner "SUB-TEST B: with sentinel-2/3 still down, ALSO killing the primary -- the real test"
MARKER_B="stage5b-marker-$(date +%s)"
SET_B=$(docker compose exec -T "$CURRENT_MASTER" redis-cli SET "$MARKER_B" "quorum-loss-unsafe-case-marker" 2>&1)
echo "Pre-kill marker SET result: $SET_B"
for svc in redis-replica-1 redis-replica-2; do
  VAL=$(docker compose exec -T "$svc" redis-cli GET "$MARKER_B" 2>&1)
  echo "$svc GET $MARKER_B -> $VAL"
done

KILL_ISO_B=$(date -u +%Y-%m-%dT%H:%M:%SZ)
docker compose stop "$CURRENT_MASTER"

banner "Polling 30s: does the lone sentinel-1 unsafely promote a replica despite lacking quorum?"
UNSAFE_PROMOTION="no"
UNSAFE_SVC=""
for i in $(seq 1 30); do
  for svc in redis-replica-1 redis-replica-2; do
    ROLE=$(docker compose exec -T "$svc" redis-cli ROLE 2>/dev/null | head -1)
    if [ "$ROLE" = "master" ]; then
      UNSAFE_PROMOTION="yes"
      UNSAFE_SVC="$svc"
      break 2
    fi
  done
  sleep 1
done
echo "Unsafe promotion occurred: $UNSAFE_PROMOTION ${UNSAFE_SVC:+(by $UNSAFE_SVC)}"

banner "Sentinel-1's own final view (quorum + master state)"
docker compose exec -T sentinel-1 redis-cli -p 26379 sentinel ckquorum mymaster
docker compose exec -T sentinel-1 redis-cli -p 26379 sentinel master mymaster 2>&1 | grep -A1 "^flags"

banner "Saving sentinel-1's full log from the incident window"
docker compose logs sentinel-1 --since "$KILL_ISO_A" > "${RUN_DIR}/sentinel-1.log" 2>&1
echo "Saved ${RUN_DIR}/sentinel-1.log ($(wc -l < "${RUN_DIR}/sentinel-1.log") lines)"

banner "Restoring the full topology"
docker compose start "$CURRENT_MASTER" sentinel-2 sentinel-3
sleep 10
for svc in $DATA_SVCS; do
  echo "--- $svc ---"
  docker compose exec -T "$svc" redis-cli INFO replication | grep -E "^role|master_host|master_link_status"
done

QUORUM_LOSS_DETECTED="no"
echo "$QUORUM_AFTER_A" | grep -q "NOQUORUM" && QUORUM_LOSS_DETECTED="yes"

banner "VERDICT SUMMARY"
echo "Sub-test A (quorum lost, primary healthy): write result=$WRITE_A, role stayed=$ROLE_A,"
echo "  sentinel-1 correctly detected quorum loss: $QUORUM_LOSS_DETECTED"
echo "Sub-test B (quorum lost AND primary killed): unsafe promotion = $UNSAFE_PROMOTION ${UNSAFE_SVC:+(by $UNSAFE_SVC)}"
if [ "$WRITE_A" = "OK" ] && [ "$ROLE_A" = "master" ] && [ "$QUORUM_LOSS_DETECTED" = "yes" ] && [ "$UNSAFE_PROMOTION" = "no" ]; then
  echo "PASS: quorum loss alone changed nothing (primary kept serving normally), sentinel-1 correctly"
  echo "detected it lost quorum, and the system correctly failed safe when quorum loss was combined"
  echo "with a real primary failure -- no unauthorized promotion occurred despite the primary being down."
else
  echo "FAIL or UNEXPECTED -- review the transcript above; this is a real finding, not a script bug."
fi
