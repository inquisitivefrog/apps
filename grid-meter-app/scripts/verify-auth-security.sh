#!/usr/bin/env bash
# Ad hoc curl-based smoke check for the auth/security behaviors this repo cares about most:
# unauthenticated/invalid-token rejection, actuator staying open, and PUT /readings/{id} being
# rejected (readings are immutable — see docs/api-and-data-model.md). The real, CI-gated source of
# truth for this behavior is the REST Assured suite (api/src/test/java/com/gridmeter/api/auth/
# ApiSecurityComponentTest.java and reading/ReadingApiTestBase.java's putReading_isRejectedWith405)
# run via `mvn test`. This script exists only so a quick manual check against a running
# `docker compose up` stack doesn't mean retyping a compound curl chain inline each time.
#
# Usage: scripts/verify-auth-security.sh [base-url]
#   base-url defaults to http://localhost (Traefik), matching local `docker compose up`.
set -uo pipefail

BASE="${1:-http://localhost}"
API="$BASE/api/v1"
FAILURES=0

check() {
  local description="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    echo "PASS: $description (got $actual)"
  else
    echo "FAIL: $description (expected $expected, got $actual)" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

status=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/actuator/health")
check "actuator/health has no auth required" 200 "$status"

status=$(curl -s -o /dev/null -w '%{http_code}' "$API/meters")
check "unauthenticated request to protected endpoint" 401 "$status"

status=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer garbage" "$API/meters")
check "invalid token on protected endpoint" 401 "$status"

login_response=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"GridMeter!Demo2026"}')
token=$(echo "$login_response" | grep -o '"accessToken"[^,}]*' | sed 's/.*:"//;s/"$//')
if [ -n "$token" ]; then
  echo "PASS: login returns an access token"
else
  echo "FAIL: login did not return an access token (response: $login_response)" >&2
  FAILURES=$((FAILURES + 1))
fi

status=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $token" "$API/meters")
check "authenticated request to protected endpoint" 200 "$status"

fake_id="00000000-0000-0000-0000-000000000000"
status=$(curl -s -o /dev/null -w '%{http_code}' -X PUT -H "Authorization: Bearer $token" "$API/readings/$fake_id")
check "PUT /readings/{id} is rejected (readings are immutable)" 405 "$status"

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$FAILURES check(s) failed." >&2
  exit 1
fi
