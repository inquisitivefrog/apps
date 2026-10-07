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
# ECR repos live in bootstrap-freetier/'s persistent state now (2026-10-06, see that module's
# ecr.tf for why), not this one - computed directly from the account ID + region + this
# project's fixed naming convention instead of a cross-state `terraform output` read.
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)"
ECR_API_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/grid-meter-app-api"
ECR_FRONTEND_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/grid-meter-app-frontend"
RDS_ENDPOINT="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["rds_endpoint"]["value"])')"
RDS_USERNAME="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["rds_master_username"]["value"])')"
RDS_SECRET_ARN="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["rds_master_user_secret_arn"]["value"])')"
CACHE_HOST="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["elasticache_endpoint"]["value"])')"
CACHE_PORT="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["elasticache_port"]["value"])')"
CACHE_USER_ID="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["elasticache_app_user_id"]["value"])')"
# Sensitive output, but still present in `terraform output -json` (marked sensitive in its own
# metadata, not omitted) - read from the same $TF_OUT blob as everything else above rather than
# a separate `-raw` call, for consistency.
CACHE_APP_PASSWORD="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["elasticache_app_password"]["value"])')"
VPC_ID="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["vpc_id"]["value"])')"
NLB_SUBNET_ID="$(echo "$TF_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["nlb_subnet_id"]["value"])')"

# Persistent Elastic IP lives in bootstrap-freetier/'s own separate state (2026-10-07, see its
# eip.tf for why - same cross-state read pattern already used for ECR before deploy-aws.sh moved
# to computing that URL directly instead).
EIP_ALLOCATION_ID="$(cd "$TF_DIR/bootstrap-freetier" && terraform output -raw app_eip_allocation_id)"
EIP_PUBLIC_IP="$(cd "$TF_DIR/bootstrap-freetier" && terraform output -raw app_eip_public_ip)"

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

echo "== Installing/upgrading the AWS Load Balancer Controller (needed for traefik-web's pinned-EIP NLB) =="
# No IRSA (same hard SCP block as everywhere else on this account) - the controller instead gets
# its AWS permissions via the EC2 node role (terraform/aws/load-balancer-controller.tf), reached
# over IMDS from wherever its pods land. They'll land on the EC2 node group by default (no
# fargate=true label applied here), which is required for that IMDS path to actually work -
# Fargate pods can't reach node-role credentials at all (same constraint ebs-csi.tf already hit).
helm repo add eks https://aws.github.io/eks-charts >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set region="$AWS_REGION" \
  --set vpcId="$VPC_ID" \
  --wait --timeout 120s

echo "== Applying Traefik CRDs + RBAC (shared with kind) =="
kubectl apply -f "$K8S_DIR/traefik-crds.yaml"
kubectl apply -f "$K8S_DIR/traefik-rbac.yaml"

echo "== Applying Traefik controller (AWS variant - LoadBalancer, not hostPort) =="
# EIP allocation ID and subnet ID are deploy-time facts (same reasoning as api-aws.yaml's image
# placeholder) - substituted here rather than baked into the committed manifest.
sed -e "s|PLACEHOLDER_EIP_ALLOCATION_ID|${EIP_ALLOCATION_ID}|" \
    -e "s|PLACEHOLDER_NLB_SUBNET_ID|${NLB_SUBNET_ID}|" \
    "$K8S_DIR/traefik-aws.yaml" | kubectl apply -f -

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
  --from-literal=GRID_METER_AWS_ELASTICACHE_PASSWORD="$CACHE_APP_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "== Applying config (real RDS/ElastiCache endpoints, generated at deploy time) =="
# Not a static committed configmap-aws.yaml, deliberately - these values are deploy-time facts
# (they'd drift the moment RDS/ElastiCache is ever recreated with a new endpoint), same reasoning
# already applied to the redis-entrypoint-script ConfigMap below.
# SPRING_PROFILES_ACTIVE is "cloud,cloud-aws-password" (not "cloud,cloud-aws") - this account
# can't use IRSA at all (hard SCP block on iam:CreateOpenIDConnectProvider, see
# terraform/aws/elasticache-iam-auth.tf), so the app authenticates to ElastiCache with a real
# password instead of an IAM-signed token. GRID_METER_AWS_ELASTICACHE_USER_ID doubles as the
# Redis AUTH username (see application.yml's cloud-aws-password profile block).
kubectl create configmap grid-meter-config \
  --from-literal=SPRING_PROFILES_ACTIVE=cloud,cloud-aws-password \
  --from-literal=SPRING_DATASOURCE_URL="jdbc:postgresql://${RDS_ENDPOINT}/gridmeter" \
  --from-literal=SPRING_DATASOURCE_USERNAME="$RDS_USERNAME" \
  --from-literal=SPRING_KAFKA_BOOTSTRAP_SERVERS="kafka-0.kafka-headless:9092,kafka-1.kafka-headless:9092,kafka-2.kafka-headless:9092" \
  --from-literal=SPRING_DATA_REDIS_HOST="$CACHE_HOST" \
  --from-literal=SPRING_DATA_REDIS_PORT="$CACHE_PORT" \
  --from-literal=GRID_METER_AWS_ELASTICACHE_USER_ID="$CACHE_USER_ID" \
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
sed "s|PLACEHOLDER_ECR_API_IMAGE|${ECR_API_URL}:latest|" "$K8S_DIR/api-aws.yaml" | kubectl apply -f -
sed "s|grid-meter-frontend:kind|${ECR_FRONTEND_URL}:latest|" "$K8S_DIR/frontend.yaml" | kubectl apply -f -
# frontend.yaml is shared across every target (kind + all three clouds), so the AWS-only
# "fargate: true" label (picked up by terraform/aws/fargate.tf's selector) is patched on here
# rather than baked into that shared manifest - api-aws.yaml/traefik-aws.yaml carry it directly
# since those files are already AWS-specific.
kubectl patch deployment frontend --type=merge \
  -p '{"spec":{"template":{"metadata":{"labels":{"fargate":"true"}}}}}'

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

echo "== Waiting for the NLB to actually provision (confirming, not assuming - provisioning takes a minute or two) =="
for i in $(seq 1 30); do
  LB_HOST="$(kubectl get svc traefik-web -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  if [[ -n "$LB_HOST" ]]; then
    break
  fi
  sleep 5
done

echo
if [[ -n "${LB_HOST:-}" ]]; then
  # The reported URL is the persistent Elastic IP, NOT $LB_HOST - the NLB's own AWS-assigned
  # hostname is just as unstable across nightly rebuilds as the old Classic ELB's was. The whole
  # point of the EIP pinning above is that this address stays the same every day; confirmed the
  # NLB actually came up (not just assumed) via $LB_HOST before reporting it.
  echo "Done. App should be reachable at http://$EIP_PUBLIC_IP (stable across nightly rebuilds)"
else
  echo "Done, but the NLB wasn't confirmed ready within the poll window - check"
  echo "'kubectl get svc traefik-web' directly before trusting http://$EIP_PUBLIC_IP yet."
fi
