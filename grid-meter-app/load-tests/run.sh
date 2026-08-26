#!/usr/bin/env bash
# Runs one load-test profile (non-GUI mode) against a running docker compose stack and generates
# the HTML dashboard report. JMeter must be on PATH (brew install jmeter locally; pinned version
# 5.6.3 — see docs/tech-stack-versions.md). Requires traefik/api/postgres/kafka/redis already up
# (docker compose up), same as scripts/run-black-box-api-tests.sh in the api/ test tier.
#
# Usage: load-tests/run.sh <steady-state|ramp-up|rapid-spike|gentle-spike|soak> [-Jname=value ...]
# Example: load-tests/run.sh rapid-spike -Jduration=15   (shorten a real run for a quick local check)
#
# After the run, checks the result against check-thresholds.sh's coarse gates (error rate < 1%,
# p95 latency ceiling) and exits non-zero if either is breached — see docs/testing-strategy.md for
# why these gates are intentionally coarse (a human watching Grafana during the run is the real
# signal, not this pass/fail check).
set -euo pipefail
cd "$(dirname "$0")"

PROFILE="${1:-}"
case "$PROFILE" in
  steady-state|ramp-up|rapid-spike|gentle-spike|soak) ;;
  *)
    echo "Usage: $0 <steady-state|ramp-up|rapid-spike|gentle-spike|soak> [-Jname=value ...]" >&2
    exit 1
    ;;
esac
shift

RUN_DIR="results/${PROFILE}-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN_DIR"

echo "Running '$PROFILE' — results in $RUN_DIR"
jmeter -n -t "${PROFILE}.jmx" -q config/load-test.properties \
  -l "$RUN_DIR/results.jtl" -e -o "$RUN_DIR/report" \
  -j "$RUN_DIR/jmeter.log" "$@"

echo
./check-thresholds.sh "$RUN_DIR/report/statistics.json"
