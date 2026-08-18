#!/usr/bin/env bash
# Sends a request via bare REST Assured (RestAssuredMinimalProbe.java) — no Spring, no Awaitility,
# no shared test base class — to check whether the "Connection reset" originates in REST Assured's
# Groovy HTTPBuilder layer itself, now that both of Apache HttpClient's execution paths
# (probe-apache-http-client.sh, probe-apache-http-client-legacy.sh) have been ruled out. Requires
# the api module's test classpath; build it first with scripts/build-test-classpath.sh.
#
# Usage: scripts/probe-restassured-minimal.sh <url> [POST-json-body] [classpath-file]
# Example: scripts/probe-restassured-minimal.sh http://localhost/api/v1/auth/login \
#            '{"username":"demo","password":"GridMeter!Demo2026"}'
#
# Set WIRE_DEBUG=1 to enable Apache HttpClient wire-level logging (every byte sent/received) via
# commons-logging's SimpleLog. Run as a plain `java` process (not through Maven/Failsafe), these
# system properties actually take effect — unlike passing them via Failsafe's argLine, which did
# not produce any output when tried earlier in this investigation.
set -euo pipefail
cd "$(dirname "$0")"

CLASSPATH_FILE="${3:-/tmp/grid-meter-api-test-classpath.txt}"
if [ ! -f "$CLASSPATH_FILE" ]; then
  echo "Classpath file not found: $CLASSPATH_FILE" >&2
  echo "Run scripts/build-test-classpath.sh first (optionally passing the same path as arg 3 here)." >&2
  exit 1
fi

DEBUG_OPTS=()
if [ "${WIRE_DEBUG:-0}" = "1" ]; then
  DEBUG_OPTS=(
    -Dorg.apache.commons.logging.Log=org.apache.commons.logging.impl.SimpleLog
    -Dorg.apache.commons.logging.simplelog.showdatetime=true
    -Dorg.apache.commons.logging.simplelog.log.org.apache.http=DEBUG
    -Dorg.apache.commons.logging.simplelog.log.org.apache.http.wire=DEBUG
  )
fi

java "${DEBUG_OPTS[@]}" --class-path "$(cat "$CLASSPATH_FILE")" RestAssuredMinimalProbe.java "$1" "${2:-}"
