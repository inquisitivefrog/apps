#!/usr/bin/env bash
# Independent cross-check that a terraform destroy left nothing quietly billing behind - queries
# real AWS Cost Explorer data by service, as a second data source separate from the live
# resource-existence checks in README.md's "confirm no residue" section.
#
# Important limitation, confirmed live 2026-09-18: Cost Explorer data lags - querying it
# immediately after a same-day teardown showed a stale/incomplete picture (missing known real
# EKS/RDS/ElastiCache/NAT charges from the hours just spent testing), not zero. This script
# cannot confirm "zero cost right now" - only "zero cost as of a day or two ago", once Cost
# Explorer's own pipeline has caught up. Re-run this a day or two after a teardown for a
# meaningful answer; running it same-day mostly confirms the lag itself, not a clean account.
#
# Usage: ./check-costs.sh [days-back]   (default: 7)
set -euo pipefail

# Cost Explorer is a billing-account-wide API - defaulted explicitly here rather than read from
# `terraform output`, since this script is typically run AFTER a destroy, when terraform state
# (and therefore its outputs) may already be empty.
AWS_PROFILE="${AWS_PROFILE:-grid-meter}"
DAYS="${1:-7}"

END_DATE="$(date +%Y-%m-%d)"
# -v-Nd is BSD/macOS date syntax (this project's dev machine); -d "-N days" is the GNU
# equivalent, kept as a fallback for portability - see CLAUDE.md's own standing lesson on
# BSD-vs-GNU date behavior differing silently.
START_DATE="$(date -v-"${DAYS}"d +%Y-%m-%d 2>/dev/null || date -d "-${DAYS} days" +%Y-%m-%d)"

echo "== AWS cost by service, $START_DATE to $END_DATE (profile: $AWS_PROFILE) =="
echo "Note: Cost Explorer data typically lags 24-48h - a same-day teardown will NOT show \$0 yet."
echo

aws ce get-cost-and-usage \
  --time-period Start="$START_DATE",End="$END_DATE" \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --profile "$AWS_PROFILE" --region us-east-1 \
  --output json | python3 -c "
import json, sys

d = json.load(sys.stdin)
for period in d.get('ResultsByTime', []):
    date = period['TimePeriod']['Start']
    estimated = ' (estimated)' if period.get('Estimated') else ''
    groups = [g for g in period.get('Groups', [])
              if float(g['Metrics']['UnblendedCost']['Amount']) > 0.0001]
    print(f'--- {date}{estimated} ---')
    if not groups:
        print('  \$0.00 - no billed line items')
    for g in sorted(groups, key=lambda g: -float(g['Metrics']['UnblendedCost']['Amount'])):
        cost = float(g['Metrics']['UnblendedCost']['Amount'])
        print(f'  {g[\"Keys\"][0]}: \${cost:.4f}')
"
