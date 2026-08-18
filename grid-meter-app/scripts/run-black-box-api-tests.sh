#!/usr/bin/env bash
# Brings up the data/edge tier via Docker Compose, waits for the API to report healthy through
# Traefik, then runs the Failsafe-bound black-box API test suite (*ApiIT classes, see
# api/src/test/java/com/gridmeter/api/{meter,reading}) against the real deployed stack rather than
# an embedded server. Mirrors the "frontend-black-box-test" CI job in
# .github/workflows/grid-meter-app-ci.yml — see docs/testing-strategy.md for why this tier exists
# alongside the embedded *ApiComponentTest tier that runs on every push.
#
# Does NOT tear the stack down afterward — local dev convenience, so a failure can be poked at
# with curl/docker logs. Run `docker compose down` manually when done. CI's job does its own
# teardown in an `if: always()` step.
#
# Usage: scripts/run-black-box-api-tests.sh
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose up -d --build traefik api postgres kafka redis
./scripts/wait-for-health.sh "http://localhost/actuator/health" 90


# -DskipTests skips BOTH Surefire and Failsafe (they share that property by design — see
# maven-failsafe-plugin's own docs, which call this out as "a source of conflicts"). To run only
# the Failsafe-bound *ApiIT classes, invoke its goals directly instead of going through the
# `verify` lifecycle phase (which would also trigger Surefire's `test` phase).
API_BASE_URL="http://localhost/api/v1" mvn -B -f api/pom.xml test-compile failsafe:integration-test failsafe:verify
