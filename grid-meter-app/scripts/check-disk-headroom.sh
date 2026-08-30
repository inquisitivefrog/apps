#!/usr/bin/env bash
# Guards against the repeated Docker-disk-exhaustion pattern seen across several sessions: Docker's
# default json-file logging driver has no size cap, TRACE-level debug logging and
# high-request-volume load tests generate a lot of it, and Docker Desktop's VM disk (Docker.raw) is
# a sparse file that only shrinks back down in response to an actual prune -- so across many test
# sessions with no prune in between, free disk just ratchets down until something stops working and
# gets "fixed" with a reboot. docker-compose.yml's per-service `logging:` cap (added alongside this
# script) addresses the generation side; this script is the enforcement point on the consumption
# side: a hard stop BEFORE a test run that would push things further, not a silent auto-cleanup --
# matching this project's preference for an explicit human decision over automatic action on
# anything that touches real state.
#
# Source this near the top of any script that creates load (load-tests/run.sh, the chaos/HA demo
# scripts, the Kafka debug-overlay scripts) -- it exits non-zero and prints exactly what to do
# before the calling script proceeds, rather than letting a test run start and fail partway through
# once disk is gone.
#
# Usage: source scripts/check-disk-headroom.sh   (exits the CALLING script on hard-stop, via `exit`
#                                                  -- this file is meant to be sourced, not executed
#                                                  standalone, though running it directly also works
#                                                  as a manual check)
#
# Thresholds (override via env if a specific run genuinely needs different numbers):
#   DISK_HEADROOM_WARN_GB  - below this, print a warning but continue (default 30)
#   DISK_HEADROOM_STOP_GB  - below this, refuse to proceed (default 15)
WARN_GB="${DISK_HEADROOM_WARN_GB:-30}"
STOP_GB="${DISK_HEADROOM_STOP_GB:-15}"

AVAIL_GB=$(df -g /System/Volumes/Data 2>/dev/null | awk 'NR==2 {print $4}')
if [ -z "$AVAIL_GB" ]; then
  echo "check-disk-headroom.sh: could not read free disk space -- not blocking, but this check is not working." >&2
  return 0 2>/dev/null || exit 0
fi

if [ "$AVAIL_GB" -lt "$STOP_GB" ]; then
  echo "================================================================" >&2
  echo "DISK HEADROOM CHECK FAILED: ${AVAIL_GB}GB free, below the ${STOP_GB}GB hard-stop threshold." >&2
  echo "================================================================" >&2
  echo "Refusing to start a test/experiment run that would add more container/log growth on top of" >&2
  echo "this. This is the repeated pattern from several past sessions -- resolve it now, not after" >&2
  echo "something fails partway through and forces a reboot." >&2
  echo >&2
  echo "Current Docker usage breakdown:" >&2
  docker system df 2>&1 >&2
  echo >&2
  echo "Recommended first step (safe -- only removes stopped containers, dangling images, and build" >&2
  echo "cache; never touches named volumes like postgres-data/grafana-data or running containers):" >&2
  echo "  docker system prune -f" >&2
  echo >&2
  echo "If that isn't enough, check Docker.raw's actual on-disk size (it can be far larger than" >&2
  echo "\`docker system df\` suggests until a prune triggers a VM-disk compaction):" >&2
  echo "  du -sh ~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw" >&2
  echo >&2
  echo "Override for this run only (not recommended as a habit): DISK_HEADROOM_STOP_GB=<n> before" >&2
  echo "the command that sources this script." >&2
  return 1 2>/dev/null || exit 1
elif [ "$AVAIL_GB" -lt "$WARN_GB" ]; then
  echo "check-disk-headroom.sh: WARNING -- ${AVAIL_GB}GB free (below the ${WARN_GB}GB warn threshold," >&2
  echo "above the ${STOP_GB}GB hard-stop). Proceeding, but consider a 'docker system prune -f' soon." >&2
fi

return 0 2>/dev/null || exit 0
