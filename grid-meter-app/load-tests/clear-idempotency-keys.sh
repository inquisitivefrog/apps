#!/usr/bin/env bash
# Deletes every idempotency key (idempotency:<uuid>, ReadingService) from Redis so each load-test
# run starts from a clean state. run.sh calls it before every run, the same way it seeds users.
#
# Why: each POST /readings stores its Idempotency-Key for 24h (docs/idempotency-scope.md). At load-
# test rates that is ~100 bytes x ~4,000 readings/s, and the keys from earlier runs are still
# there when the next one starts. On 2026-11-18 a day of runs (~1.7M keys) pushed all three kind
# Redis pods past their 128Mi limit mid-run, so a run that had passed earlier failed for reasons
# that had nothing to do with its own load. Only the idempotency keys are removed: latest readings,
# active users and anything else in Redis stay.
#
# Deletes on the current master only (replicas follow), found by asking each Redis its role, so it
# works after a Sentinel failover. UNLINK frees memory in the background without blocking Redis.
# Targets the kind cluster if its redis StatefulSet is reachable, otherwise the Compose stack.
#
# Usage: ./clear-idempotency-keys.sh
set -euo pipefail

CLEAR='before=$(redis-cli --scan --pattern "idempotency:*" | wc -l);
       redis-cli --scan --pattern "idempotency:*" --count 1000 | xargs -r -n 1000 redis-cli unlink >/dev/null;
       echo "$before $(redis-cli --scan --pattern "idempotency:*" | wc -l) $(redis-cli info memory | grep ^used_memory_human: | cut -d: -f2 | tr -d "\r")"'

if kubectl --context kind-grid-meter get statefulset redis >/dev/null 2>&1; then
  TARGET="kind"
  for pod in redis-0 redis-1 redis-2; do
    if kubectl --context kind-grid-meter exec "$pod" -- redis-cli role 2>/dev/null | head -1 | grep -q master; then
      MASTER="$pod"; break
    fi
  done
  run() { kubectl --context kind-grid-meter exec "$MASTER" -- sh -c "$1"; }
else
  TARGET="Compose"
  for svc in redis redis-replica-1 redis-replica-2; do
    if docker compose exec -T "$svc" redis-cli role 2>/dev/null | head -1 | grep -q master; then
      MASTER="$svc"; break
    fi
  done
  run() { docker compose exec -T "$MASTER" sh -c "$1"; }
fi

if [ -z "${MASTER:-}" ]; then
  echo "No Redis master found on $TARGET -- is the stack up?" >&2
  exit 1
fi

read -r BEFORE AFTER USED < <(run "$CLEAR")
echo "Cleared idempotency keys on $TARGET ($MASTER): $BEFORE removed, $AFTER left, Redis now using $USED."
