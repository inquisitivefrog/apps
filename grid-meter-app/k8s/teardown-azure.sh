#!/usr/bin/env bash
# Azure-target counterpart of teardown-aws.sh/teardown-gcp.sh. Tears down the
# Kubernetes-provisioned Azure resources that `terraform destroy` (terraform/azure/) does NOT
# know about and cannot clean up itself - run this BEFORE terraform destroy, every time. All real
# Azure resources this script cleans up live in AKS's own auto-created node resource group
# (terraform/azure/outputs.tf's node_resource_group, e.g. MC_<rg>_<name>_<region>), NOT the main
# resource group Terraform manages - a real, Azure-specific structural fact neither AWS's nor
# GCP's identical scripts have to account for (see terraform/azure/aks.tf's own header comment).
#
# Three reasons, all found live on AWS/GCP first and applied here proactively rather than waiting
# to rediscover each on Azure too:
#
#   1. The `traefik-web` Service (type LoadBalancer) causes AKS's cloud-controller to provision a
#      real Azure Load Balancer + Public IP in the node resource group. Terraform never created
#      that (kubectl did, indirectly), so `terraform destroy` has no resource block for it and
#      will never delete it.
#   2. Kafka's 3 PVCs cause the Azure Disk CSI driver to provision 3 real Managed Disks, same
#      node-resource-group / no-Terraform-resource-block problem.
#   3. **The `api` Deployment holds live HikariCP connections to Postgres** - GCP's identical
#      script found this live (2026-09-22): `terraform destroy` failed with `pq: database
#      "gridmeter" is being accessed by other users` because Postgres's own destroy has no
#      `depends_on` the cluster's destroy (independent resource graphs in Terraform's eyes, even
#      though the *app* running on the cluster depends on the database). This is generic Postgres
#      connection-draining behavior, not GCP-specific, so it applies here identically - applied
#      proactively as Step 1, not left to be rediscovered against Azure Postgres Flexible Server
#      too.
#
# Confirmed live and clean on its first real run (2026-09-23) - no new bugs found, unlike AWS's
# identical script, which needed the Step 1 fix added only after a real crash-loop was found the
# hard way. Applying that lesson proactively here paid off: `api` released its Postgres
# connections cleanly, the real Azure Load Balancer's public IP was found and confirmed deleted
# via polling, and all 3 real Azure Disks backing Kafka's PVCs were found and confirmed deleted -
# `k8s/check-resources-azure.sh` afterward showed exactly the 5 expected failures (everything this
# script intentionally removed), no unexpected 6th failure the way AWS's first attempt had.
set -euo pipefail

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$K8S_DIR/../terraform/azure"

RESOURCE_GROUP="$(cd "$TF_DIR" && terraform output -raw resource_group_name)"
NODE_RESOURCE_GROUP="$(cd "$TF_DIR" && terraform output -raw node_resource_group)"
echo "Using Azure resource group '$RESOURCE_GROUP' (node resource group: '$NODE_RESOURCE_GROUP')"

echo "== Confirming kubectl is pointed at the right cluster =="
CTX="$(kubectl config current-context)"
echo "Current context: $CTX"
read -p "Proceed with teardown against this context? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

echo
echo "== Step 1: scale 'api' to 0, releasing its live Postgres connections before terraform destroy ever attempts DROP DATABASE =="
API_REPLICAS="$(kubectl get deployment api -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
if [[ -z "$API_REPLICAS" ]]; then
  echo "No 'api' Deployment found - already deleted, or never created. Skipping."
else
  kubectl scale deployment api --replicas=0
  echo "Waiting for 'api' pods to fully terminate (releases their Postgres connections) ..."
  kubectl wait --for=delete pod -l app=api --timeout=120s 2>/dev/null || true
  echo "Confirmed: 'api' pods terminated."
fi

echo
echo "== Step 2: delete the LoadBalancer Service, wait for the real Azure Load Balancer/Public IP to actually disappear =="
LB_IP="$(kubectl get svc traefik-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
if [[ -z "$LB_IP" ]]; then
  echo "No traefik-web LoadBalancer IP found - already deleted, or never created. Skipping."
else
  PIP_NAME="$(az network public-ip list --resource-group "$NODE_RESOURCE_GROUP" \
    --query "[?ipAddress=='$LB_IP'].name" -o tsv 2>/dev/null || true)"
  echo "Found public IP for $LB_IP: ${PIP_NAME:-none found by IP match}"
  kubectl delete svc traefik-web --ignore-not-found
  echo "Waiting for Azure to actually delete it (polling, not a fixed sleep) ..."
  for i in $(seq 1 30); do
    STILL_THERE="$(az network public-ip list --resource-group "$NODE_RESOURCE_GROUP" \
      --query "[?ipAddress=='$LB_IP'].name" -o tsv 2>/dev/null || true)"
    if [[ -z "$STILL_THERE" ]]; then
      echo "Confirmed: public IP for $LB_IP is gone."
      break
    fi
    sleep 10
  done
  STILL_THERE="$(az network public-ip list --resource-group "$NODE_RESOURCE_GROUP" \
    --query "[?ipAddress=='$LB_IP'].name" -o tsv 2>/dev/null || true)"
  if [[ -n "$STILL_THERE" ]]; then
    echo "WARNING: public IP for $LB_IP still exists after 5 minutes of polling - check the" \
         "Azure portal (node resource group '$NODE_RESOURCE_GROUP' -> Load balancing) before" \
         "running terraform destroy."
  fi
fi

echo
echo "== Step 3: stop Kafka (releases its volumes), then delete the PVCs, then wait for the real Managed Disks to actually disappear =="
# A PVC cannot finish deleting - and its Managed Disk cannot actually be released - while a
# running pod still has it mounted (kubernetes.io/pvc-protection finalizer blocks it), same
# reasoning AWS's/GCP's identical scripts found live: the StatefulSet has to go first so the pods
# actually release their volumes before PVC deletion is attempted.
VOLUME_HANDLES="$(kubectl get pv -o jsonpath='{.items[*].spec.csi.volumeHandle}' 2>/dev/null || true)"
if [[ -z "$VOLUME_HANDLES" ]]; then
  echo "No PersistentVolumes found - already deleted, or never created. Skipping."
else
  echo "Found Azure Disks backing current PVs (by resource ID): $VOLUME_HANDLES"
  kubectl delete statefulset kafka --ignore-not-found
  echo "Waiting for Kafka pods to fully terminate (releases the volumes) ..."
  kubectl wait --for=delete pod -l app=kafka --timeout=120s 2>/dev/null || true
  kubectl delete pvc --all -n default --ignore-not-found

  # Azure Disk CSI volumeHandles are full ARM resource IDs
  # (/subscriptions/.../resourceGroups/<node-rg>/providers/Microsoft.Compute/disks/<disk-name>) -
  # `az disk show --ids` accepts the full ID directly, no need to extract just the disk name the
  # way AWS's/GCP's volume-handle formats require.
  echo "Waiting for Azure to actually delete the disks (polling, not a fixed sleep) ..."
  for i in $(seq 1 30); do
    STILL_THERE=0
    for id in $VOLUME_HANDLES; do
      az disk show --ids "$id" >/dev/null 2>&1 && STILL_THERE=1
    done
    if [[ "$STILL_THERE" -eq 0 ]]; then
      echo "Confirmed: all Azure Disks are gone."
      break
    fi
    sleep 10
  done
  STILL_THERE=0
  for id in $VOLUME_HANDLES; do
    az disk show --ids "$id" >/dev/null 2>&1 && STILL_THERE=1
  done
  if [[ "$STILL_THERE" -eq 1 ]]; then
    echo "WARNING: one or more Azure Disks still exist after 5 minutes of polling: $VOLUME_HANDLES -" \
         "check the Azure portal (node resource group '$NODE_RESOURCE_GROUP' -> Disks) before" \
         "running terraform destroy."
  fi
fi

echo
echo "== Step 4: tear down the observability follow-up slice (kube-prometheus-stack + Loki/Tempo/Alloy), if deployed =="
# Optional, separate layer (k8s/deploy-observability.sh) - not part of every deploy-azure.sh run,
# so this step is itself conditional and safe whether or not it was ever applied. Found live
# (2026-09-24, on AWS - same unmodified kube-prometheus-stack-values.yaml used across all three
# clouds, so this holds here too) that none of this carries a real cloud-specific footprint the
# way the LoadBalancer/Managed Disks above do: no persistence is configured for Prometheus, and no
# additional LoadBalancer-type Service exists beyond traefik-web, already handled in Step 2 -
# terraform destroy deleting the whole AKS cluster would clean all of this up regardless. Still
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
echo "== Kubernetes-provisioned Azure resources cleared. Now run: =="
echo "    cd $(cd "$K8S_DIR/../terraform/azure" && pwd)"
echo "    terraform plan -destroy"
echo "    terraform destroy"
echo
echo "(Deliberately not run automatically from this script - real, hard-to-reverse infrastructure"
echo " teardown should be a deliberate, reviewed step, not chained onto a kubectl cleanup script.)"
