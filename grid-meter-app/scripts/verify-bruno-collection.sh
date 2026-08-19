#!/usr/bin/env bash
# Replays the same request sequence as api/bruno/ (auth -> meters -> readings -> ops) via curl,
# to confirm the collection's requests/assertions still match real API behavior after being
# authored. The Bruno collection itself is for a human to run interactively in the Bruno app;
# this script exists so that check can also be done headlessly (no `bru` CLI is installed here)
# against a running `docker compose up` stack. Not part of CI — REST Assured is what gates that.
#
# Usage: scripts/verify-bruno-collection.sh [base-url]
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

extract_json_field() {
  # crude but dependency-free: extract "field":"value" or "field":value from a JSON blob
  local json="$1" field="$2"
  echo "$json" | grep -o "\"$field\"[^,}]*" | head -1 | sed 's/.*:[[:space:]]*"\{0,1\}//;s/"$//'
}

# --- ops/Health ---
status=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/actuator/health")
check "ops/Health: 200, no auth" 200 "$status"

# --- ops/Prometheus Metrics ---
status=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/actuator/prometheus")
check "ops/Prometheus Metrics: 200, no auth" 200 "$status"

# --- auth/Login ---
login_response=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"GridMeter!Demo2026"}')
token=$(extract_json_field "$login_response" accessToken)
if [ -n "$token" ]; then
  echo "PASS: auth/Login: 200, accessToken present"
else
  echo "FAIL: auth/Login did not return an accessToken (response: $login_response)" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- auth/Login - Invalid Credentials ---
status=$(curl -s -o /tmp/bruno-verify-invalid-login.json -w '%{http_code}' -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"wrong-password"}')
check "auth/Login Invalid Credentials: 401" 401 "$status"
msg=$(extract_json_field "$(cat /tmp/bruno-verify-invalid-login.json)" message)
check "auth/Login Invalid Credentials: anti-enumeration message" "Invalid username or password" "$msg"

# --- auth/Unauthenticated Request Rejected ---
status=$(curl -s -o /dev/null -w '%{http_code}' "$API/meters")
check "auth/Unauthenticated Request Rejected: 401" 401 "$status"

AUTH_HEADER=(-H "Authorization: Bearer $token")

# --- meters/Create Meter ---
serial="SN-$(date +%s)"
create_response=$(curl -s -X POST "$API/meters" "${AUTH_HEADER[@]}" \
  -H "Content-Type: application/json" \
  -d "{\"serialNumber\":\"$serial\",\"location\":\"123 Main St, Unit 4\",\"status\":\"ACTIVE\",\"installedAt\":\"2026-01-01T00:00:00Z\"}")
meter_id=$(extract_json_field "$create_response" id)
returned_serial=$(extract_json_field "$create_response" serialNumber)
if [ -n "$meter_id" ]; then
  echo "PASS: meters/Create Meter: 201, id present ($meter_id)"
else
  echo "FAIL: meters/Create Meter did not return an id (response: $create_response)" >&2
  FAILURES=$((FAILURES + 1))
fi
check "meters/Create Meter: serialNumber echoed" "$serial" "$returned_serial"

# --- meters/Search Meters ---
status=$(curl -s -o /dev/null -w '%{http_code}' "${AUTH_HEADER[@]}" "$API/meters?page=0&size=20")
check "meters/Search Meters: 200" 200 "$status"

# --- meters/Get Meter ---
get_response=$(curl -s "${AUTH_HEADER[@]}" "$API/meters/$meter_id")
returned_id=$(extract_json_field "$get_response" id)
check "meters/Get Meter: id matches" "$meter_id" "$returned_id"

# --- meters/Update Meter ---
update_response=$(curl -s -X PUT "$API/meters/$meter_id" "${AUTH_HEADER[@]}" \
  -H "Content-Type: application/json" \
  -d "{\"serialNumber\":\"$serial\",\"location\":\"456 Updated Ave\",\"status\":\"MAINTENANCE\",\"installedAt\":\"2026-01-01T00:00:00Z\"}")
updated_status=$(extract_json_field "$update_response" status)
check "meters/Update Meter: status updated" "MAINTENANCE" "$updated_status"

# --- readings/Ingest Reading ---
ingest_response=$(curl -s -X POST "$API/readings" "${AUTH_HEADER[@]}" \
  -H "Content-Type: application/json" \
  -d "{\"meterId\":\"$meter_id\",\"readingTimestamp\":\"2026-01-01T12:00:00Z\",\"value\":42.5}")
reading_id=$(extract_json_field "$ingest_response" id)
reading_meter_id=$(extract_json_field "$ingest_response" meterId)
if [ -n "$reading_id" ]; then
  echo "PASS: readings/Ingest Reading: 201, id present ($reading_id)"
else
  echo "FAIL: readings/Ingest Reading did not return an id (response: $ingest_response)" >&2
  FAILURES=$((FAILURES + 1))
fi
check "readings/Ingest Reading: meterId echoed" "$meter_id" "$reading_meter_id"

# --- readings/Search Readings ---
status=$(curl -s -o /dev/null -w '%{http_code}' "${AUTH_HEADER[@]}" "$API/readings?meterId=$meter_id&page=0&size=20")
check "readings/Search Readings: 200" 200 "$status"

# --- readings/Get Reading ---
get_reading_response=$(curl -s "${AUTH_HEADER[@]}" "$API/readings/$reading_id")
returned_reading_id=$(extract_json_field "$get_reading_response" id)
check "readings/Get Reading: id matches" "$reading_id" "$returned_reading_id"

# --- readings/Reject PUT Reading (405) ---
status=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/readings/$reading_id" "${AUTH_HEADER[@]}" \
  -H "Content-Type: application/json" \
  -d "{\"meterId\":\"$meter_id\",\"readingTimestamp\":\"2026-01-01T12:00:00Z\",\"value\":999.9}")
check "readings/Reject PUT Reading: 405 (immutable)" 405 "$status"

# --- readings/Delete Reading ---
status=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$API/readings/$reading_id" "${AUTH_HEADER[@]}")
check "readings/Delete Reading: 204" 204 "$status"

# --- meters/Delete Meter ---
status=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$API/meters/$meter_id" "${AUTH_HEADER[@]}")
check "meters/Delete Meter: 204" 204 "$status"

rm -f /tmp/bruno-verify-invalid-login.json

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$FAILURES check(s) failed." >&2
  exit 1
fi
