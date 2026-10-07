#!/usr/bin/env bash
# One-time historical backfill - NOT a load test, deliberately separate from load-tests/'s
# steady-state/ramp-up/rapid-spike profiles. Those exist to validate real-time ingestion
# performance and correctly use "now" as the readingTimestamp for that purpose; this script
# exists purely so the Readings page looks like a real system with months of history instead
# of a pile of readings clustered around whenever a load test last ran. Run manually, as needed
# - not wired into any CI pipeline.
#
# Usage: scripts/seed-historical-readings.sh [host] [port]
#   Defaults to localhost:80 (matches load-tests/config/load-test.properties' own default).
#   Example against the AWS demo: scripts/seed-historical-readings.sh 3.149.164.41 80
set -euo pipefail

HOST="${1:-localhost}"
PORT="${2:-80}"
BASE_URL="http://${HOST}:${PORT}/api/v1"
READINGS_PER_METER="${READINGS_PER_METER:-30}"
DAYS_OF_HISTORY="${DAYS_OF_HISTORY:-90}"

echo "== Logging in =="
TOKEN="$(curl -s -X POST "$BASE_URL/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"username":"demo","password":"GridMeter!Demo2026"}' | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])')"

if [[ -z "$TOKEN" ]]; then
  echo "Login failed - no access token received." >&2
  exit 1
fi

echo "== Fetching all meter IDs (paginated) =="
METER_IDS="$(python3 - "$BASE_URL" "$TOKEN" <<'PYEOF'
import json, sys, urllib.request

base_url, token = sys.argv[1], sys.argv[2]
headers = {"Authorization": f"Bearer {token}"}
ids = []
page = 0
while True:
    req = urllib.request.Request(f"{base_url}/meters?page={page}&size=100", headers=headers)
    with urllib.request.urlopen(req) as resp:
        data = json.load(resp)
    ids.extend(m["id"] for m in data["content"])
    if page >= data.get("totalPages", 1) - 1:
        break
    page += 1
print("\n".join(ids))
PYEOF
)"

METER_COUNT="$(echo "$METER_IDS" | grep -c . || true)"
if [[ "$METER_COUNT" -eq 0 ]]; then
  echo "No meters found - nothing to backfill. Run a load-test profile first to provision some." >&2
  exit 1
fi
echo "Found $METER_COUNT meters. Generating $READINGS_PER_METER readings each, spread over the last $DAYS_OF_HISTORY days."

echo "== Posting historical readings =="
# Meter IDs go through a temp file, not stdin - `python3 - <<HEREDOC` already uses stdin to
# deliver the script source itself, which fully exhausts it before the script ever runs;
# confirmed live (2026-10-07) this silently produces an empty sys.stdin read inside the script
# (0 readings posted, no error) rather than a clean failure, since piping into a `-`+heredoc
# invocation is well-formed shell syntax, just not doing what it looks like it does.
METER_IDS_FILE="$(mktemp)"
trap 'rm -f "$METER_IDS_FILE"' EXIT
echo "$METER_IDS" > "$METER_IDS_FILE"

python3 - "$BASE_URL" "$TOKEN" "$READINGS_PER_METER" "$DAYS_OF_HISTORY" "$METER_IDS_FILE" <<'PYEOF'
import json, random, sys, urllib.request, uuid
from datetime import datetime, timedelta, timezone

base_url, token, readings_per_meter, days_of_history, meter_ids_file = (
    sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
)
with open(meter_ids_file) as f:
    meter_ids = [line.strip() for line in f if line.strip()]

now = datetime.now(timezone.utc)
total, failures = 0, 0
for meter_id in meter_ids:
    # Sorted so each meter's own history reads chronologically, not shuffled -
    # purely cosmetic, doesn't affect the API (readings are immutable, order of
    # insertion is irrelevant to correctness).
    offsets = sorted(random.uniform(0, days_of_history * 86400) for _ in range(readings_per_meter))
    for offset_seconds in offsets:
        ts = (now - timedelta(seconds=offset_seconds)).strftime("%Y-%m-%dT%H:%M:%SZ")
        value = round(random.uniform(0, 999) + random.uniform(0, 99) / 100, 2)
        body = json.dumps({"meterId": meter_id, "readingTimestamp": ts, "value": value}).encode()
        # Idempotency-Key must be unique per request, not a shared header - confirmed live
        # (2026-10-07) the API requires this on every POST /readings (same mechanism
        # load-tests/steady-state.jmx already uses via JMeter's __UUID() function).
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Idempotency-Key": str(uuid.uuid4()),
        }
        req = urllib.request.Request(f"{base_url}/readings", data=body, headers=headers, method="POST")
        try:
            urllib.request.urlopen(req)
            total += 1
        except urllib.error.HTTPError as e:
            failures += 1
            if failures <= 5:
                print(f"  FAILED meter={meter_id} ts={ts}: {e.code} {e.read().decode()[:200]}", file=sys.stderr)

print(f"Posted {total} readings, {failures} failures.")
if failures > 0 and failures == total + failures:
    sys.exit(1)
PYEOF

echo
echo "Done."
