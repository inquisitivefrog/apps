#!/usr/bin/env bash
# docs/postgres-ha-scope.md Stage 3: kill one Patroni replica, confirm the primary keeps
# accepting writes throughout, and confirm synchronous_standby_names correctly degrades to (and
# recovers from) the surviving 1-of-2 quorum member. Reusable for both sub-tests (kill patroni-2,
# kill patroni-3) rather than one-off per-node scripts, per this project's own "generalize into a
# wildcard" convention.
#
# Polls for the actual readiness condition throughout (synchronous_standby_names dropping/
# regaining the target node, pg_stat_replication showing caught-up) rather than a fixed sleep --
# per docs/testing-strategy.md's "Test-infrastructure lesson" section, the standing discipline for
# every chaos/failover script in this project.
#
# Usage: ./postgres-replica-failure-test.sh <patroni-2|patroni-3>

set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:?Usage: $0 <patroni-2|patroni-3>}"
case "$TARGET" in
  patroni-2) WITNESS="patroni-3" ;;
  patroni-3) WITNESS="patroni-2" ;;
  *) echo "TARGET must be patroni-2 or patroni-3 (not the leader, patroni-1)" >&2; exit 1 ;;
esac

# WITNESS is whichever replica ISN'T the target -- stays up throughout, so it's a stable vantage
# point for patronictl. patroni-1 (the leader) is deliberately never used for patronictl in this
# script: its own local patroni.yml view went stale mid-session (a Docker Desktop bind-mount
# caching artifact, unrelated to the live cluster's actual correctness) and hasn't been refreshed
# to avoid triggering an unplanned failover -- see docs/postgres-ha-scope.md's Stage 2 results.
#
# psql_primary hardcoding patroni-1 is NOT the same "arbitrary interchangeable peer" pattern fixed
# elsewhere in this project's chaos scripts (docs/testing-strategy.md/postgres-ha-scope.md) --
# psql_primary must reach the actual current primary specifically (writes to a replica would fail
# outright), not just any reachable node, so dynamic peer discovery doesn't apply here. It's safe
# to hardcode only because this script's own TARGET validation above (line 19-22) rejects patroni-1
# as a kill target, guaranteeing patroni-1 remains primary for this script's entire run.
psql_primary() { docker compose exec -T patroni-1 psql -U postgres -Atc "$1"; }
ctl() { docker compose exec -T "$WITNESS" patronictl -c /etc/patroni.yml "$@"; }

echo "=== Baseline: cluster state ==="
ctl list
echo
echo "=== Baseline: synchronous_standby_names ==="
psql_primary "SHOW synchronous_standby_names;"

MARKER="stage3-${TARGET}-$(date +%s)"
echo
echo "=== Marker table + baseline write: $MARKER ==="
docker compose exec -T patroni-1 psql -U postgres -c \
  "CREATE TABLE IF NOT EXISTS stage3_marker (id serial primary key, note text, written_at timestamptz default now());
   INSERT INTO stage3_marker (note) VALUES ('${MARKER}-baseline');"

echo
echo "=== Stopping $TARGET ==="
docker compose stop "$TARGET"

echo
echo "=== Polling for synchronous_standby_names to drop $TARGET (up to 60s) ==="
START=$SECONDS
while (( SECONDS - START < 60 )); do
  CURRENT=$(psql_primary "SHOW synchronous_standby_names;")
  echo "  [$((SECONDS-START))s] $CURRENT"
  if [[ "$CURRENT" != *"$TARGET"* ]]; then
    echo "  -> dropped from the quorum set after $((SECONDS-START))s"
    break
  fi
  sleep 3
done

echo
echo "=== Cluster state with $TARGET down ==="
ctl list || true

echo
echo "=== Write-acceptance check: 5 writes on the primary while $TARGET is down ==="
FAIL=0
for i in 1 2 3 4 5; do
  T0=$(date +%s%N)
  if docker compose exec -T patroni-1 psql -U postgres -c \
      "INSERT INTO stage3_marker (note) VALUES ('${MARKER}-outage-${i}');" >/dev/null 2>/tmp/stage3_write_err; then
    T1=$(date +%s%N)
    echo "  write $i: OK ($(( (T1-T0) / 1000000 ))ms)"
  else
    echo "  write $i: FAILED"
    cat /tmp/stage3_write_err
    FAIL=$((FAIL+1))
  fi
done
echo "  $((5-FAIL))/5 succeeded"

echo
echo "=== Restoring $TARGET ==="
docker compose start "$TARGET"

echo
echo "=== Polling for $TARGET to catch up (streaming, sent_lsn = replay_lsn), up to 90s ==="
START=$SECONDS
while (( SECONDS - START < 90 )); do
  ROW=$(psql_primary "SELECT state || ':' || (sent_lsn = replay_lsn)::text FROM pg_stat_replication WHERE application_name = '$TARGET';")
  echo "  [$((SECONDS-START))s] $TARGET -> ${ROW:-<not connected yet>}"
  if [[ "$ROW" == "streaming:t" ]]; then
    echo "  -> caught up after $((SECONDS-START))s"
    break
  fi
  sleep 5
done

echo
echo "=== Final cluster state ==="
ctl list
echo
echo "=== Final synchronous_standby_names (should name both nodes again) ==="
psql_primary "SHOW synchronous_standby_names;"

echo
echo "=== Marker rows from this run (primary's view) ==="
docker compose exec -T patroni-1 psql -U postgres -c "SELECT * FROM stage3_marker WHERE note LIKE '${MARKER}%' ORDER BY id;"
echo
echo "=== Confirming those rows landed on $TARGET too, via direct query (not lag inference) ==="
docker compose exec -T "$TARGET" psql -U postgres -c "SELECT * FROM stage3_marker WHERE note LIKE '${MARKER}%' ORDER BY id;"
