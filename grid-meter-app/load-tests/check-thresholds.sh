#!/usr/bin/env bash
# Checks a JMeter HTML dashboard report's statistics.json against the coarse load-test gates from
# docs/testing-strategy.md: error rate < 1%, a p95 latency ceiling. Deliberately outside JMeter
# itself (not a Backend Listener) — a small script reading the aggregate report keeps the gate
# simple and independently testable, matching the doc's own framing that these gates are a blunt
# trip-wire, not a substitute for a human watching Grafana during the run.
#
# JMeter's default percentile mapping is pct1=90th, pct2=95th, pct3=99th (aggregate_rpt_pct1/2/3
# in jmeter.properties) — Total.pct2ResTime below IS the p95, not a guess.
#
# Usage: load-tests/check-thresholds.sh <statistics.json> [max-error-pct] [p95-ceiling-ms]
set -euo pipefail

STATS_FILE="${1:?Usage: $0 <statistics.json> [max-error-pct] [p95-ceiling-ms]}"
MAX_ERROR_PCT="${2:-1}"
P95_CEILING_MS="${3:-500}"

ERROR_PCT=$(jq -r '.Total.errorPct' "$STATS_FILE")
P95_MS=$(jq -r '.Total.pct2ResTime' "$STATS_FILE")
SAMPLE_COUNT=$(jq -r '.Total.sampleCount' "$STATS_FILE")

echo "Samples: $SAMPLE_COUNT | Error rate: ${ERROR_PCT}% | p95: ${P95_MS}ms"

FAILURES=0

if awk -v a="$ERROR_PCT" -v b="$MAX_ERROR_PCT" 'BEGIN { exit !(a >= b) }'; then
  echo "FAIL: error rate ${ERROR_PCT}% >= ${MAX_ERROR_PCT}% threshold" >&2
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: error rate ${ERROR_PCT}% < ${MAX_ERROR_PCT}% threshold"
fi

if awk -v a="$P95_MS" -v b="$P95_CEILING_MS" 'BEGIN { exit !(a >= b) }'; then
  echo "FAIL: p95 ${P95_MS}ms >= ${P95_CEILING_MS}ms ceiling" >&2
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: p95 ${P95_MS}ms < ${P95_CEILING_MS}ms ceiling"
fi

if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES gate(s) failed." >&2
  exit 1
fi
echo "All gates passed."
