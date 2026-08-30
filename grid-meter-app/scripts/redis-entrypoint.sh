#!/bin/sh
# Generic entrypoint for all 3 Redis data nodes in the Sentinel HA topology (redis,
# redis-replica-1, redis-replica-2 in docker-compose.yml). Fixes Finding A in
# docs/redis-ha-scope.md: a plain `redis-server` command has no memory of Sentinel's failover
# decisions across a restart -- this container could have been demoted to a replica by Sentinel
# while it was down, but a bare restart with a static command would boot it back up believing
# it's still primary, producing a real split-brain window (confirmed empirically, 3 runs,
# load-tests/vendor-bug-reports/redis/). This script asks Sentinel who the CURRENT master
# actually is before starting, rather than trusting a static docker-compose command to still be
# correct.
#
# MY_HOSTNAME must be set (per-service) to this container's own Compose service name, matching
# what Sentinel would report if this node is currently the master.
#
# FALLBACK_REPLICAOF_HOST/FALLBACK_REPLICAOF_PORT (optional): if Sentinel is genuinely
# unreachable after retrying, a node with these set falls back to this static --replicaof rather
# than starting bare (which would make an unreachable-Sentinel replica silently become an
# unintended second primary -- worse than just preserving its old static assumption). Leave unset
# on the node meant to fall back to plain primary (the "redis" service).
# Bootstrap case (no prior Sentinel state -- first ever `docker compose up`) resolves correctly
# without special-casing: each Sentinel's own command line hardcodes its INITIAL monitor target
# as "redis" (see docker-compose.yml's sentinel-* services), so a fresh Sentinel always reports
# "redis" as master until a real failover changes that -- exactly matching this project's
# intended initial topology.
set -e

SENTINEL_HOSTS="sentinel-1 sentinel-2 sentinel-3"
MASTER_HOST=""
MASTER_PORT=""

echo "redis-entrypoint: I am '$MY_HOSTNAME' -- asking Sentinel who the current master is"
attempt=0
while [ "$attempt" -lt 10 ] && [ -z "$MASTER_HOST" ]; do
  attempt=$((attempt + 1))
  for s in $SENTINEL_HOSTS; do
    RESULT=$(redis-cli -h "$s" -p 26379 sentinel get-master-addr-by-name mymaster 2>/dev/null || true)
    if [ -n "$RESULT" ]; then
      MASTER_HOST=$(echo "$RESULT" | sed -n '1p')
      MASTER_PORT=$(echo "$RESULT" | sed -n '2p')
      echo "redis-entrypoint: $s reports current master is $MASTER_HOST:$MASTER_PORT (attempt $attempt)"
      break
    fi
  done
  if [ -z "$MASTER_HOST" ]; then
    sleep 1
  fi
done

if [ -z "$MASTER_HOST" ]; then
  if [ -n "${FALLBACK_REPLICAOF_HOST:-}" ]; then
    echo "redis-entrypoint: could not reach any Sentinel after $attempt attempts -- falling back to"
    echo "static --replicaof $FALLBACK_REPLICAOF_HOST $FALLBACK_REPLICAOF_PORT rather than risking"
    echo "an unintended second primary. This is a real gap if it happens, not a silent success --"
    echo "logged loudly on purpose."
    exec redis-server "$@" --replicaof "$FALLBACK_REPLICAOF_HOST" "$FALLBACK_REPLICAOF_PORT"
  fi
  echo "redis-entrypoint: could not reach any Sentinel after $attempt attempts -- starting as"
  echo "configured (no fallback replicaof set for this node) with no reconciliation possible."
  echo "This is a real gap if it happens (no way to know the correct role), not a silent success --"
  echo "logged loudly on purpose."
  exec redis-server "$@"
elif [ "$MASTER_HOST" = "$MY_HOSTNAME" ]; then
  echo "redis-entrypoint: Sentinel confirms '$MY_HOSTNAME' is the current master -- starting as primary"
  exec redis-server "$@"
else
  echo "redis-entrypoint: Sentinel reports current master is '$MASTER_HOST' (not '$MY_HOSTNAME') --"
  echo "starting as its replica, not trusting docker-compose.yml's static role assignment"
  exec redis-server "$@" --replicaof "$MASTER_HOST" "$MASTER_PORT"
fi
