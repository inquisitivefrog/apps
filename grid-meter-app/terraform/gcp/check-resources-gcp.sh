#!/usr/bin/env bash
# GCP counterpart to terraform/aws/check-resources-aws.sh: confirms every Terraform-provisioned
# GCP resource actually exists and is healthy, queried directly against real GCP APIs - not
# trusting `terraform apply`'s own "Apply complete" message, same "verify the live system"
# discipline applied everywhere else in this project.
#
# Covers the full stack terraform/gcp/ creates, including Artifact Registry - the only section
# still missing relative to AWS's script is Workload Identity/IAM, since this build doesn't need
# pod-level GCP IAM bindings yet. Expected to grow the same way AWS's own check-resources-aws.sh
# did (its ECR/IAM sections only arrived once that later phase was actually built).
set -uo pipefail

TF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# tf_output <name> - wraps `terraform output -raw`, but doesn't trust a non-empty capture on its
# own. Found live (2026-09-21) running this exact script right after a real `terraform destroy`
# left an empty state: `terraform output -raw <name>` against a state with zero outputs prints its
# "Warning: No outputs found" diagnostic to STDOUT (confirmed by isolating stdout/stderr
# separately), exits 0, and stderr is empty - so `2>/dev/null` never had anything to suppress, and
# the multi-line warning text itself got captured as the "value", defeating the `-z` empty-check
# below entirely (it's very much non-empty) and producing a garbled cascade of gcloud errors
# instead of the intended clean "has terraform apply been run yet?" message. Same false-PASS shape
# as this script's other guard below (a technically-non-empty capture that isn't a real value) -
# fixed the same way, by adding a content check on top of the emptiness check: a real output value
# (project ID/region/zone/cluster name) is always a single line with no embedded newline; Terraform's
# warning diagnostic always is multi-line. Reject anything containing a newline as "not a real value".
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
  echo "Could not read project/region/zone/cluster name from terraform output - has 'terraform apply' been run yet?"
  exit 2
fi

PASS=0
FAIL=0

# check <label> <command...> - runs the command, prints PASS/FAIL, tallies results.
# Never aborts on a single failure - the whole point is a full report, not a fail-fast script.
#
# Requires BOTH a zero exit code AND non-empty stdout - neither alone is reliable. Discovered live
# testing this exact script (2026-09-21) against a real, currently-empty project:
# `gcloud compute instances list` with zero filter matches exits 0 and prints only a "filter keys
# not present" WARNING to stderr, empty stdout - a bare exit-code check alone would have read that
# as a false PASS with no real value behind it, the same false-PASS shape AWS's own
# k8s/check-resources-aws.sh found the hard way (2026-09-18), just from the opposite direction
# (there, a non-empty *stderr* error message read as truthy "output"; here, a *successful* exit
# code with empty real output). stdout and stderr are captured separately (not merged via 2>&1)
# specifically so a successful-but-empty result can't masquerade as a real value either way.
check() {
  local label="$1"; shift
  local out err rc errfile
  errfile="$(mktemp)"
  out="$("$@" --project "$PROJECT_ID" 2>"$errfile")"
  rc=$?
  err="$(cat "$errfile")"
  rm -f "$errfile"
  if [[ $rc -eq 0 && -n "$out" && "$out" != "None" ]]; then
    echo "  PASS  $label: $out"
    PASS=$((PASS+1))
  else
    echo "  FAIL  $label: not found (or empty) - ${err:-no output}"
    FAIL=$((FAIL+1))
  fi
}

echo "== Checking Terraform-provisioned GCP resources for cluster '$CLUSTER_NAME' (project: $PROJECT_ID, region: $REGION) =="
echo

echo "-- Networking --"
check "VPC" gcloud compute networks describe grid-meter-app-vpc --format="value(name)"
check "Subnet" gcloud compute networks subnets describe grid-meter-app-subnet --region "$REGION" --format="value(name)"
check "Cloud Router" gcloud compute routers describe grid-meter-app-router --region "$REGION" --format="value(name)"
check "Cloud NAT" gcloud compute routers nats describe grid-meter-app-nat --router grid-meter-app-router --region "$REGION" --format="value(name)"
check "Private Service Access peering" gcloud services vpc-peerings list --network=grid-meter-app-vpc --format="value(peering)"
echo

echo "-- GKE --"
check "GKE cluster status" gcloud container clusters describe "$CLUSTER_NAME" --zone "$ZONE" --format="value(status)"
check "GKE node pool status" gcloud container node-pools describe grid-meter-app-nodes --cluster "$CLUSTER_NAME" --zone "$ZONE" --format="value(status)"
check "GKE node service account" gcloud iam service-accounts describe "grid-meter-app-gke-node@${PROJECT_ID}.iam.gserviceaccount.com" --format="value(email)"
# Found via a real live apply (2026-09-21): GCE truncates instance names at 63 chars, so a
# name-regex filter against the full cluster/node-pool name silently matched nothing
# ("gke-grid-meter-app-gke-..." never appears - real instances are named
# "gke-grid-meter-app-g-grid-meter-app-n-<hash>-<suffix>", both components truncated). Filtering
# on GKE's own goog-k8s-cluster-name label instead - stable, not truncated, and exists on every
# GKE-managed instance (confirmed via `gcloud compute instances describe ... --format="yaml(labels)"`
# against a real node).
#
# A dedicated count check, not the shared check() function above: check() only verifies "command
# succeeded and returned something non-empty" (see its own comment - deliberately no expected-value
# comparison, since every other call here is a single-resource existence/status check with nothing
# to count). Found live (2026-09-24) that this made the "(expect 3, RUNNING)" label pure cosmetic
# text - it never actually validated the count, so it kept reporting PASS with 4 real instances
# returned instead of 3 (main's 3 nodes + the separate extra pool's 1, node_pools.tf/variables.tf),
# not just today after the GCE_STOCKOUT zone fix. Fixed with an explicit count comparison, matching
# the style AWS's/Azure's check-resources-*.sh already use for PVC counts.
GCE_INSTANCE_NAMES="$(gcloud compute instances list --project "$PROJECT_ID" --filter="labels.goog-k8s-cluster-name=${CLUSTER_NAME} AND status=RUNNING" --format="value(name)" 2>/dev/null)"
GCE_INSTANCE_COUNT="$(echo "$GCE_INSTANCE_NAMES" | grep -c . || true)"
if [[ "$GCE_INSTANCE_COUNT" == "4" ]]; then
  echo "  PASS  GCE worker instances (expect 4, RUNNING): $GCE_INSTANCE_COUNT"
  PASS=$((PASS+1))
else
  echo "  FAIL  GCE worker instances (expect 4, RUNNING): got $GCE_INSTANCE_COUNT - ${GCE_INSTANCE_NAMES:-none}"
  FAIL=$((FAIL+1))
fi
echo

echo "-- Data tier --"
check "Cloud SQL instance state" gcloud sql instances describe grid-meter-app-postgres --format="value(state)"
check "Cloud SQL database version" gcloud sql instances describe grid-meter-app-postgres --format="value(databaseVersion)"
check "Cloud SQL database: gridmeter" gcloud sql databases describe gridmeter --instance=grid-meter-app-postgres --format="value(name)"
check "Memorystore for Valkey state" gcloud memorystore instances describe grid-meter-app-cache --location "$REGION" --format="value(state)"
check "Memorystore engine version" gcloud memorystore instances describe grid-meter-app-cache --location "$REGION" --format="value(engineVersion)"
echo

echo "-- Secret Manager --"
check "Cloud SQL password secret" gcloud secrets describe grid-meter-app-cloudsql-password --format="value(name)"
echo

echo "-- Artifact Registry --"
check "Repo: api" gcloud artifacts repositories describe grid-meter-app-api --location "$REGION" --format="value(name)"
check "Repo: frontend" gcloud artifacts repositories describe grid-meter-app-frontend --location "$REGION" --format="value(name)"
echo

echo "== Summary: $PASS passed, $FAIL failed =="
if [[ "$FAIL" -gt 0 ]]; then
  echo "One or more expected resources are missing or unhealthy - investigate before proceeding."
  exit 1
fi
echo "All expected Terraform-provisioned resources confirmed present and healthy."
