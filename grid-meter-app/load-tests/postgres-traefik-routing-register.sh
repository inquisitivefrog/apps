#!/usr/bin/env bash
# docs/postgres-ha-scope.md "Patroni deployment model" §4 spike: registers a Consul service
# ("postgres-primary") with one instance per Patroni node, each backed by an HTTP health check
# against that node's own Patroni REST API /primary endpoint (confirmed live: returns 200 only
# from the actual current primary, 503 from replicas -- verified before this script was written,
# not assumed from Patroni's docs). Only the currently-passing instance is eligible for Traefik's
# Consul Catalog provider to route to, via the traefik.tcp.* tags set on each registration.
#
# Deliberately independent of Patroni's own `register_service` Consul feature -- a documented
# upstream Patroni issue (patroni/patroni#2517) describes the master/primary *tag* getting stuck
# on a stale value after a Consul communication timeout during Patroni's own write path. This
# approach never depends on Patroni successfully writing anything: Consul's own agent actively
# polls each node's /primary endpoint on its own schedule, so the check result is always freshly
# computed, not a value that can go stale from a missed write.
#
# Each Patroni node registers against its own paired Consul agent (patroni-1->consul-1, etc.),
# mirroring the existing node-to-agent pairing already used elsewhere in this project's Postgres
# HA setup, for the same failure-isolation reasoning.
#
# Usage: ./postgres-traefik-routing-register.sh [register|deregister]

set -euo pipefail
cd "$(dirname "$0")/.."

ACTION="${1:-register}"

NODES=(patroni-1 patroni-2 patroni-3)
AGENTS=(consul-1 consul-2 consul-3)

if [[ "$ACTION" == "deregister" ]]; then
  for i in "${!NODES[@]}"; do
    NODE="${NODES[$i]}"
    AGENT="${AGENTS[$i]}"
    echo "Deregistering postgres-primary-${NODE} via ${AGENT}"
    docker compose exec -T "$AGENT" curl -s -X PUT \
      "http://localhost:8500/v1/agent/service/deregister/postgres-primary-${NODE}" || true
  done
  exit 0
fi

for i in "${!NODES[@]}"; do
  NODE="${NODES[$i]}"
  AGENT="${AGENTS[$i]}"
  echo "Registering postgres-primary-${NODE} via ${AGENT}"
  docker compose exec -T "$AGENT" curl -s -X PUT "http://localhost:8500/v1/agent/service/register" -d '{
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

echo
echo "=== Registered. Health status (only the current primary should show 'passing') ==="
sleep 4
docker compose exec -T consul-1 curl -s "http://localhost:8500/v1/health/service/postgres-primary" \
  | python3 -c "
import json, sys
for entry in json.load(sys.stdin):
    node = entry['Service']['Address']
    checks = entry['Checks']
    status = [c['Status'] for c in checks if c['CheckID'].startswith('service:')]
    print(f\"  {node}: {status[0] if status else 'unknown'}\")
"
# ^ python3 runs on the HOST here (not inside the consul container, which has curl but no
# python3) -- docker compose exec's stdout is captured by the host shell's pipe, so this works
# without needing python3 installed in the consul image at all.
