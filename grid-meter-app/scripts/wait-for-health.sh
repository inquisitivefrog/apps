#!/usr/bin/env bash
# Polls a health-check URL until it responds successfully or a timeout elapses. Used both locally
# and in CI to wait for the stack to come up before running black-box tests against it.
#
# Usage: scripts/wait-for-health.sh [url] [timeout-seconds]
set -euo pipefail

URL="${1:-http://localhost/actuator/health}"
TIMEOUT="${2:-90}"
ELAPSED=0

until curl -sf "$URL" >/dev/null 2>&1; do
  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "Timed out after ${TIMEOUT}s waiting for $URL" >&2
    exit 1
  fi
  sleep 2
  ELAPSED=$((ELAPSED + 2))
done

echo "$URL is healthy"
