#!/usr/bin/env bash
# Reports what's currently listening on host port 80 and the docker-compose.yml stack's status.
# Written for the k8s/kind demo: kind's port mapping (see k8s/kind-config.yaml) needs port 80
# free, and Compose's traefik service binds it too, so the two can't run at the same time.
set -uo pipefail

echo "== Listening on port 80 =="
lsof -nP -iTCP:80 -sTCP:LISTEN || echo "(nothing listening on port 80)"

echo
echo "== docker compose stack status =="
docker compose ps --format '{{.Name}}: {{.Status}}' || echo "(no compose stack running, or not in a compose project directory)"
