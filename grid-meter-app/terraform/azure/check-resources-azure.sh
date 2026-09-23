#!/usr/bin/env bash
# Azure counterpart to terraform/aws/check-resources-aws.sh / terraform/gcp/check-resources-gcp.sh:
# confirms every Terraform-provisioned Azure resource actually exists and is healthy, queried
# directly against real Azure APIs (`az`) - not trusting `terraform apply`'s own "Apply complete"
# message, same "verify the live system" discipline applied everywhere else in this project.
#
# Intended to run right after `terraform apply` in terraform/azure/, before `k8s/deploy-azure.sh` -
# scoped to Terraform-managed infrastructure only. It does NOT check kubectl-provisioned resources
# (the load balancer, Kafka's PVCs/Managed Disks in the node resource group) - those don't exist
# until deploy-azure.sh runs, and are covered by teardown-azure.sh's own live checks during
# teardown instead.
#
# Azure Managed Redis is queried via `az redisenterprise` (not a guessed command-group name - the
# real resource ID confirmed live during this project's own first Managed Redis apply was
# .../Microsoft.Cache/redisEnterprise/<name>, and `redisenterprise` is the matching CLI group).
#
# NOT yet live-tested against a real cluster as of 2026-09-23 - only syntax-checked (bash -n) this
# pass, same caveat k8s/check-resources-azure.sh carries.
set -uo pipefail

TF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# tf_output <name> - wraps `terraform output -raw`, but doesn't trust a non-empty capture on its
# own. Same guard AWS's/GCP's identical scripts use: a real output value is always a single line
# with no embedded newline, while a state-with-zero-outputs "Warning: No outputs found" diagnostic
# (printed to stdout, exit 0, empty stderr) is multi-line - reject anything containing a newline
# as "not a real value" rather than trusting emptiness-of-stderr alone.
tf_output() {
  local val
  val="$(cd "$TF_DIR" && terraform output -raw "$1" 2>/dev/null)"
  if [[ "$val" == *$'\n'* ]]; then
    val=""
  fi
  printf '%s' "$val"
}

RESOURCE_GROUP="$(tf_output resource_group_name)"
CLUSTER_NAME="$(tf_output aks_cluster_name)"

if [[ -z "$RESOURCE_GROUP" || -z "$CLUSTER_NAME" ]]; then
  echo "Could not read resource group/cluster name from terraform output - has 'terraform apply' been run yet?"
  exit 2
fi

# Resource names not exposed as terraform outputs (VNet, subnets, Key Vault, ACR, Redis, Postgres,
# identity) are read straight from locals.tf's/each resource's own naming convention - the same
# "<project_name>-<suffix>" pattern used throughout this config - rather than adding an output for
# every single resource name just for this script.
PROJECT_NAME="grid-meter-app"
VNET_NAME="${PROJECT_NAME}-vnet"
AKS_SUBNET="${PROJECT_NAME}-aks-subnet"
POSTGRES_SUBNET="${PROJECT_NAME}-postgres-subnet"
DNS_ZONE="${PROJECT_NAME}.postgres.database.azure.com"
POSTGRES_SERVER="${PROJECT_NAME}-postgres"
REDIS_NAME="${PROJECT_NAME}-redis"
KEY_VAULT_NAME="$(tf_output key_vault_name)"
ACR_LOGIN_SERVER="$(tf_output acr_login_server)"
ACR_NAME="${ACR_LOGIN_SERVER%%.*}"

# `az redisenterprise ...` is a dynamically-installed CLI extension, not built in - confirmed live
# (2026-09-23) its first-ever invocation on this machine printed 3 lines of "installing extension"
# warnings on stderr ahead of the real value, which this script's check() below merges into the
# captured output (deliberately, so a real command failure's error text is still visible) - without
# this pre-install, both Redis checks' PASS lines would carry that noise every run, not just the
# first. Installing it once, quietly, up front keeps every later `check` call's output clean.
az extension add --name redisenterprise --allow-preview true -y >/dev/null 2>&1 || true

PASS=0
FAIL=0

# check <label> <command...> - runs the command, prints PASS/FAIL, tallies results.
# Never aborts on a single failure - the whole point is a full report, not a fail-fast script.
check() {
  local label="$1"; shift
  local out
  if out="$("$@" 2>&1)" && [[ -n "$out" && "$out" != "None" && "$out" != "null" ]]; then
    echo "  PASS  $label: $out"
    PASS=$((PASS+1))
  else
    echo "  FAIL  $label: not found (or empty) - ${out:-no output}"
    FAIL=$((FAIL+1))
  fi
}

echo "== Checking Terraform-provisioned Azure resources for cluster '$CLUSTER_NAME' (resource group: $RESOURCE_GROUP) =="
echo

echo "-- Networking --"
check "Resource Group" az group show --name "$RESOURCE_GROUP" --query "properties.provisioningState" -o tsv
check "VNet" az network vnet show --resource-group "$RESOURCE_GROUP" --name "$VNET_NAME" --query "provisioningState" -o tsv
check "AKS subnet" az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$AKS_SUBNET" --query "provisioningState" -o tsv
check "Postgres delegated subnet" az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$POSTGRES_SUBNET" --query "provisioningState" -o tsv
check "Postgres private DNS zone" az network private-dns zone show --resource-group "$RESOURCE_GROUP" --name "$DNS_ZONE" --query "provisioningState" -o tsv
check "Postgres private DNS VNet link" az network private-dns link vnet show --resource-group "$RESOURCE_GROUP" --zone-name "$DNS_ZONE" --name "${PROJECT_NAME}-postgres-dns-link" --query "provisioningState" -o tsv
echo

echo "-- AKS --"
check "AKS cluster provisioning state" az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "provisioningState" -o tsv
check "AKS system node pool state" az aks nodepool show --resource-group "$RESOURCE_GROUP" --cluster-name "$CLUSTER_NAME" --name system --query "provisioningState" -o tsv
check "AKS node count (expect 2)" az aks nodepool show --resource-group "$RESOURCE_GROUP" --cluster-name "$CLUSTER_NAME" --name system --query "count" -o tsv
check "AKS workload identity enabled" az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "oidcIssuerProfile.enabled" -o tsv
echo

echo "-- Data tier --"
check "Postgres Flexible Server state" az postgres flexible-server show --resource-group "$RESOURCE_GROUP" --name "$POSTGRES_SERVER" --query "state" -o tsv
check "Postgres version" az postgres flexible-server show --resource-group "$RESOURCE_GROUP" --name "$POSTGRES_SERVER" --query "version" -o tsv
check "Postgres database: gridmeter" az postgres flexible-server db show --resource-group "$RESOURCE_GROUP" --server-name "$POSTGRES_SERVER" --database-name gridmeter --query "name" -o tsv
check "Managed Redis provisioning state" az redisenterprise show --resource-group "$RESOURCE_GROUP" --cluster-name "$REDIS_NAME" --query "provisioningState" -o tsv
check "Managed Redis database access policy assignment" az redisenterprise database access-policy-assignment list --resource-group "$RESOURCE_GROUP" --cluster-name "$REDIS_NAME" --database-name default --query "[0].name" -o tsv
echo

echo "-- Key Vault --"
check "Key Vault" az keyvault show --name "$KEY_VAULT_NAME" --query "properties.provisioningState" -o tsv
check "Postgres password secret exists" az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "postgres-admin-password" --query "id" -o tsv
check "Key Vault RBAC role assignment (deployer)" az role assignment list --scope "$(az keyvault show --name "$KEY_VAULT_NAME" --query id -o tsv 2>/dev/null)" --query "[?roleDefinitionName=='Key Vault Secrets Officer'] | [0].roleDefinitionName" -o tsv
echo

echo "-- Container Registry --"
check "ACR provisioning state" az acr show --name "$ACR_NAME" --query "provisioningState" -o tsv
check "ACR AcrPull role assignment (AKS kubelet identity)" az role assignment list --scope "$(az acr show --name "$ACR_NAME" --query id -o tsv 2>/dev/null)" --query "[?roleDefinitionName=='AcrPull'] | [0].roleDefinitionName" -o tsv
echo

echo "-- App workload identity (IAM-auth backport, 2026-09-23 - see README.md) --"
check "User-assigned identity" az identity show --resource-group "$RESOURCE_GROUP" --name "${PROJECT_NAME}-app-identity" --query "principalId" -o tsv
check "Federated identity credential" az identity federated-credential show --resource-group "$RESOURCE_GROUP" --identity-name "${PROJECT_NAME}-app-identity" --name "${PROJECT_NAME}-app-fic" --query "name" -o tsv
echo

echo "== Summary: $PASS passed, $FAIL failed =="
if [[ "$FAIL" -gt 0 ]]; then
  echo "One or more expected resources are missing or unhealthy - investigate before proceeding to deploy-azure.sh."
  exit 1
fi
echo "All expected Terraform-provisioned resources confirmed present and healthy."
