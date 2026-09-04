#!/usr/bin/env bash
# Brings up the data/edge tier via Docker Compose, waits for the API to report healthy through
# Traefik, then runs the Failsafe-bound black-box API test suite (*ApiIT classes, see
# api/src/test/java/com/gridmeter/api/{meter,reading}) against the real deployed stack rather than
# an embedded server. This is the script the "black-box-api-test" CI job in
# .github/workflows/grid-meter-app-ci.yml runs directly — see docs/testing-strategy.md for why
# this tier exists alongside the embedded *ApiComponentTest tier that runs on every push.
#
# Does NOT tear the stack down afterward — local dev convenience, so a failure can be poked at
# with curl/docker logs. Run `docker compose down` manually when done. CI's job does its own
# teardown in an `if: always()` step.
#
# Usage: scripts/run-black-box-api-tests.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# No standalone `postgres` here -- that service was retired after docs/postgres-ha-scope.md's
# Stage 7 cutover (see docker-compose.yml's comment at the old postgres service's former
# location). `api` itself depends_on patroni-1/2/3, postgres-primary-registrar, and the
# sentinels, so listing it below already brings up the full Patroni/Consul/registrar chain
# Traefik's :55432 entrypoint needs -- no need to hand-duplicate that dependency list here.
docker compose up -d --build traefik api kafka-1 kafka-2 kafka-3 redis
./scripts/wait-for-health.sh "http://localhost/actuator/health" 90


# -DskipTests skips BOTH Surefire and Failsafe (they share that property by design — see
# maven-failsafe-plugin's own docs, which call this out as "a source of conflicts"). To run only
# the Failsafe-bound *ApiIT classes, invoke its goals directly instead of going through the
# `verify` lifecycle phase (which would also trigger Surefire's `test` phase).
API_BASE_URL="http://localhost/api/v1" mvn -B -f api/pom.xml test-compile failsafe:integration-test failsafe:verify
