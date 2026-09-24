#!/usr/bin/env bash
# GCP-target counterpart of teardown-aws.sh. Tears down the Kubernetes-provisioned GCP resources
# that `terraform destroy` (terraform/gcp/) does NOT know about and cannot clean up itself - run
# this BEFORE terraform destroy, every time. Three reasons, the third found live (2026-09-22):
#
#   1. The `traefik-web` Service (type LoadBalancer) causes GKE's cloud-controller to provision a
#      real GCP forwarding rule + backing LB resources. Terraform never created that (kubectl did,
#      indirectly), so `terraform destroy` has no resource block for it and will never delete it.
#   2. Kafka's 3 PVCs cause the GCE PD CSI driver to provision 3 real persistent disks. Same
#      problem - deleting the PVCs (StorageClass reclaimPolicy: Delete, storageclass-gcp.yaml) is
#      what actually triggers the CSI driver to call Compute Engine's DeleteDisk.
#   3. **The `api` Deployment holds live HikariCP connections to Cloud SQL** - found live when this
#      script was skipped entirely and `terraform destroy` failed with `pq: database "gridmeter" is
#      being accessed by other users`. `google_sql_database.main`'s destroy has no `depends_on` the
#      GKE cluster's own destroy (they're independent resource graphs in Terraform's eyes, even
#      though the *app* running on the cluster depends on the database) - Terraform attempted
#      `DROP DATABASE` in the same early batch as everything else, while the `api` pods were still
#      live and connected. A retry after the cluster was fully destroyed succeeded (the connections
#      were gone along with the pods), but that's an accidental fix via a much bigger, slower
#      hammer than necessary - scaling `api` to 0 here, before anything else, closes the gap
#      directly and cheaply.
#
# Needs `gke-gcloud-auth-plugin` installed and on $PATH, plus
# `export USE_GKE_GCLOUD_AUTH_PLUGIN=True` - every kubectl call fails outright without it (see
# terraform/gcp/README.md's Prerequisites section).
#
# deploy-gcp.sh has been live-debugged and functionally validated (2026-09-21, see
# terraform/gcp/README.md), which also answered this script's own open question: a plain
# `type: LoadBalancer` Service resolves to the legacy target-pool-based external Network LB here
# (confirmed via `gcloud compute forwarding-rules list`'s target field pointing at
# `targetPools/...`, not a backend service) - worth having actually checked, since AWS's identical
# assumption ("it'll be an NLB") turned out wrong when finally checked there (it was a Classic
# ELB). This teardown script itself has now run for real too (2026-09-21) - clean on the first
# try, both the forwarding rule and all 3 persistent disks confirmed actually gone via live
# polling, no bugs found. It queries forwarding rules by IP address, which exists for either LB
# flavor, specifically so it didn't need to guess which one before this was confirmed.
set -euo pipefail

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$K8S_DIR/../terraform/gcp"

PROJECT_ID="$(cd "$TF_DIR" && terraform output -raw gcp_project_id)"
REGION="$(cd "$TF_DIR" && terraform output -raw gcp_region)"
echo "Using GCP project '$PROJECT_ID' in region '$REGION'"

echo "== Confirming kubectl is pointed at the right cluster =="
CTX="$(kubectl config current-context)"
echo "Current context: $CTX"
read -p "Proceed with teardown against this context? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

echo
echo "== Step 1: scale 'api' to 0, releasing its live Cloud SQL connections before terraform destroy ever attempts DROP DATABASE =="
API_REPLICAS="$(kubectl get deployment api -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
if [[ -z "$API_REPLICAS" ]]; then
  echo "No 'api' Deployment found - already deleted, or never created. Skipping."
else
  kubectl scale deployment api --replicas=0
  echo "Waiting for 'api' pods to fully terminate (releases their Cloud SQL connections) ..."
  kubectl wait --for=delete pod -l app=api --timeout=120s 2>/dev/null || true
  echo "Confirmed: 'api' pods terminated."
fi

echo
echo "== Step 2: delete the LoadBalancer Service, wait for the real GCP forwarding rule to actually disappear =="
LB_IP="$(kubectl get svc traefik-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
if [[ -z "$LB_IP" ]]; then
  echo "No traefik-web LoadBalancer IP found - already deleted, or never created. Skipping."
else
  FR_NAME="$(gcloud compute forwarding-rules list --project "$PROJECT_ID" \
    --filter="IPAddress=$LB_IP" --format="value(name)" 2>/dev/null || true)"
  echo "Found forwarding rule for $LB_IP: ${FR_NAME:-none found by IP match}"
  kubectl delete svc traefik-web --ignore-not-found
  echo "Waiting for GCP to actually delete it (polling, not a fixed sleep) ..."
  for i in $(seq 1 30); do
    STILL_THERE="$(gcloud compute forwarding-rules list --project "$PROJECT_ID" \
      --filter="IPAddress=$LB_IP" --format="value(name)" 2>/dev/null || true)"
    if [[ -z "$STILL_THERE" ]]; then
      echo "Confirmed: forwarding rule for $LB_IP is gone."
      break
    fi
    sleep 10
  done
  STILL_THERE="$(gcloud compute forwarding-rules list --project "$PROJECT_ID" \
    --filter="IPAddress=$LB_IP" --format="value(name)" 2>/dev/null || true)"
  if [[ -n "$STILL_THERE" ]]; then
    echo "WARNING: forwarding rule for $LB_IP still exists after 5 minutes of polling - check the" \
         "GCP console (Network Services -> Load Balancing) before running terraform destroy."
  fi
fi

echo
echo "== Step 3: stop Kafka (releases its volumes), then delete the PVCs, then wait for the real persistent disks to actually disappear =="
# A PVC cannot finish deleting - and its underlying disk cannot actually be released - while a
# running pod still has it mounted (kubernetes.io/pvc-protection finalizer blocks it) - same
# reasoning AWS's teardown-aws.sh found live (2026-09-18): the StatefulSet has to go first so the
# pods actually release their volumes before PVC deletion is attempted.
VOLUME_HANDLES="$(kubectl get pv -o jsonpath='{.items[*].spec.csi.volumeHandle}' 2>/dev/null || true)"
if [[ -z "$VOLUME_HANDLES" ]]; then
  echo "No PersistentVolumes found - already deleted, or never created. Skipping."
else
  echo "Found persistent disks backing current PVs: $VOLUME_HANDLES"
  kubectl delete statefulset kafka --ignore-not-found
  echo "Waiting for Kafka pods to fully terminate (releases the volumes) ..."
  kubectl wait --for=delete pod -l app=kafka --timeout=120s 2>/dev/null || true
  kubectl delete pvc --all -n default --ignore-not-found

  # GCE PD CSI volumeHandles are shaped like
  # projects/<project>/zones/<zone>/disks/<disk-name> - extract just the disk name. Deliberately
  # queried via `gcloud compute disks list` (zone-less, searches every zone), NOT `describe
  # --zone "$ZONE"` - Kafka's 3 nodes spread across all 3 zones in gke_node_locations
  # (us-central1-a/b/c, variables.tf), not just this cluster's single control-plane zone, so a
  # disk can legitimately live in a zone `describe --zone "$ZONE"` would never find it in.
  DISK_NAMES=""
  for handle in $VOLUME_HANDLES; do
    DISK_NAMES="$DISK_NAMES ${handle##*/}"
  done

  echo "Waiting for GCP to actually delete the persistent disks (polling, not a fixed sleep) ..."
  for i in $(seq 1 30); do
    STILL_THERE=0
    for name in $DISK_NAMES; do
      [[ -n "$(gcloud compute disks list --project "$PROJECT_ID" --filter="name=$name" --format="value(name)" 2>/dev/null)" ]] && STILL_THERE=1
    done
    if [[ "$STILL_THERE" -eq 0 ]]; then
      echo "Confirmed: all persistent disks are gone."
      break
    fi
    sleep 10
  done
  STILL_THERE=0
  for name in $DISK_NAMES; do
    [[ -n "$(gcloud compute disks list --project "$PROJECT_ID" --filter="name=$name" --format="value(name)" 2>/dev/null)" ]] && STILL_THERE=1
  done
  if [[ "$STILL_THERE" -eq 1 ]]; then
    echo "WARNING: one or more persistent disks still exist after 5 minutes of polling: $DISK_NAMES -" \
         "check the GCP console (Compute Engine -> Disks) before running terraform destroy."
  fi
fi

echo
echo "== Step 4: tear down the observability follow-up slice (kube-prometheus-stack + Loki/Tempo/Alloy), if deployed =="
# Optional, separate layer (k8s/deploy-observability.sh) - not part of every deploy-gcp.sh run,
# so this step is itself conditional and safe whether or not it was ever applied. Found live
# (2026-09-24, on AWS - same unmodified kube-prometheus-stack-values.yaml used across all three
# clouds, so this holds here too) that none of this carries a real cloud-specific footprint the
# way the LoadBalancer/PVCs above do: no persistence is configured for Prometheus, and no
# additional LoadBalancer-type Service exists beyond traefik-web, already handled in Step 2 -
# terraform destroy deleting the whole GKE cluster would clean all of this up regardless. Still
# done explicitly here, matching Steps 2/3's own reasoning: kubectl-applied resources get torn
# down via kubectl, not left to chance, and this stays correct even if a future change
# (persistence, or a publicly-exposed Grafana LoadBalancer) introduces a real footprint later.
if helm status kube-prometheus-stack >/dev/null 2>&1; then
  helm uninstall kube-prometheus-stack
  kubectl delete -f "$K8S_DIR/servicemonitor-api.yaml" --ignore-not-found
  kubectl delete -f "$K8S_DIR/alloy.yaml" --ignore-not-found
  kubectl delete -f "$K8S_DIR/tempo.yaml" --ignore-not-found
  kubectl delete -f "$K8S_DIR/loki.yaml" --ignore-not-found
  kubectl delete configmap grid-meter-grafana-alerting grid-meter-grafana-dashboard grid-meter-tempo-config grid-meter-alloy-config --ignore-not-found
  echo "Confirmed: observability follow-up slice removed."
else
  echo "kube-prometheus-stack Helm release not found - observability was never deployed, or already torn down. Skipping."
fi

echo
echo "== Kubernetes-provisioned GCP resources cleared. Now run: =="
echo "    cd $(cd "$K8S_DIR/../terraform/gcp" && pwd)"
echo "    terraform plan -destroy"
echo "    terraform destroy"
echo
echo "(Deliberately not run automatically from this script - real, hard-to-reverse infrastructure"
echo " teardown should be a deliberate, reviewed step, not chained onto a kubectl cleanup script.)"
