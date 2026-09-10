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
# what Sentinel would report if this node is currently the master. In k8s (k8s/redis.yaml), this
# script is shared unmodified -- the StatefulSet's own command wrapper computes MY_HOSTNAME per
# pod from the Downward API (the pod's own name) plus the headless Service's DNS suffix, instead
# of Compose's one-hardcoded-value-per-service approach, since a StatefulSet applies one identical
# pod template to every replica.
#
# SENTINEL_HOSTS (optional, space-separated): defaults to Compose's 3 service names; overridden
# in k8s to the 3 Sentinel pods' headless-Service DNS names.
#
# FALLBACK_REPLICAOF_HOST/FALLBACK_REPLICAOF_PORT (optional): if Sentinel is genuinely
# unreachable after retrying, a node with these set falls back to this static --replicaof rather
# than starting bare (which would make an unreachable-Sentinel replica silently become an
# unintended second primary -- worse than just preserving its old static assumption). Leave unset
# on the node meant to fall back to plain primary (the "redis" service in Compose, redis-0 in k8s).
# Bootstrap case (no prior Sentinel state -- first ever `docker compose up`) resolves correctly
# without special-casing: each Sentinel's own command line hardcodes its INITIAL monitor target
# as "redis" (see docker-compose.yml's sentinel-* services), so a fresh Sentinel always reports
# "redis" as master until a real failover changes that -- exactly matching this project's
# intended initial topology.
set -e

# Defaults to Compose's own 3 Sentinel service names, unchanged from before this was
# parameterized -- overridden via env var in k8s (k8s/redis.yaml), where the hosts are per-pod
# headless-Service DNS names instead of Compose service names.
SENTINEL_HOSTS="${SENTINEL_HOSTS:-sentinel-1 sentinel-2 sentinel-3}"
MASTER_HOST=""
MASTER_PORT=""

echo "redis-entrypoint: I am '$MY_HOSTNAME' -- asking Sentinel who the current master is"
# Real, live-confirmed gap in the original version of this loop (found 2026-09-09 re-running the
# Compose Stage 4 regression after the k8s SENTINEL_HOSTS parameterization): `SENTINEL
# get-master-addr-by-name` can and does return the OLD master's address for several seconds
# *after* a new master has already been selected and promoted -- Sentinel does not update that
# specific answer until the ENTIRE failover completes (every known replica reconfigured, the
# `+switch-master` event), not merely once a replacement has been chosen. Confirmed live: a
# restarted node whose query landed during this window got told it was still master, started as
# one, and accepted a write before Sentinel's own later runtime `REPLICAOF` call corrected it --
# the exact two-writer window Finding A's fix exists to prevent, just via a mechanism this
# original version never accounted for.
#
# The fix went through two iterations, both confirmed via a dedicated live probe rather than
# guessed. The first checked only for the literal substring `failover_in_progress` in `SENTINEL
# master mymaster`'s `flags` field -- real, but incomplete: a second, EARLIER race (found
# re-verifying the first fix) showed a query landing in the narrow window right after a kill but
# *before* Sentinel has even started reacting to it, where flags read `s_down,master` -- subjectively
# suspected down, but no failover initiated yet, so no `failover_in_progress` substring exists to
# catch. Rather than enumerate every unhealthy flag combination Sentinel can report
# (`master,disconnected`, `s_down,master`, `s_down,o_down,master,failover_in_progress`, and
# whatever else exists that hasn't been observed yet), the robust fix is the inverse: only ever
# trust an answer when flags is the single, clean, literal value "master" -- confirmed via live
# probing to be the actual steady-state value, with every other observed combination (transient or
# otherwise) containing something appended to it. Anything other than exactly "master" means don't
# trust get-master-addr-by-name yet, regardless of which specific unhealthy condition it is.
#
# This stricter check has a real cost, found live re-verifying it: a genuinely fresh, simultaneous
# bootstrap (every data node and every Sentinel recreated at once, e.g. this project's own Stage 4
# test resetting to canonical topology before each run) can spend a while in `master,disconnected`
# then `s_down,master,disconnected` before the first-ever Sentinel-to-primary connection actually
# settles -- a normal, expected part of cold start, not a failover, but indistinguishable from one
# by the flags value alone. 30 attempts (30s) was not always enough headroom for this under real
# resource contention (a concurrent `kind` cluster sharing the same Docker Desktop VM, in the run
# that first surfaced this). Widened to 60 to give genuine cold starts real margin -- correctness
# (never trusting a dirty flag) matters more here than shaving a few seconds off startup latency,
# and every node still has its FALLBACK_REPLICAOF_HOST/PORT (or loud bare-start log) safety net if
# even that isn't enough.
max_attempts=60
attempt=0
while [ "$attempt" -lt "$max_attempts" ] && [ -z "$MASTER_HOST" ]; do
  attempt=$((attempt + 1))
  for s in $SENTINEL_HOSTS; do
    FLAGS=$(redis-cli -h "$s" -p 26379 sentinel master mymaster 2>/dev/null | awk '/^flags$/{getline; print; exit}')
    if [ "$FLAGS" != "master" ]; then
      echo "redis-entrypoint: $s reports flags='$FLAGS' (not a clean 'master') -- not trusting its answer yet (attempt $attempt)"
      continue
    fi
    RESULT=$(redis-cli -h "$s" -p 26379 sentinel get-master-addr-by-name mymaster 2>/dev/null || true)
    if [ -n "$RESULT" ]; then
      MASTER_HOST=$(echo "$RESULT" | sed -n '1p')
      MASTER_PORT=$(echo "$RESULT" | sed -n '2p')
      echo "redis-entrypoint: $s reports current master is $MASTER_HOST:$MASTER_PORT (attempt $attempt, flags=$FLAGS)"
      break
    fi
  done
  if [ -z "$MASTER_HOST" ]; then
    sleep 1
  fi
done

# A second, structural gap found alongside the failover_in_progress one, live-confirmed via a
# plain, non-killing restart of the (genuinely still-healthy) current master: Sentinel only ever
# knows an entity's HOSTNAME if it was the address given on Sentinel's own static, original
# `sentinel monitor mymaster <host> ...` line (the "redis" service in Compose, redis-0 in k8s).
# Any OTHER node -- specifically, any node that becomes master via a real failover -- is known to
# Sentinel only by the raw connection IP it saw that node's replica traffic arrive from (no
# `replica-announce-ip` is configured, so a replica never tells its master a hostname to remember).
# `MASTER_HOST` above can therefore be a raw IP identical to THIS node's own current IP, which will
# never string-equal `$MY_HOSTNAME` -- confirmed live: a real promoted master, restarted with no
# failure at all, was told the master was its own IP, failed the hostname comparison, and issued
# `--replicaof <its own IP>` on itself (rejected by Redis as self-referential, leaving it an
# orphaned, disconnected pseudo-replica -- not real split-brain, since it never accepted writes
# and instead recognizes no working master, but every bit as broken operationally). Fixed by also
# resolving this node's own current IP and accepting either form as a match, since Sentinel's
# reported address will be one or the other depending on how it originally learned this node's
# identity, never both.
MY_IP=$(hostname -i 2>/dev/null | awk '{print $1}')

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
elif [ "$MASTER_HOST" = "$MY_HOSTNAME" ] || { [ -n "$MY_IP" ] && [ "$MASTER_HOST" = "$MY_IP" ]; }; then
  echo "redis-entrypoint: Sentinel confirms '$MASTER_HOST' is the current master, and that's me"
  echo "('$MY_HOSTNAME', ip $MY_IP) -- starting as primary"
  exec redis-server "$@"
else
  echo "redis-entrypoint: Sentinel reports current master is '$MASTER_HOST' (not '$MY_HOSTNAME' or"
  echo "'$MY_IP') -- starting as its replica, not trusting docker-compose.yml's static role assignment"
  exec redis-server "$@" --replicaof "$MASTER_HOST" "$MASTER_PORT"
fi
