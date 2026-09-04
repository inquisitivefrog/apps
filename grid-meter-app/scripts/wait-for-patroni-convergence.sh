#!/usr/bin/env bash
# Polls for actual Patroni replica readiness -- not a fixed sleep -- before the E2E CI job's
# cli-postgres.spec.ts runs (it connects directly to a live-discovered replica, bypassing
# Traefik). This wait is NOT just a conservative assumption: empirically confirmed
# (2026-09-04) that the app's own /actuator/health going green (~26s after stack-up) is NOT
# sufficient -- at that point, replicas are still in Patroni's "stopped"/"creating replica"
# states and genuinely refuse TCP connections (ECONNREFUSED), not just report stale data. A
# replica only starts accepting connections once ITS OWN state reaches "streaming" -- observed
# taking ~110-120s from a cold `docker compose up`. See docs/testing-strategy-ha-supplement.md
# and this project's standing "poll for the actual condition, not a proxy" lesson
# (docs/testing-strategy.md).
#
# Usage: scripts/wait-for-patroni-convergence.sh [timeout_seconds]
set -uo pipefail

TIMEOUT="${1:-180}"
INTERVAL=3
elapsed=0

while [ "$elapsed" -lt "$TIMEOUT" ]; do
  list_json=$(docker compose exec -T patroni-1 patronictl -c /etc/patroni.yml list -f json 2>/dev/null)
  if [ -n "$list_json" ]; then
    converged=$(echo "$list_json" | python3 -c "
import sys, json
try:
    members = json.load(sys.stdin)
except Exception:
    print('false')
    sys.exit(0)
replicas = [m for m in members if m.get('Role') != 'Leader']
has_leader = any(m.get('Role') == 'Leader' and m.get('State') == 'running' for m in members)
all_streaming = len(replicas) >= 1 and all(m.get('State') == 'streaming' for m in replicas)
print('true' if has_leader and all_streaming else 'false')
" 2>/dev/null)
    if [ "$converged" = "true" ]; then
      echo "wait-for-patroni-convergence.sh: converged after ${elapsed}s."
      docker compose exec -T patroni-1 patronictl -c /etc/patroni.yml list
      exit 0
    fi
  fi
  sleep "$INTERVAL"
  elapsed=$((elapsed + INTERVAL))
done

echo "================================================================" >&2
echo "wait-for-patroni-convergence.sh: TIMED OUT after ${TIMEOUT}s waiting for a Leader plus" >&2
echo "all replicas to reach 'streaming'. Current state:" >&2
echo "================================================================" >&2
docker compose exec -T patroni-1 patronictl -c /etc/patroni.yml list 2>&1 >&2 || true
exit 1
