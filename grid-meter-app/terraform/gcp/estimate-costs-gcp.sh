#!/usr/bin/env bash
# Stand-in for the check-costs-gcp.sh this project doesn't have yet (see README.md's "No
# check-costs-gcp.sh yet" section) - AWS's check-costs-aws.sh works because `aws ce
# get-cost-and-usage` is an always-on, queryable-anytime API; GCP has no gcloud/API equivalent
# without first setting up a one-time, Console-only Cloud Billing export to BigQuery, which this
# project hasn't done. That's a real prerequisite gap, not something this script works around -
# what this script does instead is a genuinely different, complementary thing: inventory whatever
# GCP resources are ACTUALLY LIVE right now (same live-query discipline as check-resources-gcp.sh)
# and multiply by published GCP list pricing to produce a ballpark "what is this probably costing"
# estimate, usable today with zero setup.
#
# This is NOT real billing data and cannot be treated as such:
#   - List prices only - no committed-use discounts, no promotional credits beyond the one
#     Always-Free allowance explicitly called out below.
#   - Usage-based charges (network egress, Cloud NAT data processing, load-balancer data
#     processing) are NOT included - they can't be estimated from static resource presence at
#     all, only from actual traffic, which is exactly the data this script doesn't have access to.
#   - Rates below were sourced via live web search (2026-09-21) against a mix of official
#     cloud.google.com pricing pages and third-party pricing-calculator sites, since GCP exposes no
#     `gcloud`/API call this script could query directly for its own current rate card (the real
#     mechanism, the Cloud Billing Catalog API, requires per-SKU-ID lookups disproportionate to
#     this script's scope). Treat these as "right order of magnitude for a us-central1 dev/demo
#     stack," not penny-accurate - each rate's sourcing confidence is noted inline.
#
# Purpose: an immediate "does anything expensive appear to be running right now" sanity check
# during a work session, and a same-instant confirmation that a completed teardown is genuinely
# costing nothing - both roles AWS's check-costs-aws.sh can't fill immediately (it has a real 2-3
# day Cost Explorer lag). Complements, not replaces, a real check-costs-gcp.sh once the BigQuery
# export exists.
set -uo pipefail

TF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Same tf_output() helper and same fix as check-resources-gcp.sh (2026-09-21): `terraform output
# -raw` writes its "No outputs found" warning to stdout (not stderr) when state has zero outputs,
# so a bare `2>/dev/null` never suppresses it - reject any captured value containing a newline,
# since a real output value is always one line and Terraform's warning diagnostic never is.
tf_output() {
  local val
  val="$(cd "$TF_DIR" && terraform output -raw "$1" 2>/dev/null)"
  if [[ "$val" == *$'\n'* ]]; then
    val=""
  fi
  printf '%s' "$val"
}

PROJECT_ID="$(tf_output gcp_project_id)"
REGION="$(tf_output gcp_region)"
ZONE="$(tf_output gcp_zone)"
CLUSTER_NAME="$(tf_output gke_cluster_name)"

if [[ -z "$PROJECT_ID" || -z "$REGION" || -z "$ZONE" || -z "$CLUSTER_NAME" ]]; then
  echo "No terraform outputs found - either 'terraform apply' hasn't been run yet, or everything"
  echo "has already been destroyed. Either way: nothing live to estimate. Total: \$0.00/day."
  exit 0
fi

# --- List-price rate card (us-central1, sourced 2026-09-21 via live web search) ---
# Each rate is USD, per hour unless noted. Comments record sourcing confidence honestly rather
# than implying false precision.
#
# e2-medium (2 vCPU / 4 GiB, this stack's only node machine type): two materially different
# figures turned up ($0.0335/hr vs $0.055/hr across different reseller/calculator sites, neither
# GCP's own pricing page directly). Went with $0.0335/hr - it's the one that's internally
# consistent with the same source's own e2-small and e2-standard-2 figures (e2-standard-2 priced
# at exactly 2x this e2-medium figure, which is dimensionally correct: same vCPU count, 2x memory
# family scaling), which the $0.055/hr figure isn't. Flagged as the least certain rate below.
E2_MEDIUM_HOURLY=0.0335

# GKE cluster management fee: $0.10/cluster-hour list price, but Google's Always Free tier grants
# $74.40/month in GKE credit applied automatically to exactly one zonal or Autopilot cluster's
# management fee per billing account - enough to cover this stack's single zonal cluster running
# continuously all month. This project has exactly one cluster, so the net cost is $0.00, not
# $0.10/hr - shown as both the list price and the free-tier-adjusted net below, not silently
# assumed either way (same "declare it explicitly" discipline as this project's other findings).
GKE_CLUSTER_MGMT_HOURLY_LIST=0.10
GKE_CLUSTER_MGMT_HOURLY_NET=0.00

# Cloud SQL db-f1-micro (shared-core compute only, storage billed separately below): sourced from
# a specific historical $0.0150/hr figure that several current 2026 sources' monthly-cost ranges
# ($7-10/month) are consistent with ($0.015 x 730 = $10.95) - treated as reliable enough for an
# estimate, not penny-exact.
CLOUDSQL_F1_MICRO_HOURLY=0.0150
CLOUDSQL_PD_SSD_GB_MONTH=0.17

# Memorystore for Valkey SHARED_CORE_NANO: flat per-instance rate (fixed 1.4 GiB capacity, not
# billed per-GB) - one of the more confidently-sourced rates here (single consistent figure).
MEMORYSTORE_NANO_HOURLY=0.0318

# Cloud NAT: per-VM gateway fee (capped at 32 VMs) plus a flat per-external-IP fee. Data
# processing ($0.045/GiB) is usage-based and deliberately excluded - can't be estimated from
# static resource presence.
NAT_GATEWAY_PER_VM_HOURLY=0.0014
NAT_GATEWAY_CAP_HOURLY=0.044
NAT_EXTERNAL_IP_HOURLY=0.005

# Persistent disks. pd-standard backs GKE node boot disks (gke.tf's disk_type); pd-balanced-xfs
# (k8s/storageclass-gcp.yaml) backs Kafka's PVCs. pd-standard's rate is the least confidently
# sourced number in this script - search results only confirmed it's cheaper than pd-balanced
# without giving a clean current figure, so a long-standing, widely-cited $0.04/GiB-month rate is
# used as a reasonable stand-in, flagged as such.
PD_STANDARD_GB_MONTH=0.04
PD_BALANCED_GB_MONTH=0.10
GKE_NODE_BOOT_DISK_GB=30

# External Network Load Balancer forwarding rule: flat rate covering up to 5 rules (this stack
# uses exactly 1, traefik-web).
LB_FORWARDING_RULE_HOURLY=0.025

HOURS_PER_DAY=24
HOURS_PER_MONTH=730 # GCP's own standard billing-month convention (365*24/12), used consistently across its pricing pages.

TOTAL_HOURLY=0.0000

# line <label> <hourly>
line() {
  local label="$1" hourly="$2"
  local daily monthly
  daily="$(awk -v h="$hourly" -v d="$HOURS_PER_DAY" 'BEGIN{printf "%.4f", h*d}')"
  monthly="$(awk -v h="$hourly" -v m="$HOURS_PER_MONTH" 'BEGIN{printf "%.2f", h*m}')"
  printf "  %-45s \$%.4f/hr   \$%s/day   \$%s/mo\n" "$label" "$hourly" "$daily" "$monthly"
  TOTAL_HOURLY="$(awk -v t="$TOTAL_HOURLY" -v h="$hourly" 'BEGIN{printf "%.4f", t+h}')"
}

echo "== Estimating GCP list-price cost for cluster '$CLUSTER_NAME' (project: $PROJECT_ID, region: $REGION) =="
echo "   (list-price estimate from live resource inventory - not real billing data; see this"
echo "   script's header comment for exactly what is and isn't included)"
echo

echo "-- Compute (GKE nodes) --"
NODE_COUNT="$(gcloud compute instances list --project "$PROJECT_ID" \
  --filter="labels.goog-k8s-cluster-name=${CLUSTER_NAME} AND status=RUNNING" \
  --format="value(name)" 2>/dev/null | grep -c . || true)"
NODE_COUNT="${NODE_COUNT:-0}"
if [[ "$NODE_COUNT" -gt 0 ]]; then
  node_compute_hourly="$(awk -v n="$NODE_COUNT" -v r="$E2_MEDIUM_HOURLY" 'BEGIN{printf "%.4f", n*r}')"
  line "$NODE_COUNT x e2-medium (compute)" "$node_compute_hourly"
  node_disk_hourly="$(awk -v n="$NODE_COUNT" -v gb="$GKE_NODE_BOOT_DISK_GB" -v r="$PD_STANDARD_GB_MONTH" -v m="$HOURS_PER_MONTH" 'BEGIN{printf "%.4f", (n*gb*r)/m}')"
  line "$NODE_COUNT x ${GKE_NODE_BOOT_DISK_GB}GB pd-standard boot disk" "$node_disk_hourly"
else
  echo "  (no running nodes found for this cluster)"
fi
echo

echo "-- GKE cluster management fee --"
CLUSTER_STATUS="$(gcloud container clusters describe "$CLUSTER_NAME" --project "$PROJECT_ID" --zone "$ZONE" --format="value(status)" 2>/dev/null)"
if [[ -n "$CLUSTER_STATUS" ]]; then
  echo "  List price \$${GKE_CLUSTER_MGMT_HOURLY_LIST}/hr, but covered by the Always Free tier's"
  echo "  \$74.40/month credit for this project's one zonal cluster - net cost used below:"
  line "GKE cluster management fee (Always-Free-covered)" "$GKE_CLUSTER_MGMT_HOURLY_NET"
else
  echo "  (no GKE cluster found)"
fi
echo

echo "-- Data tier --"
SQL_STATE="$(gcloud sql instances describe grid-meter-app-postgres --project "$PROJECT_ID" --format="value(state)" 2>/dev/null)"
if [[ -n "$SQL_STATE" ]]; then
  SQL_DISK_GB="$(gcloud sql instances describe grid-meter-app-postgres --project "$PROJECT_ID" --format="value(settings.dataDiskSizeGb)" 2>/dev/null)"
  SQL_DISK_GB="${SQL_DISK_GB:-20}" # falls back to variables.tf's cloudsql_disk_size_gb default if the live field comes back empty
  line "Cloud SQL db-f1-micro (compute)" "$CLOUDSQL_F1_MICRO_HOURLY"
  sql_disk_hourly="$(awk -v gb="$SQL_DISK_GB" -v r="$CLOUDSQL_PD_SSD_GB_MONTH" -v m="$HOURS_PER_MONTH" 'BEGIN{printf "%.4f", (gb*r)/m}')"
  line "Cloud SQL ${SQL_DISK_GB}GB PD_SSD storage" "$sql_disk_hourly"
else
  echo "  (no Cloud SQL instance found)"
fi

MEMORYSTORE_STATE="$(gcloud memorystore instances describe grid-meter-app-cache --project "$PROJECT_ID" --location "$REGION" --format="value(state)" 2>/dev/null)"
if [[ -n "$MEMORYSTORE_STATE" ]]; then
  line "Memorystore for Valkey SHARED_CORE_NANO" "$MEMORYSTORE_NANO_HOURLY"
else
  echo "  (no Memorystore instance found)"
fi
echo

echo "-- Networking --"
NAT_NAME="$(gcloud compute routers nats describe grid-meter-app-nat --project "$PROJECT_ID" --router grid-meter-app-router --region "$REGION" --format="value(name)" 2>/dev/null)"
if [[ -n "$NAT_NAME" ]]; then
  nat_gateway_hourly="$(awk -v n="$NODE_COUNT" -v r="$NAT_GATEWAY_PER_VM_HOURLY" -v cap="$NAT_GATEWAY_CAP_HOURLY" 'BEGIN{v=n*r; printf "%.4f", (v<cap)?v:cap}')"
  nat_total_hourly="$(awk -v g="$nat_gateway_hourly" -v ip="$NAT_EXTERNAL_IP_HOURLY" 'BEGIN{printf "%.4f", g+ip}')"
  line "Cloud NAT (gateway + 1 external IP, excl. data processing)" "$nat_total_hourly"
else
  echo "  (no Cloud NAT found)"
fi

# Found live (2026-09-22): an unfiltered `forwarding-rules list` also picks up Memorystore's own
# PSC auto-connection forwarding rules (confirmed via `loadBalancingScheme` - empty/unset on those,
# vs "EXTERNAL" on the actual Network LB rule traefik-web creates) - a different product with
# different billing, not the external-LB forwarding-rule fee this section prices. The dollar total
# happened to land right anyway that run (both fall under the same flat "up to 5 rules" tier as the
# one real external rule would), but the label was wrong and would double-count once a real LB rule
# also exists alongside them. Filtered to loadBalancingScheme=EXTERNAL specifically.
FR_COUNT="$(gcloud compute forwarding-rules list --project "$PROJECT_ID" --filter="loadBalancingScheme=EXTERNAL" --format="value(name)" 2>/dev/null | grep -c . || true)"
FR_COUNT="${FR_COUNT:-0}"
if [[ "$FR_COUNT" -gt 0 ]]; then
  line "$FR_COUNT external forwarding rule(s) (excl. data processing)" "$LB_FORWARDING_RULE_HOURLY"
else
  echo "  (no forwarding rules found - LoadBalancer Service not deployed)"
fi
echo

echo "-- Persistent disks (Kafka PVCs, zone-less like teardown-gcp.sh's own disk check) --"
PVC_TOTAL_GB="$(gcloud compute disks list --project "$PROJECT_ID" --filter="name~^pvc-" --format="value(sizeGb)" 2>/dev/null | awk '{s+=$1} END{printf "%d", s+0}')"
if [[ "$PVC_TOTAL_GB" -gt 0 ]]; then
  pvc_hourly="$(awk -v gb="$PVC_TOTAL_GB" -v r="$PD_BALANCED_GB_MONTH" -v m="$HOURS_PER_MONTH" 'BEGIN{printf "%.4f", (gb*r)/m}')"
  line "${PVC_TOTAL_GB}GB total across Kafka's pd-balanced-xfs PVCs" "$pvc_hourly"
else
  echo "  (no PVC-backed persistent disks found)"
fi
echo

TOTAL_DAILY="$(awk -v h="$TOTAL_HOURLY" -v d="$HOURS_PER_DAY" 'BEGIN{printf "%.2f", h*d}')"
TOTAL_MONTHLY="$(awk -v h="$TOTAL_HOURLY" -v m="$HOURS_PER_MONTH" 'BEGIN{printf "%.2f", h*m}')"
echo "== Estimated total: \$${TOTAL_HOURLY}/hr   \$${TOTAL_DAILY}/day   \$${TOTAL_MONTHLY}/mo =="
echo "   (list price, no discounts applied; excludes all usage-based data-processing/egress"
echo "   charges - see header comment. Artifact Registry storage excluded as negligible.)"
