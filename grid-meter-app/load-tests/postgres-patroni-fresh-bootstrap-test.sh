#!/usr/bin/env bash
# docs/postgres-ha-scope.md Stage 7's own write-up explicitly flagged this as unverified: the
# patroni.yml bootstrap.users/post_bootstrap hook that creates the gridmeter role/database (added
# after that gap was found live) has never actually been exercised against a real from-scratch
# bootstrap -- it was declared based on Patroni's documented behavior, not confirmed against this
# project's own running system, exactly the kind of unverified claim this project's whole HA
# investigation exists to catch.
#
# Testing this properly requires wiping BOTH of two things this script found were not what
# patroni.yml's own comment claimed:
#   1. Each Patroni node's Postgres data lives on a Docker-managed ANONYMOUS volume (inherited
#      from the postgres:18.4 base image's own VOLUME declaration), not purely in the container's
#      writable layer as patroni.yml's comment asserts ("this cluster deliberately has no
#      persistent volume"). `docker compose stop`/`start` or even a plain `--force-recreate`
#      reattaches the SAME anonymous volume by default -- confirmed via `docker inspect` showing a
#      real named volume mount, not verified by trusting the comment. `docker compose rm -f -v`
#      (the -v flag) is required to actually remove it.
#   2. Consul still holds a full `service/gridmeter-postgres-ha/*` KV tree (initialize key,
#      leader, members, history) from the existing cluster. Left in place, Patroni would see an
#      "already initialized" cluster on the freshly-emptied nodes and attempt to REJOIN as a
#      replica of a leader with no data, never triggering bootstrap.users/post_bootstrap at all --
#      a false-negative test that looks like it ran but never actually exercised the hook.
#
# This is destructive to the CURRENTLY LIVE Patroni cluster the app is cut over to (real outage,
# real data loss -- though only demo data, recreated fresh by Flyway/seed migrations). Confirmed
# explicitly requested (relayed via Claude Chat) specifically because a hook that has never fired
# is exactly the kind of unverified claim this project doesn't let stand.
#
# Usage: ./postgres-patroni-fresh-bootstrap-test.sh
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1

RUN_TS="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="load-tests/vendor-bug-reports/postgres/runs/${RUN_TS}-fresh-bootstrap"
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

banner "Pre-teardown: confirming the current (about-to-be-destroyed) cluster is healthy"
docker compose exec -T patroni-1 patronictl -c /etc/patroni.yml list 2>&1

banner "Step 1: stopping and removing all 3 Patroni containers WITH their anonymous volumes (-v)"
VOL_1=$(docker inspect grid-meter-app-patroni-1-1 --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{end}}{{end}}' 2>/dev/null)
VOL_2=$(docker inspect grid-meter-app-patroni-2-1 --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{end}}{{end}}' 2>/dev/null)
VOL_3=$(docker inspect grid-meter-app-patroni-3-1 --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{end}}{{end}}' 2>/dev/null)
echo "Anonymous volumes before removal: $VOL_1 / $VOL_2 / $VOL_3"
docker compose stop patroni-1 patroni-2 patroni-3
docker compose rm -f -v patroni-1 patroni-2 patroni-3

echo "Confirming those specific volume IDs are actually gone, not just detached:"
for v in "$VOL_1" "$VOL_2" "$VOL_3"; do
  if [ -n "$v" ]; then
    if docker volume inspect "$v" >/dev/null 2>&1; then
      echo "  $v -- STILL EXISTS (real problem, -v did not remove it)"
    else
      echo "  $v -- gone, confirmed"
    fi
  fi
done

banner "Step 2: clearing Consul's KV tree for this cluster scope, so it looks genuinely new"
docker compose exec -T consul-1 consul kv delete -recurse service/gridmeter-postgres-ha/ 2>&1
echo "--- confirming empty ---"
docker compose exec -T consul-1 consul kv get -recurse service/gridmeter-postgres-ha 2>&1 || echo "(empty, as expected)"

banner "Step 3: bringing up patroni-1 alone first (matching the original Stage 2 bootstrap order)"
docker compose up -d patroni-1
echo "Waiting up to 60s for patroni-1 to report itself as a running Leader..."
BOOTSTRAPPED=0
for i in $(seq 1 60); do
  STATE=$(docker compose exec -T patroni-1 patronictl -c /etc/patroni.yml list 2>&1)
  if echo "$STATE" | grep -q "Leader.*running"; then
    echo "patroni-1 self-bootstrapped as Leader at t+${i}s"
    echo "$STATE"
    BOOTSTRAPPED=1
    break
  fi
  sleep 1
done
if [ "$BOOTSTRAPPED" -eq 0 ]; then
  echo "!!! patroni-1 did not bootstrap as Leader within 60s -- real failure, aborting" >&2
  docker compose logs patroni-1 --tail 50 2>&1
  exit 1
fi

banner "Step 4: checking whether the gridmeter role/database exist YET -- this is the actual test"
echo "(if the hook works, these should already exist purely from patroni-1's own bootstrap, before"
echo "patroni-2/patroni-3 even join, and before any manual intervention of any kind)"
ROLE_CHECK=$(docker compose exec -T patroni-1 psql -U postgres -Atc "SELECT 1 FROM pg_roles WHERE rolname='gridmeter';" 2>&1)
DB_CHECK=$(docker compose exec -T patroni-1 psql -U postgres -Atc "SELECT 1 FROM pg_database WHERE datname='gridmeter';" 2>&1)
echo "gridmeter role exists: $([ "$ROLE_CHECK" = "1" ] && echo YES || echo "NO ($ROLE_CHECK)")"
echo "gridmeter database exists: $([ "$DB_CHECK" = "1" ] && echo YES || echo "NO ($DB_CHECK)")"

HOOK_WORKED="no"
if [ "$ROLE_CHECK" = "1" ] && [ "$DB_CHECK" = "1" ]; then
  HOOK_WORKED="yes"
fi

banner "Step 5: bringing up patroni-2 and patroni-3, confirming they join as replicas"
docker compose up -d patroni-2 patroni-3
echo "Waiting up to 90s for both to show up as streaming replicas (a from-scratch initial sync can"
echo "take longer than a normal restart's rejoin -- don't assume the same 60s ceiling applies)..."
JOINED=0
for i in $(seq 1 90); do
  STATE=$(docker compose exec -T patroni-1 patronictl -c /etc/patroni.yml list 2>&1)
  REPLICA_COUNT=$(echo "$STATE" | grep -c "streaming")
  if [ "$REPLICA_COUNT" -ge 2 ]; then
    echo "Both replicas streaming at t+${i}s"
    echo "$STATE"
    JOINED=1
    break
  fi
  sleep 1
done
if [ "$JOINED" -eq 0 ]; then
  echo "!!! Replicas did not both join within 60s -- real finding, reporting current state:" >&2
  docker compose exec -T patroni-1 patronictl -c /etc/patroni.yml list 2>&1
fi

banner "Step 6: re-registering postgres-primary in Consul (registrar is a one-shot, already exited)"
docker compose up -d --force-recreate postgres-primary-registrar
sleep 3
docker compose logs postgres-primary-registrar --tail 20 2>&1

banner "Step 7: restarting api against the fresh cluster, confirming Flyway + real app traffic work"
docker compose restart api
echo "Waiting for api health..."
API_HEALTHY=0
for i in $(seq 1 30); do
  if curl -sf http://localhost/actuator/health >/dev/null 2>&1; then
    echo "api healthy at t+${i}s"
    API_HEALTHY=1
    break
  fi
  sleep 1
done
if [ "$API_HEALTHY" -eq 0 ]; then
  echo "!!! api did not become healthy within 30s" >&2
  docker compose logs api --tail 60 2>&1
fi

# Polled, not a single one-shot check -- api becoming "healthy" guarantees Flyway already ran
# (Spring's startup sequence runs it before the actuator port opens), but docker's own log driver
# can lag a moment behind the container's actual stdout, so a single immediate check can race a
# real success into a false "no" the same way this project's chaos scripts have hit before.
FLYWAY_RAN="no"
for i in $(seq 1 5); do
  if docker compose logs api 2>&1 | grep -q "Successfully applied 6 migrations"; then
    FLYWAY_RAN="yes"
    break
  fi
  sleep 1
done
echo "Flyway ran all 6 migrations against the fresh database: $FLYWAY_RAN"

APP_WORKS="no"
if [ "$API_HEALTHY" -eq 1 ]; then
  TOKEN=$(curl -s -X POST http://localhost/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"demo","password":"GridMeter!Demo2026"}' \
    | python3 -c "import sys,json;print(json.load(sys.stdin).get('accessToken',''))" 2>/dev/null)
  if [ -n "$TOKEN" ]; then
    METER_RESP=$(curl -s -X POST http://localhost/api/v1/meters \
      -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
      -d '{"serialNumber":"FRESH-BOOTSTRAP-TEST","location":"Test","status":"ACTIVE","installedAt":"2026-01-01T00:00:00Z"}')
    echo "Real end-to-end check (login + create meter): $METER_RESP"
    if echo "$METER_RESP" | grep -q '"id"'; then
      APP_WORKS="yes"
    fi
  fi
fi

banner "RESULT SUMMARY"
echo "gridmeter role created purely by the bootstrap.users hook: $([ "$ROLE_CHECK" = "1" ] && echo YES || echo NO)"
echo "gridmeter database created purely by the post_bootstrap hook: $([ "$DB_CHECK" = "1" ] && echo YES || echo NO)"
echo "Hook overall verdict: $([ "$HOOK_WORKED" = "yes" ] && echo "WORKS AS DECLARED -- verified, not assumed" || echo "DID NOT WORK -- real gap, needs fixing")"
echo "Both replicas joined cleanly: $([ "$JOINED" -eq 1 ] && echo YES || echo NO)"
echo "Flyway migrations ran clean against the fresh database: $FLYWAY_RAN"
echo "Real end-to-end app request (login + create meter) succeeded: $APP_WORKS"

banner "Final cluster state"
docker compose exec -T patroni-1 patronictl -c /etc/patroni.yml list 2>&1
