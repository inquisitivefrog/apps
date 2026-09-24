#!/usr/bin/env bash
# Azure-target counterpart of deploy.sh/deploy-aws.sh/deploy-gcp.sh. Builds+pushes images to ACR
# (real AKS nodes can't `kind load docker-image` the way kind's version does), points kubectl at
# the real cluster, and applies the Azure-specific manifests in dependency order. Postgres and
# Redis are NOT applied here - they're managed services (Postgres Flexible Server/Managed Redis,
# provisioned by terraform/azure/), not in-cluster StatefulSets on this target. Kafka stays
# self-hosted in-cluster identically to every other target.
#
# Prerequisite: terraform/azure/ must already be applied (see terraform/azure/README.md) - this
# script reads its outputs directly rather than duplicating any endpoint/name as a literal here.
# `node_resource_group`/`redis_port` outputs need a `terraform apply` of the current config before
# this will work (added 2026-09-23, output-only - see README.md).
#
# Redis will NOT actually work end-to-end after this script - Managed Redis is Entra
# ID-token-only and the app has no credential provider for that yet (README.md's "What's next").
# Postgres/Kafka/the rest of the app should work fully; this mirrors AWS's/GCP's own now-identical
# gap (all three clouds need the same follow-up, terraform/azure/README.md's "IAM-auth backport"
# section).
#
# NOT yet live-tested against a real cluster as of 2026-09-23 - written the same way AWS's/GCP's
# scripts were before their own first real runs (which each found real bugs - see deploy-aws.sh's
# --platform linux/amd64 finding and deploy-gcp.sh's three build/push findings). Expect at least
# one Azure-specific bug on the first real run here too; fix forward the same way, don't assume
# this is correct just because it mirrors two working siblings.
set -euo pipefail

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$K8S_DIR")"
TF_DIR="$REPO_ROOT/terraform/azure"

echo "== Reading Terraform outputs =="
TF_OUT="$(cd "$TF_DIR" && terraform output -json)"
jq_out() { echo "$TF_OUT" | python3 -c "import json,sys; print(json.load(sys.stdin)['$1']['value'])"; }

RESOURCE_GROUP="$(jq_out resource_group_name)"
CLUSTER_NAME="$(jq_out aks_cluster_name)"
ACR_LOGIN_SERVER="$(jq_out acr_login_server)"
ACR_NAME="${ACR_LOGIN_SERVER%%.*}" # az acr login wants the short registry name, not the full <name>.azurecr.io hostname
POSTGRES_FQDN="$(jq_out postgres_fqdn)"
POSTGRES_DB="$(jq_out postgres_db_name)"
POSTGRES_USER="$(jq_out postgres_user)"
KEY_VAULT_NAME="$(jq_out key_vault_name)"
POSTGRES_SECRET_NAME="$(jq_out postgres_password_secret_name)"
REDIS_HOST="$(jq_out redis_hostname)"
REDIS_PORT="$(jq_out redis_port)"
APP_IDENTITY_CLIENT_ID="$(jq_out app_identity_client_id)"

echo "== Fetching kubeconfig for $CLUSTER_NAME =="
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

echo "== Authenticating Docker to ACR =="
az acr login --name "$ACR_NAME"

echo "== Building + pushing images (tag: latest, platform: linux/amd64) =="
# --platform linux/amd64 required, not optional, on this dev machine - same reasoning as
# deploy-aws.sh/deploy-gcp.sh: this Mac is Apple Silicon (arm64), Buildx defaults to the host's
# native platform, and the AKS node pool (Standard_D2as_v7, an x86_64 instance family, aks.tf)
# can't run an arm64-only image at all. Both siblings hit "no match for platform in manifest"
# live on their first real deploy without this flag - built in here proactively.
docker build --platform linux/amd64 -t "$ACR_LOGIN_SERVER/api:latest" "$REPO_ROOT/api"
docker build --platform linux/amd64 -t "$ACR_LOGIN_SERVER/frontend:latest" "$REPO_ROOT/frontend"
docker push "$ACR_LOGIN_SERVER/api:latest"
docker push "$ACR_LOGIN_SERVER/frontend:latest"

echo "== Applying Traefik CRDs + RBAC (shared with kind/AWS/GCP) =="
kubectl apply -f "$K8S_DIR/traefik-crds.yaml"
kubectl apply -f "$K8S_DIR/traefik-rbac.yaml"

echo "== Applying Traefik controller (Azure variant - LoadBalancer, not hostPort) =="
kubectl apply -f "$K8S_DIR/traefik-azure.yaml"

echo "== Un-defaulting AKS's own built-in default StorageClass (managed-csi) =="
# Unlike EKS (no default StorageClass at all), AKS auto-marks managed-csi as default at cluster
# creation, the same shape GKE's standard-rwo is - same fix as deploy-gcp.sh's identical step.
kubectl patch storageclass managed-csi \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' \
  2>/dev/null || echo "  (managed-csi not found or already un-defaulted - continuing)"

echo "== Applying default StorageClass (XFS-formatted, needed for Kafka's PVCs) =="
kubectl apply -f "$K8S_DIR/storageclass-azure.yaml"

echo "== Fetching the real Postgres admin password from Key Vault (never hardcoded) =="
POSTGRES_PASSWORD="$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "$POSTGRES_SECRET_NAME" --query value -o tsv)"

echo "== Generating a fresh JWT signing secret for this deployment =="
JWT_SECRET="$(openssl rand -base64 32)"

echo "== Applying secrets (generated at deploy time, never committed) =="
kubectl create secret generic grid-meter-secrets \
  --from-literal=SPRING_DATASOURCE_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=GRID_METER_JWT_SECRET="$JWT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "== Applying config (real Postgres/Redis endpoints, generated at deploy time) =="
# Not a static committed configmap-azure.yaml, deliberately - same reasoning as
# deploy-aws.sh/deploy-gcp.sh: these values are deploy-time facts that would drift the moment
# Postgres/Redis is ever recreated with a new endpoint.
kubectl create configmap grid-meter-config \
  --from-literal=SPRING_PROFILES_ACTIVE=cloud,cloud-azure \
  --from-literal=SPRING_DATASOURCE_URL="jdbc:postgresql://${POSTGRES_FQDN}:5432/${POSTGRES_DB}" \
  --from-literal=SPRING_DATASOURCE_USERNAME="$POSTGRES_USER" \
  --from-literal=SPRING_KAFKA_BOOTSTRAP_SERVERS="kafka-0.kafka-headless:9092,kafka-1.kafka-headless:9092,kafka-2.kafka-headless:9092" \
  --from-literal=SPRING_DATA_REDIS_HOST="$REDIS_HOST" \
  --from-literal=SPRING_DATA_REDIS_PORT="$REDIS_PORT" \
  --from-literal=GRID_METER_TRACING_SAMPLING_PROBABILITY="1.0" \
  --from-literal=JAVA_TOOL_OPTIONS="-Xmx384m" \
  --from-literal=MANAGEMENT_OTLP_METRICS_EXPORT_ENABLED="false" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "== Applying Kafka (self-hosted in-cluster, unchanged from every other target) =="
kubectl apply -f "$K8S_DIR/kafka.yaml"

echo "== Applying api + frontend (real image + Workload Identity client ID baked in before the first apply, not patched after) =="
sed -e "s|PLACEHOLDER_ACR_API_IMAGE|${ACR_LOGIN_SERVER}/api:latest|" \
    -e "s|PLACEHOLDER_APP_IDENTITY_CLIENT_ID|${APP_IDENTITY_CLIENT_ID}|" \
    "$K8S_DIR/api-azure.yaml" | kubectl apply -f -
sed "s|grid-meter-frontend:kind|${ACR_LOGIN_SERVER}/frontend:latest|" "$K8S_DIR/frontend.yaml" | kubectl apply -f -

echo "== Forcing a rollout restart (picks up a freshly-pushed :latest on a repeat run of this script) =="
kubectl rollout restart deployment/api
kubectl rollout restart deployment/frontend

echo "== Applying IngressRoute (target-agnostic - only references Service names) =="
kubectl apply -f "$K8S_DIR/ingressroute.yaml"

echo "== Waiting for rollouts =="
kubectl rollout status deployment/traefik --timeout=180s
kubectl rollout status statefulset/kafka --timeout=180s
kubectl rollout status deployment/api --timeout=240s
kubectl rollout status deployment/frontend --timeout=180s

echo "== Waiting for the LoadBalancer's public IP (provisioning takes a minute or two) =="
# Azure's external LB is IP-based, not DNS-hostname-based like AWS's ELB - same as GCP -
# .status.loadBalancer.ingress[0].ip, not .hostname.
for i in $(seq 1 30); do
  LB_IP="$(kubectl get svc traefik-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  if [[ -n "$LB_IP" ]]; then
    break
  fi
  sleep 5
done

echo
if [[ -n "${LB_IP:-}" ]]; then
  echo "Done. App should be reachable at http://$LB_IP"
else
  echo "Done, but the LoadBalancer IP wasn't assigned within the poll window - check"
  echo "'kubectl get svc traefik-web' directly."
fi
