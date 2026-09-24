#!/usr/bin/env bash
# Kubernetes-layer counterpart to terraform/aws/check-resources-aws.sh - confirms every object
# deploy-aws.sh is supposed to create actually exists and is healthy on the real cluster, queried
# directly via kubectl, not trusted from `kubectl rollout status`'s own "successfully rolled out"
# message alone. Intended to run right after deploy-aws.sh, before a demo or before
# teardown-aws.sh.
set -uo pipefail

PASS=0
FAIL=0

# check <label> <expect> <command...>  - runs the command, compares trimmed output to <expect>
# ("any" skips the comparison and just requires non-empty, error-free output). Never aborts on a
# single failure - the point is a full report, not a fail-fast script.
#
# Checks the command's own exit code explicitly, not just whether it printed something -
# confirmed live (2026-09-18) that kubectl's "Error from server (NotFound): ... not found" text
# is itself non-empty output, so an "any"-expectation check on a resource that doesn't exist at
# all was silently reporting PASS on the error message text before this fix.
check() {
  local label="$1" expect="$2"; shift 2
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  local trimmed
  trimmed="$(echo "$out" | tr -d '[:space:]')"
  if [[ $rc -ne 0 || -z "$trimmed" ]]; then
    echo "  FAIL  $label: not found / error - $out"
    FAIL=$((FAIL+1))
  elif [[ "$expect" == "any" || "$trimmed" == "$expect" ]]; then
    echo "  PASS  $label: $trimmed"
    PASS=$((PASS+1))
  else
    echo "  FAIL  $label: expected '$expect', got '$trimmed'"
    FAIL=$((FAIL+1))
  fi
}

CTX="$(kubectl config current-context 2>&1)"
echo "== Checking Kubernetes-deployed app layer (context: $CTX) =="
echo

echo "-- Traefik --"
check "Traefik Deployment ready" "1/1" kubectl get deployment traefik -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
check "traefik-web Service type" "LoadBalancer" kubectl get svc traefik-web -o jsonpath='{.spec.type}'
check "traefik-web external hostname assigned" any kubectl get svc traefik-web -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
check "traefik-metrics Service exists" "ClusterIP" kubectl get svc traefik-metrics -o jsonpath='{.spec.type}'
echo

echo "-- Kafka --"
check "Kafka StatefulSet ready replicas" "3" kubectl get statefulset kafka -o jsonpath='{.status.readyReplicas}'
check "kafka-headless Service exists" "None" kubectl get svc kafka-headless -o jsonpath='{.spec.clusterIP}'
check "Kafka PVCs bound (expect 3)" "3" bash -c "kubectl get pvc --no-headers 2>/dev/null | grep -c '^kafka-data.*Bound' || true"
echo

echo "-- api / frontend --"
check "api Deployment ready" "2/2" kubectl get deployment api -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
check "api Service exists" "ClusterIP" kubectl get svc api -o jsonpath='{.spec.type}'
check "frontend Deployment ready" "1/1" kubectl get deployment frontend -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
check "frontend Service exists" "ClusterIP" kubectl get svc frontend -o jsonpath='{.spec.type}'
echo

echo "-- Config/secrets/routing --"
check "grid-meter-config ConfigMap exists" any kubectl get configmap grid-meter-config -o jsonpath='{.metadata.name}'
check "grid-meter-secrets Secret exists" any kubectl get secret grid-meter-secrets -o jsonpath='{.metadata.name}'
check "IngressRoute exists" any kubectl get ingressroute grid-meter -o jsonpath='{.metadata.name}'
check "gp3 StorageClass is default" "true" kubectl get storageclass gp3 -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}'
echo

echo "-- Observability (optional; only checked if deployed via k8s/deploy-observability.sh) --"
if kubectl get deployment loki >/dev/null 2>&1; then
  check "kube-prometheus-stack-grafana Deployment ready" "1/1" kubectl get deployment kube-prometheus-stack-grafana -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
  check "Prometheus StatefulSet ready replicas" "1" kubectl get statefulset prometheus-kube-prometheus-stack-prometheus -o jsonpath='{.status.readyReplicas}'
  check "Loki Deployment ready" "1/1" kubectl get deployment loki -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
  check "Tempo Deployment ready" "1/1" kubectl get deployment tempo -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
  check "Alloy Deployment ready" "1/1" kubectl get deployment alloy -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
  check "grid-meter-api ServiceMonitor exists" any kubectl get servicemonitor grid-meter-api -o jsonpath='{.metadata.name}'
else
  echo "  (not deployed - skipping; run k8s/deploy-observability.sh first if this cluster should have it)"
fi
echo

echo "== Summary: $PASS passed, $FAIL failed =="
if [[ "$FAIL" -gt 0 ]]; then
  echo "One or more expected Kubernetes objects are missing or unhealthy - investigate before demoing."
  exit 1
fi
echo "All expected Kubernetes-deployed resources confirmed present and healthy."
