#!/usr/bin/env bash
# GCP counterpart to terraform/aws/check-resources.sh: confirms every Terraform-provisioned GCP
# resource actually exists and is healthy, queried directly against real GCP APIs - not trusting
# `terraform apply`'s own "Apply complete" message, same "verify the live system" discipline
# applied everywhere else in this project.
#
# Scoped to what terraform/gcp/'s current base-infra pass actually creates (VPC/GKE/Cloud
# SQL/Memorystore) - it does NOT check Artifact Registry, Workload Identity, or any k8s-overlay
# resource, because none of that exists yet (see README.md's "Not yet built this pass"). AWS's own
# check-resources.sh only grew its ECR/IAM sections once that later phase was actually built -
# this script's scope is expected to grow the same way, not a gap to fix now.
set -uo pipefail

TF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_ID="$(cd "$TF_DIR" && terraform output -raw gcp_project_id 2>/dev/null)"
REGION="$(cd "$TF_DIR" && terraform output -raw gcp_region 2>/dev/null)"
ZONE="$(cd "$TF_DIR" && terraform output -raw gcp_zone 2>/dev/null)"
CLUSTER_NAME="$(cd "$TF_DIR" && terraform output -raw gke_cluster_name 2>/dev/null)"

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
check "GCE worker instances (expect 3, RUNNING)" gcloud compute instances list --filter="labels.goog-k8s-cluster-name=${CLUSTER_NAME} AND status=RUNNING" --format="value(name)"
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
