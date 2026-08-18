#!/usr/bin/env bash
# Sends a request via the JDK's built-in java.net.http.HttpClient (JdkHttpClientProbe.java),
# using the JDK's single-file source-launch mode — no separate compile step needed. See
# RawHttpProbe.java / probe-raw-http.sh for the raw-socket counterpart.
#
# Usage: scripts/probe-jdk-http-client.sh <url> [POST-json-body]
# Example: scripts/probe-jdk-http-client.sh http://localhost/api/v1/auth/login \
#            '{"username":"demo","password":"GridMeter!Demo2026"}'
set -euo pipefail
cd "$(dirname "$0")"
java JdkHttpClientProbe.java "$@"
