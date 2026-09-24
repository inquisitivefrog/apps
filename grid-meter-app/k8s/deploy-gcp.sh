#!/usr/bin/env bash
# GCP-target counterpart of deploy.sh/deploy-aws.sh. Builds+pushes images to Artifact Registry
# (real GKE nodes can't `kind load docker-image` the way kind's version does), points kubectl at
# the real cluster, and applies the GCP-specific manifests in dependency order. Cloud SQL and
# Memorystore are NOT applied here - they're managed services (provisioned by terraform/gcp/),
# not in-cluster StatefulSets on this target. Kafka stays self-hosted in-cluster identically to
# every other target.
#
# Prerequisite: terraform/gcp/ must already be applied (see terraform/gcp/README.md) - this
# script reads its outputs directly rather than duplicating any endpoint/name as a literal here.
# Also needs `gke-gcloud-auth-plugin` installed and on $PATH, plus
# `export USE_GKE_GCLOUD_AUTH_PLUGIN=True` - found missing live (2026-09-21) the first time
# kubectl was pointed at this real cluster; every kubectl call fails outright without it (see
# terraform/gcp/README.md's Prerequisites section).
#
# Live-debugged and functionally validated end-to-end (2026-09-21) - see terraform/gcp/README.md's
# "Deploy overlay: now live-debugged and functionally validated" section for the full account (4
# real GCP-specific bugs found and fixed: Artifact Registry paths needing an image-name segment,
# Buildx attestations rejected by GAR, the node SA missing artifactregistry.reader, and real node
# overcommitment needing a 4th node). AWS's proactively-applied fixes (XFS StorageClass, --platform
# linux/amd64, 1Gi api memory) all held up correctly on the first real run - none of AWS's original
# 6 bugs recurred here.
set -euo pipefail

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$K8S_DIR")"
TF_DIR="$REPO_ROOT/terraform/gcp"

echo "== Reading Terraform outputs =="
TF_OUT="$(cd "$TF_DIR" && terraform output -json)"
jq_out() { echo "$TF_OUT" | python3 -c "import json,sys; print(json.load(sys.stdin)['$1']['value'])"; }

PROJECT_ID="$(jq_out gcp_project_id)"
REGION="$(jq_out gcp_region)"
ZONE="$(jq_out gcp_zone)"
CLUSTER_NAME="$(jq_out gke_cluster_name)"
AR_API_URL="$(jq_out artifact_registry_api_repository)"
AR_FRONTEND_URL="$(jq_out artifact_registry_frontend_repository)"
CLOUDSQL_PRIVATE_IP="$(jq_out cloudsql_private_ip)"
CLOUDSQL_USER="$(jq_out cloudsql_user)"
CLOUDSQL_SECRET_ID="$(jq_out cloudsql_password_secret_id)"
MEMORYSTORE_HOST="$(jq_out memorystore_host)"
MEMORYSTORE_PORT="$(jq_out memorystore_port)"
APP_SERVICE_ACCOUNT_EMAIL="$(jq_out app_service_account_email)"
MEMORYSTORE_CA_CERTS="$(jq_out memorystore_server_ca_certificates)"

echo "== Fetching kubeconfig for $CLUSTER_NAME =="
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID"

echo "== Authenticating Docker to Artifact Registry =="
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet --project "$PROJECT_ID"

echo "== Building + pushing images (tag: latest, platform: linux/amd64) =="
# --platform linux/amd64 is required, not optional, on this dev machine specifically - same
# reasoning as deploy-aws.sh: this Mac is Apple Silicon (arm64), and Buildx defaults to the host's
# native platform, but the GKE node pool (e2-medium, an x86_64 instance family, gke.tf) can't run
# an arm64-only image at all. AWS's identical build confirmed "no match for platform in manifest"
# live on its first real deploy attempt with this exact mismatch - built in here proactively
# rather than waiting to rediscover it.
#
# --provenance=false --sbom=false: found live (2026-09-21) on this deploy's first real run - the
# default Buildx build attaches provenance/SBOM attestation manifests to the image, which Artifact
# Registry rejected outright at push time (400 Bad Request on the attestation manifest's own
# digest, after every real image layer had already pushed successfully) - a known, documented
# compatibility gap between newer Buildx attestation formats and Artifact Registry, not something
# specific to this project's config. AWS's ECR never hit this (no attestation-manifest rejection
# seen there), so this flag has no AWS-side equivalent to mirror - a genuinely new, GCP-specific
# finding.
#
# `docker buildx build --push` instead of `docker build` + `docker push`: found live the same
# session, immediately after the fix above - with the attestation manifest gone, the push still
# failed with a 400 on a HEAD request to the "latest" tag itself. Root cause: this machine's
# Docker Desktop uses the containerd image store (`docker info`'s driver-type:
# io.containerd.snapshotter.v1), which round-trips the built image through a local OCI-format
# store before a separate `docker push` re-uploads it - a known compatibility gap with Artifact
# Registry's manifest handling for images that took that path. `buildx build --push` pushes
# directly to the registry from the build itself, never touching the local containerd store's OCI
# export format at all - confirmed as the standard, documented workaround for this exact failure
# shape (GAR + containerd image store), not specific to this project.
docker buildx build --platform linux/amd64 --provenance=false --sbom=false --push -t "$AR_API_URL:latest" "$REPO_ROOT/api"
docker buildx build --platform linux/amd64 --provenance=false --sbom=false --push -t "$AR_FRONTEND_URL:latest" "$REPO_ROOT/frontend"

echo "== Applying Traefik CRDs + RBAC (shared with kind/AWS) =="
kubectl apply -f "$K8S_DIR/traefik-crds.yaml"
kubectl apply -f "$K8S_DIR/traefik-rbac.yaml"

echo "== Applying Traefik controller (GCP variant - LoadBalancer, not hostPort) =="
kubectl apply -f "$K8S_DIR/traefik-gcp.yaml"

echo "== Un-defaulting GKE's own built-in default StorageClass (standard-rwo) =="
# Unlike EKS (which ships with no default StorageClass at all - storageclass-aws.yaml fills a
# genuine absence), GKE auto-marks standard-rwo as default at cluster creation. Two StorageClasses
# can't both carry the is-default-class annotation without an ambiguous result, so this has to be
# explicitly un-defaulted before applying storageclass-gcp.yaml - a real GCP-specific step with no
# AWS equivalent, not copy-pasted from deploy-aws.sh by accident.
kubectl patch storageclass standard-rwo \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' \
  2>/dev/null || echo "  (standard-rwo not found or already un-defaulted - continuing)"

echo "== Applying default StorageClass (XFS-formatted, needed for Kafka's PVCs) =="
kubectl apply -f "$K8S_DIR/storageclass-gcp.yaml"

echo "== Fetching the real Cloud SQL password from Secret Manager (never hardcoded) =="
CLOUDSQL_PASSWORD="$(gcloud secrets versions access latest --secret="$CLOUDSQL_SECRET_ID" --project "$PROJECT_ID")"

echo "== Generating a fresh JWT signing secret for this deployment =="
JWT_SECRET="$(openssl rand -base64 32)"

echo "== Applying secrets (generated at deploy time, never committed) =="
kubectl create secret generic grid-meter-secrets \
  --from-literal=SPRING_DATASOURCE_PASSWORD="$CLOUDSQL_PASSWORD" \
  --from-literal=GRID_METER_JWT_SECRET="$JWT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "== Applying config (real Cloud SQL/Memorystore endpoints, generated at deploy time) =="
# Not a static committed configmap-gcp.yaml, deliberately - same reasoning as deploy-aws.sh: these
# values are deploy-time facts that would drift the moment Cloud SQL/Memorystore is ever recreated
# with a new endpoint.
kubectl create configmap grid-meter-config \
  --from-literal=SPRING_PROFILES_ACTIVE=cloud,cloud-gcp \
  --from-literal=SPRING_DATASOURCE_URL="jdbc:postgresql://${CLOUDSQL_PRIVATE_IP}:5432/gridmeter" \
  --from-literal=SPRING_DATASOURCE_USERNAME="$CLOUDSQL_USER" \
  --from-literal=SPRING_KAFKA_BOOTSTRAP_SERVERS="kafka-0.kafka-headless:9092,kafka-1.kafka-headless:9092,kafka-2.kafka-headless:9092" \
  --from-literal=SPRING_DATA_REDIS_HOST="$MEMORYSTORE_HOST" \
  --from-literal=SPRING_DATA_REDIS_PORT="$MEMORYSTORE_PORT" \
  --from-literal=GRID_METER_GCP_SERVICE_ACCOUNT_EMAIL="$APP_SERVICE_ACCOUNT_EMAIL" \
  --from-literal=GRID_METER_TRACING_SAMPLING_PROBABILITY="1.0" \
  --from-literal=JAVA_TOOL_OPTIONS="-Xmx384m" \
  --from-literal=MANAGEMENT_OTLP_METRICS_EXPORT_ENABLED="false" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "== Applying Memorystore's managed CA cert (needed for GcpRedisConfig's Lettuce trust manager) =="
# Found live (2026-09-24): Memorystore's TLS cert is signed by a private per-instance Google-
# managed CA the JDK's default trust store doesn't recognize - useSsl() alone isn't enough, the
# app needs this cert as an explicit trust anchor. --from-file, not --from-literal: the PEM bundle
# is multi-line and --from-literal would mangle it.
CA_CERT_FILE="$(mktemp)"
printf '%s\n' "$MEMORYSTORE_CA_CERTS" > "$CA_CERT_FILE"
kubectl create configmap grid-meter-memorystore-ca \
  --from-file=ca.pem="$CA_CERT_FILE" \
  --dry-run=client -o yaml | kubectl apply -f -
rm -f "$CA_CERT_FILE"

echo "== Applying Kafka (self-hosted in-cluster, unchanged from every other target) =="
kubectl apply -f "$K8S_DIR/kafka.yaml"

echo "== Applying api + frontend (real image + GCP service account email baked in before the first apply, not patched after) =="
sed -e "s|PLACEHOLDER_ARTIFACT_REGISTRY_API_IMAGE|${AR_API_URL}:latest|" \
    -e "s|PLACEHOLDER_APP_GCP_SERVICE_ACCOUNT_EMAIL|${APP_SERVICE_ACCOUNT_EMAIL}|" \
    "$K8S_DIR/api-gcp.yaml" | kubectl apply -f -
sed "s|grid-meter-frontend:kind|${AR_FRONTEND_URL}:latest|" "$K8S_DIR/frontend.yaml" | kubectl apply -f -

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
# GCP's external LB is IP-based, not DNS-hostname-based like AWS's ELB - .status.loadBalancer.
# ingress[0].ip, not .hostname.
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
