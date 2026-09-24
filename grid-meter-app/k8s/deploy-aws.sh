#!/usr/bin/env bash
# AWS-target counterpart of deploy.sh. Builds+pushes images to ECR (real EKS nodes can't
# `kind load docker-image` the way kind's version does), points kubectl at the real cluster,
# and applies the AWS-specific manifests in dependency order. Postgres and Redis are NOT applied
# here - they're managed services (RDS/ElastiCache, provisioned by terraform/aws/), not
# in-cluster StatefulSets on this target. Kafka stays self-hosted in-cluster identically to every
# other target.
#
# Prerequisite: terraform/aws/ must already be applied (see terraform/aws/README.md) - this
# script reads its outputs directly rather than duplicating any endpoint/name as a literal here.
set -euo pipefail

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$K8S_DIR")"
TF_DIR="$REPO_ROOT/terraform/aws"

echo "== Reading Terraform outputs =="
TF_OUT="$(cd "$TF_DIR" && terraform output -json)"
CLUSTER_NAME="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["eks_cluster_name"]["value"])')"
AWS_REGION="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["aws_region"]["value"])')"
AWS_PROFILE="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["aws_profile"]["value"])')"
ECR_API_URL="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["ecr_api_repository_url"]["value"])')"
ECR_FRONTEND_URL="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["ecr_frontend_repository_url"]["value"])')"
RDS_ENDPOINT="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["rds_endpoint"]["value"])')"
RDS_USERNAME="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["rds_master_username"]["value"])')"
RDS_SECRET_ARN="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["rds_master_user_secret_arn"]["value"])')"
CACHE_HOST="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["elasticache_endpoint"]["value"])')"
CACHE_PORT="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["elasticache_port"]["value"])')"
APP_IRSA_ROLE_ARN="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["app_irsa_role_arn"]["value"])')"
CACHE_USER_ID="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["elasticache_app_user_id"]["value"])')"
CACHE_REPLICATION_GROUP_ID="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["elasticache_replication_group_id"]["value"])')"

echo "== Updating kubeconfig for $CLUSTER_NAME =="
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE"

echo "== Authenticating Docker to ECR =="
ECR_REGISTRY="${ECR_API_URL%%/*}"
aws ecr get-login-password --region "$AWS_REGION" --profile "$AWS_PROFILE" | \
  docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo "== Building + pushing images (tag: latest, platform: linux/amd64) =="
# Fixed tag, matching this project's own kind-target simplicity (grid-meter-api:kind). ECR's
# repos are MUTABLE (ecr.tf), so a re-push doesn't automatically trigger a rollout on its own -
# the explicit `kubectl rollout restart` near the end of this script is what forces nodes to
# re-pull after any redeploy, not just the image tag changing.
#
# --platform linux/amd64 is required, not optional, on this dev machine specifically: this Mac
# is Apple Silicon (arm64), and Buildx defaults to the host's native platform - the EKS node
# group (t3.medium, an x86_64 instance family) can't run an arm64-only image at all ("no match
# for platform in manifest"), confirmed live on the first real deploy attempt. Building for
# amd64 explicitly matches what the node group's real instance type is, rather than assuming the
# build host's own architecture is the deploy target's.
docker build --platform linux/amd64 -t "$ECR_API_URL:latest" "$REPO_ROOT/api"
docker build --platform linux/amd64 -t "$ECR_FRONTEND_URL:latest" "$REPO_ROOT/frontend"
docker push "$ECR_API_URL:latest"
docker push "$ECR_FRONTEND_URL:latest"

echo "== Applying Traefik CRDs + RBAC (shared with kind) =="
kubectl apply -f "$K8S_DIR/traefik-crds.yaml"
kubectl apply -f "$K8S_DIR/traefik-rbac.yaml"

echo "== Applying Traefik controller (AWS variant - LoadBalancer, not hostPort) =="
kubectl apply -f "$K8S_DIR/traefik-aws.yaml"

echo "== Applying default StorageClass (needed for Kafka's PVCs - EKS 1.30+ doesn't auto-mark one) =="
kubectl apply -f "$K8S_DIR/storageclass-aws.yaml"

echo "== Fetching the real RDS master password from Secrets Manager (never hardcoded) =="
RDS_PASSWORD="$(aws secretsmanager get-secret-value --secret-id "$RDS_SECRET_ARN" \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" --query SecretString --output text | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["password"])')"

echo "== Generating a fresh JWT signing secret for this deployment =="
JWT_SECRET="$(openssl rand -base64 32)"

echo "== Applying secrets (generated at deploy time, never committed) =="
kubectl create secret generic grid-meter-secrets \
  --from-literal=SPRING_DATASOURCE_PASSWORD="$RDS_PASSWORD" \
  --from-literal=GRID_METER_JWT_SECRET="$JWT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "== Applying config (real RDS/ElastiCache endpoints, generated at deploy time) =="
# Not a static committed configmap-aws.yaml, deliberately - these values are deploy-time facts
# (they'd drift the moment RDS/ElastiCache is ever recreated with a new endpoint), same reasoning
# already applied to the redis-entrypoint-script ConfigMap below.
# SPRING_PROFILES_ACTIVE now "cloud,cloud-aws" (was just "cloud") - the extra profile activates
# application.yml's cloud-aws block, which gates config.aws.AwsRedisConfig's bean tree (the
# ElastiCache IAM-auth Lettuce credentials provider). The three new literals below are what that
# config class reads.
kubectl create configmap grid-meter-config \
  --from-literal=SPRING_PROFILES_ACTIVE=cloud,cloud-aws \
  --from-literal=SPRING_DATASOURCE_URL="jdbc:postgresql://${RDS_ENDPOINT}/gridmeter" \
  --from-literal=SPRING_DATASOURCE_USERNAME="$RDS_USERNAME" \
  --from-literal=SPRING_KAFKA_BOOTSTRAP_SERVERS="kafka-0.kafka-headless:9092,kafka-1.kafka-headless:9092,kafka-2.kafka-headless:9092" \
  --from-literal=SPRING_DATA_REDIS_HOST="$CACHE_HOST" \
  --from-literal=SPRING_DATA_REDIS_PORT="$CACHE_PORT" \
  --from-literal=AWS_REGION="$AWS_REGION" \
  --from-literal=GRID_METER_AWS_ELASTICACHE_USER_ID="$CACHE_USER_ID" \
  --from-literal=GRID_METER_AWS_ELASTICACHE_REPLICATION_GROUP_ID="$CACHE_REPLICATION_GROUP_ID" \
  --from-literal=GRID_METER_TRACING_SAMPLING_PROBABILITY="1.0" \
  --from-literal=JAVA_TOOL_OPTIONS="-Xmx384m" \
  --from-literal=MANAGEMENT_OTLP_METRICS_EXPORT_ENABLED="false" \
  --dry-run=client -o yaml | kubectl apply -f -

# Note: deploy.sh generates a redis-entrypoint-script ConfigMap here for redis.yaml/sentinel.yaml
# to mount. Neither of those manifests is applied on this target (Redis is a managed
# ElastiCache endpoint, not a self-hosted StatefulSet) - deliberately skipped, not forgotten.

echo "== Applying Kafka (self-hosted in-cluster, unchanged from every other target) =="
kubectl apply -f "$K8S_DIR/kafka.yaml"

echo "== Applying api + frontend (real image baked in before the first apply, not patched after) =="
# Substituting the real image in before kubectl ever sees the manifest, rather than applying a
# placeholder and patching it afterward (kubectl apply -> set image -> rollout restart) - the
# original apply-then-patch design created three separate ReplicaSets in quick succession on the
# first real deploy (one doomed from the literal placeholder string, two more from the
# subsequent patches), which is wasted churn a single correct apply avoids entirely.
sed -e "s|PLACEHOLDER_ECR_API_IMAGE|${ECR_API_URL}:latest|" \
    -e "s|PLACEHOLDER_APP_IRSA_ROLE_ARN|${APP_IRSA_ROLE_ARN}|" \
    "$K8S_DIR/api-aws.yaml" | kubectl apply -f -
sed "s|grid-meter-frontend:kind|${ECR_FRONTEND_URL}:latest|" "$K8S_DIR/frontend.yaml" | kubectl apply -f -

echo "== Forcing a rollout restart (picks up a freshly-pushed :latest on a repeat run of this script, since the tag string itself doesn't change) =="
kubectl rollout restart deployment/api
kubectl rollout restart deployment/frontend

echo "== Applying IngressRoute (target-agnostic - only references Service names) =="
kubectl apply -f "$K8S_DIR/ingressroute.yaml"

echo "== Waiting for rollouts =="
kubectl rollout status deployment/traefik --timeout=180s
kubectl rollout status statefulset/kafka --timeout=180s
kubectl rollout status deployment/api --timeout=240s
kubectl rollout status deployment/frontend --timeout=180s

echo "== Waiting for the LoadBalancer's public address (provisioning takes a minute or two) =="
for i in $(seq 1 30); do
  LB_HOST="$(kubectl get svc traefik-web -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  if [[ -n "$LB_HOST" ]]; then
    break
  fi
  sleep 5
done

echo
if [[ -n "${LB_HOST:-}" ]]; then
  echo "Done. App should be reachable at http://$LB_HOST"
else
  echo "Done, but the LoadBalancer hostname wasn't assigned within the poll window - check"
  echo "'kubectl get svc traefik-web' directly."
fi
