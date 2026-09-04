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
#
# DURABILITY WARNING (2026-09-04), unrelated to what this script actually checks below, but
# recorded here since it's the other half of a gotcha discovered alongside this script and
# nothing in the repo alone would surface it: the E2E workflow's `docker compose up --build`
# only works on this runner because (a) its DOCKER_CONFIG env var (set in
# .github/workflows/grid-meter-app-e2e.yml) points Docker at a credsStore-free config, since
# this runner's launchd service can't unlock the macOS keychain Docker Desktop's default
# credential helper needs -- even for anonymous pulls of public images -- and (b) every base
# image this project uses is already pulled into this Mac's local Docker cache, since buildkit
# only skips that keychain-dependent credential check for images it doesn't need to hit the
# registry for. Neither survives a runner rebuild: a fresh `./svc.sh install` regenerates the
# launchd plist without (a) (it has to be re-added to the workflow's env, which it already is --
# but if this script or a future one moves to a different runner/plist setup, re-check this), and
# `docker system prune -a` evicts (b). If CI ever starts failing on "Bring up a clean stack" with
# a keychain error again, re-pull these before assuming it's a new bug:
#   maven:3.9-eclipse-temurin-25  eclipse-temurin:25-jre-alpine  node:24-alpine
#   nginx:1.27-alpine  postgres:18.4  traefik:v3.7.10  hashicorp/consul:1.20.1
#   curlimages/curl:8.11.1  redis:8.10  apache/kafka:4.3.1  prom/prometheus:v3.11.2
#   grafana/loki:3.7.6  grafana/tempo:2.10.0  grafana/grafana:13.0.2  grafana/alloy:v1.18.1
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

# On macOS, Docker Desktop proxies every published container port through its own process
# (lsof shows "com.docke... " for ANY published port, regardless of which container it belongs
# to) -- so raw lsof output alone never actually identifies what's occupying a port, only that
# something Docker-shaped is. Cross-referencing against `docker ps` (which does know the real
# container-to-port mapping) turns "port 80 in use" into "port 80 in use by
# grid-meter-app-traefik-1, Up 3 hours" -- immediately diagnosable as a stale leftover (safe to
# kill) vs. a container that just started (likely a concurrently-running job, don't touch it).
find_port_owner() {
  docker ps --format '{{.Names}}\t{{.Ports}}\t{{.Status}}' 2>/dev/null \
    | awk -F'\t' -v p=":${1}->" '$2 ~ p {print $1 " (" $3 ")"; exit}'
}

conflicts=()
for port in "${REQUIRED_PORTS[@]}"; do
  listener=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $1, $2}')
  if [ -n "$listener" ]; then
    owner=$(find_port_owner "$port")
    if [ -n "$owner" ]; then
      conflicts+=("port ${port}: container ${owner}")
    else
      conflicts+=("port ${port}: ${listener} -- no matching container found; likely a non-Docker process, not a leftover stack")
    fi
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
