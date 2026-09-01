#!/bin/sh
# Registers the postgres-primary Consul service (one instance per Patroni node) automatically on
# every `docker compose up`, closing a durability gap docs/postgres-ha-scope.md's "Patroni
# deployment model" section explicitly flagged and left open: the original spike only registered
# this manually via load-tests/postgres-traefik-routing-register.sh, so a fresh Consul bootstrap
# (a plain `docker compose down && up`, not even a failure) would silently leave Traefik's :55432
# entrypoint with no backend at all -- an outage caused by a forgotten manual step, not by
# anything Postgres/Patroni/Consul actually doing wrong.
#
# Runs as the one-shot postgres-primary-registrar service in docker-compose.yml, then exits.
# Talks to each Consul agent directly over the compose network (http://consul-N:8500) rather than
# shelling out via `docker compose exec` like the original host-side script, since this runs
# inside a container with no Docker socket access. Registration itself is idempotent (Consul's
# register API is a PUT by ID), so re-running this on every compose up is safe even when the
# services are already registered from a prior run.
#
# Polls each node's own REST API before registering rather than trusting container start order --
# same "verify the actual readiness condition, don't assume" discipline already applied to this
# project's chaos-test scripts (see docs/testing-strategy.md).
set -eu

NODES="patroni-1 patroni-2 patroni-3"
AGENTS="consul-1 consul-2 consul-3"
RETRY_TIMEOUT=90

wait_for_node() {
  NODE="$1"
  ELAPSED=0
  until curl -sf "http://${NODE}:8008/patroni" >/dev/null 2>&1; do
    if [ "$ELAPSED" -ge "$RETRY_TIMEOUT" ]; then
      echo "Timed out after ${RETRY_TIMEOUT}s waiting for ${NODE}:8008" >&2
      exit 1
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
  done
}

for NODE in $NODES; do
  echo "Waiting for ${NODE}:8008 to be reachable..."
  wait_for_node "$NODE"
done

set -- $AGENTS
for NODE in $NODES; do
  AGENT="$1"
  shift
  echo "Registering postgres-primary-${NODE} via ${AGENT}"
  curl -sf -X PUT "http://${AGENT}:8500/v1/agent/service/register" -d '{
    "ID": "postgres-primary-'"${NODE}"'",
    "Name": "postgres-primary",
    "Tags": [
      "traefik.enable=true",
      "traefik.tcp.routers.pgprimary.rule=HostSNI(`*`)",
      "traefik.tcp.routers.pgprimary.entrypoints=pgprimary",
      "traefik.tcp.services.pgprimary.loadbalancer.server.port=5432"
    ],
    "Address": "'"${NODE}"'",
    "Port": 5432,
    "Check": {
      "HTTP": "http://'"${NODE}"':8008/primary",
      "Interval": "3s",
      "Timeout": "2s"
    }
  }'
  echo
done

echo "postgres-primary registration complete."
