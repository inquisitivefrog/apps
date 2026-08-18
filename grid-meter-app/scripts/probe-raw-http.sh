#!/usr/bin/env bash
# Sends a raw HTTP request directly over a socket, bypassing any HTTP client library, to isolate
# whether a connection problem is server/network-side or specific to some client's HTTP stack.
# Runs RawHttpProbe.java directly via the JDK's single-file source-launch mode (Java 11+) — no
# separate compile step needed.
#
# Usage: scripts/probe-raw-http.sh <host> <port> <method> <path> [json-body]
# Example: scripts/probe-raw-http.sh localhost 80 POST /api/v1/auth/login \
#            '{"username":"demo","password":"GridMeter!Demo2026"}'
set -euo pipefail
cd "$(dirname "$0")"
java RawHttpProbe.java "$@"
