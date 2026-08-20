#!/usr/bin/env bash
# Deletes a meter by ID, plus any readings for it first (deleting a meter with existing readings
# hits an FK constraint — see api/bruno/README.md). Logs in with the seed demo credentials rather
# than requiring a token to be passed in, since this is meant for quick manual cleanup after
# ad hoc UI/API testing, not for scripting into CI.
set -euo pipefail

BASE_URL="${2:-http://localhost}"
METER_ID="${1:?Usage: delete-meter.sh <meter-id> [base-url]}"

TOKEN=$(curl -sf -X POST "$BASE_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"GridMeter!Demo2026"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['accessToken'])")

READING_IDS=$(curl -sf "$BASE_URL/api/v1/readings?meterId=$METER_ID&size=100" \
  -H "Authorization: Bearer $TOKEN" \
  | python3 -c "import sys,json;[print(r['id']) for r in json.load(sys.stdin)['content']]")

for READING_ID in $READING_IDS; do
  curl -s -o /dev/null -w "DELETE /readings/$READING_ID -> %{http_code}\n" \
    -X DELETE "$BASE_URL/api/v1/readings/$READING_ID" -H "Authorization: Bearer $TOKEN"
done

curl -s -o /dev/null -w "DELETE /meters/$METER_ID -> %{http_code}\n" \
  -X DELETE "$BASE_URL/api/v1/meters/$METER_ID" -H "Authorization: Bearer $TOKEN"
