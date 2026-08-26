#!/usr/bin/env bash
# Real Docker Compose autoscaling for the api service: polls docker stats for CPU%/memory% on
# every currently-running api container, and calls `docker compose up -d --scale api=<n>` itself
# when a sustained threshold is crossed. Docker Compose has no built-in controller loop for this
# (unlike k8s HPA) -- this script IS that loop, not a simulation of one. See
# docs/autoscaling-scope.md for why api is the only service this applies to.
#
# Scale-out is fast (few consecutive high readings) and scale-in is slow (many consecutive low
# readings) -- standard anti-flapping practice: react quickly to real pressure, be conservative
# about declaring it over. Runs until killed (SIGTERM/SIGINT).
#
# Scale-OUT triggers on CPU% OR memory% (either is a legitimate pressure signal worth reacting
# to). Scale-IN triggers on CPU% ONLY, deliberately excluding memory -- verified empirically, not
# assumed: under real load, JVM memory climbed to ~98% of the container limit and simply stayed
# there even after CPU dropped back to ~0% once load subsided (a JVM doesn't reliably release
# committed heap just because load drops). Requiring memory to also be "low" before scaling in
# would have meant this watcher never scaled down at all. This matches standard real-world
# autoscaling practice of excluding memory from scale-in decisions for exactly this reason.
#
# Usage: load-tests/autoscale-watcher.sh <log-file> [options]
#   CPU_THRESHOLD=75          -- percent of the container's cpus limit (docker-compose.yml: 1.0).
#                                Used for BOTH scale-out and scale-in decisions.
#   MEM_THRESHOLD=80          -- percent of the container's memory limit (512m). Scale-out ONLY --
#                                see the scale-in note above for why.
#   POLL_SECONDS=5
#   SCALE_UP_STREAK=3         -- consecutive high polls before scaling out (~15s at default interval)
#   SCALE_DOWN_STREAK=12      -- consecutive low polls before scaling in (~60s) -- slower by design
#   MIN_REPLICAS=1
#   MAX_REPLICAS=2
set -uo pipefail
cd "$(dirname "$0")/.."

LOG="${1:?Usage: $0 <log-file>}"
CPU_THRESHOLD="${CPU_THRESHOLD:-75}"
MEM_THRESHOLD="${MEM_THRESHOLD:-80}"
POLL_SECONDS="${POLL_SECONDS:-5}"
SCALE_UP_STREAK="${SCALE_UP_STREAK:-3}"
SCALE_DOWN_STREAK="${SCALE_DOWN_STREAK:-12}"
MIN_REPLICAS="${MIN_REPLICAS:-1}"
MAX_REPLICAS="${MAX_REPLICAS:-2}"

trap 'exit 0' TERM INT

high_streak=0
low_streak=0

log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $1" >> "$LOG"; }

log "watcher started: CPU_THRESHOLD=${CPU_THRESHOLD}% MEM_THRESHOLD=${MEM_THRESHOLD}% poll=${POLL_SECONDS}s scale_up_streak=${SCALE_UP_STREAK} scale_down_streak=${SCALE_DOWN_STREAK} bounds=[${MIN_REPLICAS},${MAX_REPLICAS}]"

while true; do
  containers=$(docker compose ps -q api 2>/dev/null)
  current_replicas=$(echo "$containers" | grep -c .)

  if [ "$current_replicas" -eq 0 ]; then
    log "no api containers found -- skipping this poll"
    sleep "$POLL_SECONDS"
    continue
  fi

  any_high=0
  all_cpu_low=1
  readings=""
  for c in $containers; do
    name=$(docker inspect --format '{{.Name}}' "$c" | sed 's#^/##')
    stats=$(docker stats --no-stream --format "{{.CPUPerc}}\t{{.MemPerc}}" "$c" 2>/dev/null)
    cpu=$(echo "$stats" | cut -f1 | tr -d '%')
    mem=$(echo "$stats" | cut -f2 | tr -d '%')
    readings="$readings $name(cpu=${cpu}%,mem=${mem}%)"
    cpu_int=${cpu%.*}
    mem_int=${mem%.*}
    if [ "${cpu_int:-0}" -ge "$CPU_THRESHOLD" ] || [ "${mem_int:-0}" -ge "$MEM_THRESHOLD" ]; then
      any_high=1
    fi
    if [ "${cpu_int:-0}" -ge "$CPU_THRESHOLD" ]; then
      all_cpu_low=0
    fi
  done

  # high_streak and low_streak are independent, not mutually exclusive: "memory high, CPU low" is
  # a real state (see the scale-in note above) and must count toward BOTH -- an if/elif here once
  # let sustained-high memory alone block low_streak from ever incrementing at all, even with CPU
  # idle, which meant this watcher could never scale in. Caught empirically, not by inspection.
  if [ "$any_high" -eq 1 ]; then
    high_streak=$((high_streak + 1))
  else
    high_streak=0
  fi
  if [ "$all_cpu_low" -eq 1 ]; then
    low_streak=$((low_streak + 1))
  else
    low_streak=0
  fi

  log "replicas=$current_replicas high_streak=$high_streak low_streak=$low_streak$readings"

  if [ "$any_high" -eq 1 ] && [ "$high_streak" -ge "$SCALE_UP_STREAK" ] && [ "$current_replicas" -lt "$MAX_REPLICAS" ]; then
    new_count=$((current_replicas + 1))
    log "SCALING OUT: $current_replicas -> $new_count (sustained pressure for ${high_streak} polls)"
    docker compose up -d --scale api="$new_count" api >> "$LOG" 2>&1
    high_streak=0
    low_streak=0
  elif [ "$all_cpu_low" -eq 1 ] && [ "$low_streak" -ge "$SCALE_DOWN_STREAK" ] && [ "$current_replicas" -gt "$MIN_REPLICAS" ]; then
    new_count=$((current_replicas - 1))
    log "SCALING IN: $current_replicas -> $new_count (sustained calm for ${low_streak} polls)"
    docker compose up -d --scale api="$new_count" api >> "$LOG" 2>&1
    high_streak=0
    low_streak=0
  fi

  sleep "$POLL_SECONDS"
done
