#!/usr/bin/env bash
# Builds the api/frontend images, creates (or reuses) the kind cluster, loads the images into it,
# and applies every manifest in dependency order (CRDs/RBAC before the IngressRoute that needs
# them, data tier before the api that depends on it). See k8s/README.md for the manual
# step-by-step this automates, and for what "apply order matters" actually means here.
set -euo pipefail

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$K8S_DIR")"
CLUSTER_NAME="grid-meter"

echo "== Building images =="
docker build -t grid-meter-api:kind "$REPO_ROOT/api"
docker build -t grid-meter-frontend:kind "$REPO_ROOT/frontend"

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "== kind cluster '$CLUSTER_NAME' already exists, reusing =="
else
  echo "== Creating kind cluster '$CLUSTER_NAME' =="
  kind create cluster --config "$K8S_DIR/kind-config.yaml"
fi

echo "== Loading images into kind =="
kind load docker-image grid-meter-api:kind --name "$CLUSTER_NAME"
kind load docker-image grid-meter-frontend:kind --name "$CLUSTER_NAME"

echo "== Applying Traefik CRDs + RBAC =="
kubectl apply -f "$K8S_DIR/traefik-crds.yaml"
kubectl apply -f "$K8S_DIR/traefik-rbac.yaml"

echo "== Applying Traefik controller =="
kubectl apply -f "$K8S_DIR/traefik.yaml"

echo "== Applying config/secrets =="
kubectl apply -f "$K8S_DIR/configmap.yaml"
kubectl apply -f "$K8S_DIR/secret.yaml"

echo "== Applying data tier =="
kubectl apply -f "$K8S_DIR/postgres.yaml"
kubectl apply -f "$K8S_DIR/kafka.yaml"
kubectl apply -f "$K8S_DIR/redis.yaml"

echo "== Applying api + frontend =="
kubectl apply -f "$K8S_DIR/api.yaml"
kubectl apply -f "$K8S_DIR/frontend.yaml"

echo "== Applying IngressRoute =="
kubectl apply -f "$K8S_DIR/ingressroute.yaml"

echo "== Waiting for rollouts =="
kubectl rollout status deployment/traefik --timeout=120s
kubectl rollout status deployment/postgres --timeout=120s
kubectl rollout status deployment/kafka --timeout=120s
kubectl rollout status deployment/redis --timeout=120s
kubectl rollout status deployment/api --timeout=180s
kubectl rollout status deployment/frontend --timeout=120s

echo
echo "Done. App should be reachable at http://localhost"
