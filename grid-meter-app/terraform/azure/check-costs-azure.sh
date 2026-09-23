#!/usr/bin/env bash
# Independent cross-check that a terraform destroy left nothing quietly billing behind - queries
# real Azure Cost Management data by service, as a second data source separate from the live
# resource-existence checks (terraform/azure/check-resources-azure.sh, the residue-check pattern
# AWS's/GCP's own READMEs already establish).
#
# Real billing data, not a list-price estimate (confirmed live, 2026-09-23) - a genuine structural
# difference from GCP's estimate-costs-gcp.sh, which had to fall back to a list-price estimate
# because its BigQuery billing export was never set up. Azure's Cost Management Query API works
# without any export prerequisite - but it's accessed via `az rest` directly against
# Microsoft.CostManagement/query, not a dedicated `az costmanagement query` subcommand: the
# installed `costmanagement` CLI extension (1.0.0) only exposes `export`/`show-operation-result`,
# no ad-hoc query command, despite the underlying REST API fully supporting one. Also checked and
# ruled out: `az consumption usage list` (no extension needed, but every cost/quantity/date field
# it returns is a literal "None" string, not a real value - unusable for this purpose).
#
# Important limitation, confirmed live 2026-09-23: Cost Management data lags real usage too, the
# same shape AWS's Cost Explorer (24-48h) and GCP's would-be BigQuery export both already found -
# a query run here against a FULLY LIVE AKS/Postgres Flexible Server/Managed Redis deployment
# (applied and running the entire session) still showed only ~$0.00001 total (the bootstrap state
# Storage Account's own negligible cost), nothing for any of the actually-running compute. This
# script cannot confirm "zero cost right now" any more than AWS's/GCP's own cost checks could -
# only "zero cost as of a day or two ago", once Cost Management's own pipeline has caught up.
# Re-run this a day or two after a teardown for a meaningful answer; running it same-day mostly
# confirms the lag itself, not a clean subscription.
#
# Usage: ./check-costs-azure.sh [days-back]   (default: 7)
set -euo pipefail

# Cost Management is a subscription-wide API - read live from `az account show` rather than
# `terraform output`, since this script is typically run AFTER a destroy, when terraform state
# (and therefore its outputs) may already be empty.
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
DAYS="${1:-7}"

END_DATE="$(date +%Y-%m-%d)"
# -v-Nd is BSD/macOS date syntax (this project's dev machine); -d "-N days" is the GNU
# equivalent, kept as a fallback for portability - see CLAUDE.md's own standing lesson on
# BSD-vs-GNU date behavior differing silently.
START_DATE="$(date -v-"${DAYS}"d +%Y-%m-%d 2>/dev/null || date -d "-${DAYS} days" +%Y-%m-%d)"

echo "== Azure cost by service, $START_DATE to $END_DATE (subscription: $SUBSCRIPTION_ID) =="
echo "Note: Cost Management data lags real usage by more than same-day - a same-day teardown (or"
echo "even a fully live deployment) will NOT show real charges yet."
echo

az rest --method POST \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.CostManagement/query?api-version=2023-11-01" \
  --body "{
    \"type\": \"ActualCost\",
    \"timeframe\": \"Custom\",
    \"timePeriod\": {\"from\": \"${START_DATE}\", \"to\": \"${END_DATE}\"},
    \"dataset\": {
      \"granularity\": \"Daily\",
      \"aggregation\": {\"totalCost\": {\"name\": \"PreTaxCost\", \"function\": \"Sum\"}},
      \"grouping\": [{\"type\": \"Dimension\", \"name\": \"ServiceName\"}]
    }
  }" --output json | python3 -c "
import json, sys
from collections import defaultdict
from datetime import date, timedelta

d = json.load(sys.stdin)
props = d.get('properties', {})
cols = [c['name'] for c in props.get('columns', [])]
rows = props.get('rows', [])
cost_idx = cols.index('PreTaxCost')
date_idx = cols.index('UsageDate')
service_idx = cols.index('ServiceName')

# The API only returns rows for dates that actually have billed line items - days with zero cost
# are simply absent, not returned as zero. Build the full requested date range ourselves so every
# day prints something, matching AWS's check-costs-aws.sh's per-day display.
by_date = defaultdict(list)
for row in rows:
    by_date[str(row[date_idx])].append((row[service_idx], row[cost_idx]))

start = date.fromisoformat('$START_DATE')
end = date.fromisoformat('$END_DATE')
d_cursor = start
while d_cursor <= end:
    key = d_cursor.strftime('%Y%m%d')
    print(f'--- {d_cursor.isoformat()} ---')
    entries = [e for e in by_date.get(key, []) if e[1] > 0.0001]
    if not entries:
        print('  \$0.00 - no billed line items above \$0.0001')
    for service, cost in sorted(entries, key=lambda e: -e[1]):
        print(f'  {service}: \${cost:.4f}')
    d_cursor += timedelta(days=1)
"
