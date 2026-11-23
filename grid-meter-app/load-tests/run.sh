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

usage() {
  cat <<'USAGE'
Usage: ./run.sh <profile> [-Jname=value ...]

Profiles (default threads; users = distinct logged-in users the dashboards will show):
  steady-state   sustained baseline         20 threads, 5 min     users: 20
  ramp-up        gradually increasing load  150 threads           users: 100
  rapid-spike    sudden burst               600 threads           users: 100
  gentle-spike   slower burst, 1 replica    600 threads           users: 100
  soak           sustained, 1 hour          35 threads            users: 35

Threads act as users loadtest-001..100, wrapping around: with 600 threads, each user has 6
concurrent sessions sharing one login. Each user logs in once, whatever the thread count.

Common overrides:
  -Jthreads=N    concurrent threads (users = the smaller of threads and LOAD_TEST_USERS)
  -Jduration=S   run length in seconds, e.g. -Jduration=60 for a quick check
  -JrampUp=S     seconds to start all threads (spreads out the logins)
  -Jbackoff429Ms=MS  pause after a 429 from the edge (default 1000; 0 = retry storm)

Before each run: Redis idempotency keys from earlier runs are cleared, and users are seeded
(LOAD_TEST_USERS=200 for more, max 999). Separately: ./clear-idempotency-keys.sh,
./seed-users.sh [count]

Examples:
  ./run.sh steady-state                                 # 20 users, 5 minutes
  ./run.sh steady-state -Jthreads=100 -JrampUp=30       # 100 users
  ./run.sh rapid-spike -Jduration=60                    # shortened spike
  LOAD_TEST_USERS=10 ./run.sh rapid-spike               # 600 threads as just 10 users
USAGE
}

PROFILE="${1:-}"
case "$PROFILE" in
  steady-state|ramp-up|rapid-spike|gentle-spike|soak) ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    [ -n "$PROFILE" ] && echo "Unknown profile: $PROFILE" >&2 && echo >&2
    usage >&2
    exit 1
    ;;
esac
shift

# Checked after argument parsing so --help and typos don't print a disk warning first.
# Load tests are exactly the kind of run that has repeatedly pushed Docker's disk usage over the
# edge (see scripts/check-disk-headroom.sh for the full mechanism) -- check headroom before adding
# more container log volume on top of whatever's already there.
source ../scripts/check-disk-headroom.sh

RUN_DIR="results/${PROFILE}-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN_DIR"

# Every run starts from a clean state: idempotency keys left by earlier runs (24h TTL) otherwise
# accumulate in Redis until a later run fails for reasons unrelated to its own load.
./clear-idempotency-keys.sh

# Profiles that include common/user-login.jmx run their threads as loadtest-NNN users (wrapping
# around after LOAD_TEST_USERS, default 100), so those users must exist first.
USER_ARGS=()
if grep -q "common/user-login.jmx" "${PROFILE}.jmx"; then
  ./seed-users.sh "${LOAD_TEST_USERS:-100}"
  USER_ARGS=(-JloadTestUsers="${LOAD_TEST_USERS:-100}")
fi

echo "Running '$PROFILE' — results in $RUN_DIR"
jmeter -n -t "${PROFILE}.jmx" -q config/load-test.properties \
  -l "$RUN_DIR/results.jtl" -e -o "$RUN_DIR/report" \
  -j "$RUN_DIR/jmeter.log" ${USER_ARGS[@]+"${USER_ARGS[@]}"} "$@"

echo
./check-thresholds.sh "$RUN_DIR/report/statistics.json"
