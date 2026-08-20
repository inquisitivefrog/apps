#!/usr/bin/env bash
# Downloads Traefik's official Kubernetes CRD + RBAC manifests (pinned to the v3.7.x line
# already pinned in docs/tech-stack-versions.md) and vendors them into k8s/, so `kubectl apply
# -f k8s/` for the kind demo is fully self-contained and doesn't depend on a live URL/internet
# access at demo time. Re-run this only if the Traefik version pin changes.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$REPO_ROOT/k8s"
mkdir -p "$OUT_DIR"

CRD_URL="https://raw.githubusercontent.com/traefik/traefik/v3.7/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml"
RBAC_URL="https://raw.githubusercontent.com/traefik/traefik/v3.7/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml"

echo "Fetching Traefik CRD definitions..."
curl -fsSL -o "$OUT_DIR/traefik-crds.yaml" "$CRD_URL"
echo "Wrote $OUT_DIR/traefik-crds.yaml ($(wc -l < "$OUT_DIR/traefik-crds.yaml") lines)"

echo "Fetching Traefik RBAC manifest..."
curl -fsSL -o "$OUT_DIR/traefik-rbac.yaml" "$RBAC_URL"
echo "Wrote $OUT_DIR/traefik-rbac.yaml ($(wc -l < "$OUT_DIR/traefik-rbac.yaml") lines)"

echo "Done."
