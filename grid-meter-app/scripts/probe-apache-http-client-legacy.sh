#!/usr/bin/env bash
# Sends a request via Apache HttpClient's legacy DefaultHttpClient execution path
# (ApacheHttpClientLegacyProbe.java) — the code path REST Assured's Groovy HTTPBuilder layer
# actually uses internally, as opposed to probe-apache-http-client.sh's modern HttpClients.custom()
# builder. Requires the api module's test classpath; build it first with
# scripts/build-test-classpath.sh.
#
# Usage: scripts/probe-apache-http-client-legacy.sh <url> <expect-continue:true|false> [POST-json-body] [classpath-file]
# Example: scripts/probe-apache-http-client-legacy.sh http://localhost/api/v1/auth/login false \
#            '{"username":"demo","password":"GridMeter!Demo2026"}'
set -euo pipefail
cd "$(dirname "$0")"

CLASSPATH_FILE="${4:-/tmp/grid-meter-api-test-classpath.txt}"
if [ ! -f "$CLASSPATH_FILE" ]; then
  echo "Classpath file not found: $CLASSPATH_FILE" >&2
  echo "Run scripts/build-test-classpath.sh first (optionally passing the same path as arg 4 here)." >&2
  exit 1
fi

java --class-path "$(cat "$CLASSPATH_FILE")" ApacheHttpClientLegacyProbe.java "$1" "$2" "${3:-}"
