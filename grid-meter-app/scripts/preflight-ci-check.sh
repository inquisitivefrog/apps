#!/usr/bin/env bash
# Pre-flight guard for the self-hosted E2E CI job (.github/workflows/grid-meter-app-e2e.yml).
# This runner is this Mac -- the same machine used for everything else, not a disposable
# GitHub-hosted VM -- so a job that assumes Docker is running and its ports are free can fail
# confusingly mid-run (or worse, silently collide with whatever's already there) if the Mac is
# busy with something else when a push triggers the job. Same "hard stop with a clear message
# before proceeding" pattern as check-disk-headroom.sh, applied to Docker/port availability
# instead of disk space.
#
# Usage: source scripts/preflight-ci-check.sh   (exits the CALLING script via `exit` on failure)
#        or run directly as a standalone check.
set -uo pipefail

REQUIRED_PORTS=(80 8080 55432 3001 8500)

if ! docker info >/dev/null 2>&1; then
  echo "================================================================" >&2
  echo "PRE-FLIGHT CHECK FAILED: Docker daemon is not running." >&2
  echo "================================================================" >&2
  echo "This is a self-hosted runner on a Mac that isn't dedicated CI infrastructure --" >&2
  echo "Docker Desktop needs to be running for this job to bring up the stack. Start it and" >&2
  echo "re-run this job, rather than letting docker compose fail with a confusing error deep" >&2
  echo "into the workflow." >&2
  return 1 2>/dev/null || exit 1
fi

conflicts=()
for port in "${REQUIRED_PORTS[@]}"; do
  listener=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $1, $2}')
  if [ -n "$listener" ]; then
    conflicts+=("port ${port}: ${listener}")
  fi
done

if [ "${#conflicts[@]}" -gt 0 ]; then
  echo "================================================================" >&2
  echo "PRE-FLIGHT CHECK FAILED: required port(s) already in use." >&2
  echo "================================================================" >&2
  echo "This job needs ports 80/8080/55432/3001/8500 free to bring up its own stack. Something" >&2
  echo "is already listening on at least one of them -- either a stack from a prior run that" >&2
  echo "didn't tear down cleanly, or unrelated work on this Mac. Bailing out cleanly now rather" >&2
  echo "than starting a run that would collide partway through." >&2
  echo >&2
  echo "Conflicts found:" >&2
  for c in "${conflicts[@]}"; do
    echo "  - $c" >&2
  done
  echo >&2
  echo "If this is a stale stack from a prior run, from the grid-meter-app directory:" >&2
  echo "  docker compose down -v" >&2
  return 1 2>/dev/null || exit 1
fi

echo "preflight-ci-check.sh: Docker is running and all required ports are free. Proceeding."
return 0 2>/dev/null || exit 0
