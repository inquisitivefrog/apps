#!/usr/bin/env bash
# Logs host-level and per-container resource usage at intervals, so a load-tests/ run has a
# reviewable record confirming it didn't overrun the machine, not just an assumption. Runs until
# killed (SIGTERM/SIGINT) -- intended to be started in the background alongside a real run and
# stopped when it finishes.
#
# Usage: load-tests/monitor-resources.sh <output-file> [interval-seconds]
#   load-tests/monitor-resources.sh /path/to/resource-log.txt 10 &
#   MONITOR_PID=$!
#   ... run the actual load ...
#   kill "$MONITOR_PID"
set -uo pipefail

OUTPUT="${1:?Usage: $0 <output-file> [interval-seconds]}"
INTERVAL="${2:-10}"

trap 'exit 0' TERM INT

while true; do
  {
    echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
    echo "-- host memory (macOS memory_pressure) --"
    memory_pressure 2>/dev/null | grep -E "free percentage|Swapins|Swapouts" || echo "memory_pressure unavailable"
    echo "-- host load average --"
    uptime
    echo "-- per-container memory/CPU (docker stats) --"
    docker stats --no-stream --format "{{.Name}}: {{.MemUsage}} | {{.CPUPerc}}" 2>/dev/null || echo "docker stats unavailable"
    echo
  } >> "$OUTPUT"
  sleep "$INTERVAL"
done
