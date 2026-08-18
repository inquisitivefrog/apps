#!/usr/bin/env bash
# Captures loopback:80 traffic via tcpdump while running one known-working probe
# (probe-apache-http-client.sh) and one known-failing probe (probe-restassured-minimal.sh) back to
# back, so the two can be diffed byte-for-byte to find what REST Assured's Groovy HTTPBuilder layer
# sends differently. Needs sudo (tcpdump requires elevated privileges to capture packets even on
# loopback) — run this directly in a real terminal (or via Claude Code's `!` prefix), not through
# an automated tool, since sudo needs an interactive password prompt.
#
# Usage: scripts/capture-connection-reset.sh [pcap-output-file]
set -euo pipefail
cd "$(dirname "$0")"

PCAP_FILE="${1:-/tmp/grid-meter-connection-reset.pcap}"
LOGIN_URL="http://localhost/api/v1/auth/login"
LOGIN_BODY='{"username":"demo","password":"GridMeter!Demo2026"}'

echo "Capturing to $PCAP_FILE — this needs sudo. No port filter, so any port/protocol shows up."
sudo tcpdump -i lo0 -w "$PCAP_FILE" &
TCPDUMP_PID=$!
sleep 2

echo
echo "[$(date +%H:%M:%S.%3N)] === Running WORKING probe (raw Apache HttpClient, expect-continue=false) ==="
./probe-apache-http-client.sh "$LOGIN_URL" false "$LOGIN_BODY" || true
echo "[$(date +%H:%M:%S.%3N)] working probe done"

sleep 2

echo
echo "[$(date +%H:%M:%S.%3N)] === Running FAILING probe (bare REST Assured) ==="
./probe-restassured-minimal.sh "$LOGIN_URL" "$LOGIN_BODY" || true
echo "[$(date +%H:%M:%S.%3N)] failing probe done"

sleep 2
sudo kill "$TCPDUMP_PID" 2>/dev/null || true
wait "$TCPDUMP_PID" 2>/dev/null || true

echo
echo "Capture complete: $PCAP_FILE"
echo "Read the full ASCII dump with: sudo tcpdump -r $PCAP_FILE -A -n"
echo "(Look for two separate TCP streams/ports — one per probe — and diff their request bytes.)"
