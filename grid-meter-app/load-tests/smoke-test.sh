#!/usr/bin/env bash
# Runs all five profiles with small/fast overrides (few threads, short duration, small meter
# pool) as a quick regression check that every .jmx still works end to end — not a real load test,
# just "did I break something" after editing a fragment or profile. Requires the stack up (see
# README.md's Prerequisites). This is the loop that got run by hand repeatedly while building
# load-tests/ in the first place, bundled here instead of retyping it each time.
#
# Usage: load-tests/smoke-test.sh
set -uo pipefail
cd "$(dirname "$0")"

PROFILES=(steady-state ramp-up rapid-spike gentle-spike soak)
FAILURES=0

for profile in "${PROFILES[@]}"; do
  echo
  echo "=== $profile ==="
  if ./run.sh "$profile" -Jthreads=5 -JrampUp=1 -Jduration=4 -JthinkTimeMs=50 -JmeterPoolSize=3; then
    echo "PASS: $profile"
  else
    echo "FAIL: $profile" >&2
    FAILURES=$((FAILURES + 1))
  fi
done

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All 5 profiles passed."
else
  echo "$FAILURES profile(s) failed." >&2
  exit 1
fi
