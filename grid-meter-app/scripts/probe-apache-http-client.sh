#!/usr/bin/env bash
# Sends a request via Apache HttpClient 4.5.13 directly (ApacheHttpClientProbe.java) — the same
# library/version REST Assured bundles internally — using JDK 25's single-file source-launch mode,
# no separate compile step. Requires the api module's test classpath; build it first with
# scripts/build-test-classpath.sh. See RawHttpProbe.java / probe-raw-http.sh and
# JdkHttpClientProbe.java / probe-jdk-http-client.sh for the other two probes in this investigation.
#
# Usage: scripts/probe-apache-http-client.sh <url> <expect-continue:true|false> [POST-json-body] [classpath-file]
# Example: scripts/probe-apache-http-client.sh http://localhost/api/v1/auth/login false \
#            '{"username":"demo","password":"GridMeter!Demo2026"}'
#
# Set CHUNKED=1 to send the POST body as chunked transfer-encoding instead of fixed-length.
set -euo pipefail
cd "$(dirname "$0")"

CLASSPATH_FILE="${4:-/tmp/grid-meter-api-test-classpath.txt}"
if [ ! -f "$CLASSPATH_FILE" ]; then
  echo "Classpath file not found: $CLASSPATH_FILE" >&2
  echo "Run scripts/build-test-classpath.sh first (optionally passing the same path as arg 4 here)." >&2
  exit 1
fi

CHUNKED_OPT=()
if [ "${CHUNKED:-0}" = "1" ]; then
  CHUNKED_OPT=(-Dprobe.chunked=true)
fi

java "${CHUNKED_OPT[@]}" --class-path "$(cat "$CLASSPATH_FILE")" ApacheHttpClientProbe.java "$1" "$2" "${3:-}"
