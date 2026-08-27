#!/usr/bin/env bash
# k8s observability follow-up slice: kube-prometheus-stack (Helm, cluster/node metrics + the one
# unified Prometheus/Grafana pair) plus Loki/Tempo/Alloy (plain YAML, app logs/traces). Run
# ./k8s/deploy.sh first -- this assumes the grid-meter kind cluster and first-slice app are
# already up. See k8s/README.md's "Observability follow-up slice" section for design notes.
set -euo pipefail

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$K8S_DIR")"
OBS_DIR="$REPO_ROOT/observability"

echo "== Adding/updating the prometheus-community Helm repo =="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

# Generated from the same source files Compose mounts directly, so the two environments share one
# source of truth instead of duplicating YAML/JSON content into hand-written k8s manifests.
echo "== Generating ConfigMaps from observability/ source files =="
kubectl create configmap grid-meter-grafana-alerting \
  --from-file=rules.yaml="$OBS_DIR/alerting/rules.yml" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap grid-meter-grafana-dashboard \
  --from-file=grid-meter-overview.json="$OBS_DIR/dashboards/grid-meter-overview.json" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label configmap grid-meter-grafana-dashboard grafana_dashboard=1 --overwrite >/dev/null

kubectl create configmap grid-meter-tempo-config \
  --from-file=tempo.yml="$OBS_DIR/tempo.yml" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap grid-meter-alloy-config \
  --from-file=config.alloy="$OBS_DIR/alloy-k8s.river" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "== Installing/upgrading kube-prometheus-stack =="
# 8m, not 5m: a truly cold `kind create cluster` run (fresh image pulls, no cached layers) can
# take Grafana most of that just to finish its own boot + provisioning -- see k8s/README.md's
# "Real bugs found" section for the SQLite-lock-contention restart this was sized against.
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version 88.5.4 \
  --namespace default \
  -f "$K8S_DIR/kube-prometheus-stack-values.yaml" \
  --wait --timeout 8m

echo "== Re-applying traefik.yaml (adds --metrics.prometheus and the metrics Service) =="
kubectl apply -f "$K8S_DIR/traefik.yaml"

echo "== Applying Loki, Tempo, Alloy =="
kubectl apply -f "$K8S_DIR/loki.yaml"
kubectl apply -f "$K8S_DIR/tempo.yaml"
kubectl apply -f "$K8S_DIR/alloy.yaml"

echo "== Applying the api ServiceMonitor (needs the CRD kube-prometheus-stack just installed) =="
kubectl apply -f "$K8S_DIR/servicemonitor-api.yaml"

echo "== Waiting for rollouts =="
kubectl rollout status deployment/loki --timeout=120s
kubectl rollout status deployment/tempo --timeout=120s
kubectl rollout status deployment/alloy --timeout=120s
kubectl rollout status deployment/kube-prometheus-stack-grafana --timeout=180s

echo
echo "Done. Grafana: kubectl port-forward svc/kube-prometheus-stack-grafana 3001:80"
echo "      Prometheus: kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090"
