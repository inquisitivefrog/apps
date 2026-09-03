#!/usr/bin/env bash
# Guards against a real, confirmed contamination pattern (found 2026-09-03, isolating
# docs/redis-ha-scope.md's Lettuce/Kafka-retry hypothesis): a leftover background script from
# earlier in the same session (_tmp-oldcode-negctrl.sh, a scratch negative-control harness) kept
# running unattended for over 5 hours, continuously hitting the API with a since-expired token --
# and its 401 flood was silently mixed into the next test's own measurement window until the
# source was tracked down by hand. A full `docker compose down/up` bounce would NOT have caught
# this -- the contamination was a stray HOST process, not stale container state -- so this is a
# pre-flight HOST hygiene check, not a container reset. Same "hard stop before a measurement run
# that would be silently corrupted, not a silent auto-cleanup" philosophy as
# check-disk-headroom.sh, which this file otherwise mirrors.
#
# Source this near the top of any script whose result depends on counting/timing real requests
# against the live api service (an app-level chaos/failover test, a load-test profile) -- right
# alongside `source scripts/check-disk-headroom.sh`, not as a replacement for it. Scripts that
# never generate or measure real app traffic (most infra-only chaos scripts -- Consul/Patroni/
# Kafka-broker-only tests) don't need this.
#
# Usage: source scripts/check-no-stray-traffic.sh   (exits the CALLING script on hard-stop, via
#                                                      `exit` -- meant to be sourced, though running
#                                                      it directly also works as a manual check)
#
# Tunables (override via env if a specific run genuinely needs different numbers):
#   STRAY_TRAFFIC_WINDOW_S - how many recent seconds of api logs to sample (default 5)
STRAY_WINDOW="${STRAY_TRAFFIC_WINDOW_S:-5}"

# Real app-level traffic only -- deliberately excludes /actuator/health and /actuator/prometheus,
# which Traefik's healthcheck and Prometheus's scraper legitimately hit on their own schedule
# regardless of what test is or isn't running, and would otherwise make this check permanently
# unable to find a quiet baseline.
STRAY_COUNT=$(docker compose logs api --since "${STRAY_WINDOW}s" 2>&1 \
  | grep -cE '"(POST|GET|PUT|DELETE) /api/v1/' || true)

if [ "${STRAY_COUNT:-0}" -gt 0 ]; then
  echo "================================================================" >&2
  echo "STRAY TRAFFIC CHECK FAILED: ${STRAY_COUNT} /api/v1/* request(s) hit the api service in the" >&2
  echo "last ${STRAY_WINDOW}s, before this test's own traffic has even started." >&2
  echo "================================================================" >&2
  echo "This is the exact contamination shape found 2026-09-03: a leftover background script from" >&2
  echo "an earlier, unrelated test run left silently hammering the API, mixing its traffic into this" >&2
  echo "run's own request/success counts and timing measurements with no visible sign until someone" >&2
  echo "diffs the numbers against api's own access log by hand. Refusing to start a measurement run" >&2
  echo "on top of that rather than producing a result that looks clean but isn't." >&2
  echo >&2
  echo "Recent /api/v1/* traffic (who's actually hitting this):" >&2
  docker compose logs api --since "${STRAY_WINDOW}s" 2>&1 | grep -E '"(POST|GET|PUT|DELETE) /api/v1/' | tail -5 >&2
  echo >&2
  echo "Likely source: a stray host-side script, not stale container state -- a compose bounce will" >&2
  echo "NOT fix this. Check for leftover background processes first:" >&2
  echo "  ps aux | grep -E 'bash (load-tests|scripts)/|_tmp-'" >&2
  echo "Kill the exact PID once identified (never a broad pattern-matched kill):" >&2
  echo "  kill <pid>" >&2
  echo >&2
  echo "Then re-run this check on its own before retrying the real test:" >&2
  echo "  source scripts/check-no-stray-traffic.sh" >&2
  echo >&2
  echo "Override for this run only (not recommended as a habit -- widens the sample window, doesn't" >&2
  echo "suppress the check): STRAY_TRAFFIC_WINDOW_S=<n> before the command that sources this script." >&2
  return 1 2>/dev/null || exit 1
fi

return 0 2>/dev/null || exit 0
