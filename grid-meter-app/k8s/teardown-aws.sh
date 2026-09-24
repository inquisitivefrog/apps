#!/usr/bin/env bash
# Tears down the Kubernetes-provisioned AWS resources that `terraform destroy` (terraform/aws/)
# does NOT know about and cannot clean up itself - run this BEFORE terraform destroy, every time.
#
# Why this has to run first, not just "also run at some point":
#
#   1. The `traefik-web` Service (type LoadBalancer) caused the EKS cloud-controller to provision
#      a real AWS load balancer (confirmed live 2026-09-18: a Classic ELB, not the NLB originally
#      assumed - traefik-aws.yaml's Service has no aws-load-balancer-type annotation and this
#      cluster has no AWS Load Balancer Controller addon, so EKS's in-tree default provisioned a
#      Classic ELB instead), with its own ENIs in this VPC's subnets. Terraform never created that
#      load balancer (kubectl did, indirectly), so `terraform destroy` has no resource block for
#      it and will never delete it. Worse: if the VPC/subnets/security groups are destroyed while
#      its ENIs are still attached, AWS will refuse to delete them - `terraform destroy` can hang
#      or fail partway through on exactly those resources. Deleting the Service first triggers the
#      cloud-controller to clean up the load balancer itself, before Terraform ever touches the
#      VPC.
#   2. Kafka's 3 PVCs caused the EBS CSI driver to provision 3 real 12Gi gp3 volumes. Same
#      problem: Terraform never created them. Deleting the PVCs (StorageClass reclaimPolicy:
#      Delete, confirmed live) is what actually triggers the CSI driver to call EC2's
#      DeleteVolume - skipping this step leaves 3 orphaned, still-billed EBS volumes sitting in
#      the account indefinitely after the cluster is long gone, with no Terraform resource left
#      to ever clean them up.
#   3. **The `api` Deployment hard-crashes once Kafka is gone, not just degrades** - found live
#      (2026-09-23) running this script for real without scaling `api` down first: Spring Kafka's
#      `@KafkaListener` container creation is NOT lazy, it happens eagerly during
#      ApplicationContext startup, and `kafka-headless`'s per-pod DNS records
#      (`kafka-0.kafka-headless` etc.) stop resolving the moment the StatefulSet's pods are gone -
#      `ConfigException: No resolvable bootstrap urls given in bootstrap.servers` fails the whole
#      context refresh, crash-looping `api` indefinitely (CrashLoopBackOff) rather than just
#      degrading. Same underlying shape as GCP's teardown-gcp.sh's own Step 1 fix (an `api`
#      Deployment left running against infrastructure mid-teardown), different mechanism (Kafka
#      DNS resolution at eager consumer-startup time here, vs. live HikariCP connections blocking
#      `DROP DATABASE` there) - `teardown-aws.sh` never got the equivalent fix until now.
#
# Confirmed live (2026-09-18) before writing this: `kubectl get svc -A` showed exactly one
# LoadBalancer-type Service (traefik-web) and `kubectl get pvc -A` showed exactly 3 Bound PVCs,
# both matching what this script handles - re-check with the same commands if the app's manifests
# ever grow a second LoadBalancer Service or additional PVCs, since this script only targets what
# exists today.
set -euo pipefail

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$K8S_DIR/../terraform/aws"

# Read the profile/region from Terraform's own outputs rather than hardcoding or relying on the
# AWS CLI's default profile - the default profile is dead in this account (same class of bug
# backend.tf hit earlier: a literal must be used or it silently falls back to `default`).
AWS_PROFILE="$(cd "$TF_DIR" && terraform output -raw aws_profile)"
AWS_REGION="$(cd "$TF_DIR" && terraform output -raw aws_region)"
export AWS_PROFILE AWS_REGION
echo "Using AWS profile '$AWS_PROFILE' in region '$AWS_REGION'"

echo "== Confirming kubectl is pointed at the right cluster =="
CTX="$(kubectl config current-context)"
echo "Current context: $CTX"
read -p "Proceed with teardown against this context? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

echo
echo "== Step 1: scale 'api' to 0 - it hard-crashes (CrashLoopBackOff) the moment Kafka's DNS records disappear below, not just degrades =="
API_REPLICAS="$(kubectl get deployment api -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
if [[ -z "$API_REPLICAS" ]]; then
  echo "No 'api' Deployment found - already deleted, or never created. Skipping."
else
  kubectl scale deployment api --replicas=0
  echo "Waiting for 'api' pods to fully terminate ..."
  kubectl wait --for=delete pod -l app=api --timeout=120s 2>/dev/null || true
  echo "Confirmed: 'api' pods terminated."
fi

echo
echo "== Step 2: delete the LoadBalancer Service, wait for the real load balancer to actually disappear =="
# traefik-aws.yaml's Service carries no service.beta.kubernetes.io/aws-load-balancer-type
# annotation, and this cluster has no AWS Load Balancer Controller addon - so EKS's default
# in-tree provider is what provisions this, which means it could be EITHER a Classic ELB (the
# elbv2 API can't see these at all) or an NLB/ALB, depending on the cluster's default. Confirmed
# live (2026-09-18): `aws elbv2 describe-load-balancers` found nothing for a real, working
# load-balanced Service - proving it was actually a Classic ELB, not an NLB as originally assumed
# and never actually verified. Checking both APIs here rather than assuming either one.
LB_HOST="$(kubectl get svc traefik-web -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
if [[ -z "$LB_HOST" ]]; then
  echo "No traefik-web LoadBalancer hostname found - already deleted, or never created. Skipping."
else
  LB_ARN="$(aws elbv2 describe-load-balancers --query "LoadBalancers[?DNSName=='$LB_HOST'].LoadBalancerArn" --output text 2>/dev/null || true)"
  CLB_NAME="$(aws elb describe-load-balancers --query "LoadBalancerDescriptions[?DNSName=='$LB_HOST'].LoadBalancerName" --output text 2>/dev/null || true)"
  echo "Found load balancer: $LB_HOST (elbv2 ARN: ${LB_ARN:-none}, classic ELB name: ${CLB_NAME:-none})"
  kubectl delete svc traefik-web --ignore-not-found
  echo "Waiting for AWS to actually delete it (polling, not a fixed sleep) ..."
  for i in $(seq 1 30); do
    STILL_THERE=0
    [[ -n "$LB_ARN" ]] && aws elbv2 describe-load-balancers --load-balancer-arns "$LB_ARN" >/dev/null 2>&1 && STILL_THERE=1
    [[ -n "$CLB_NAME" ]] && aws elb describe-load-balancers --load-balancer-names "$CLB_NAME" >/dev/null 2>&1 && STILL_THERE=1
    if [[ "$STILL_THERE" -eq 0 ]]; then
      echo "Confirmed: load balancer for $LB_HOST is gone."
      break
    fi
    sleep 10
  done
  STILL_THERE=0
  [[ -n "$LB_ARN" ]] && aws elbv2 describe-load-balancers --load-balancer-arns "$LB_ARN" >/dev/null 2>&1 && STILL_THERE=1
  [[ -n "$CLB_NAME" ]] && aws elb describe-load-balancers --load-balancer-names "$CLB_NAME" >/dev/null 2>&1 && STILL_THERE=1
  if [[ "$STILL_THERE" -eq 1 ]]; then
    echo "WARNING: load balancer for $LB_HOST still exists after 5 minutes of polling - check the" \
         "AWS console (EC2 -> Load Balancers) before running terraform destroy."
  fi
fi

echo
echo "== Step 3: stop Kafka (releases its volumes), then delete the PVCs, then wait for the real EBS volumes to actually disappear =="
# A PVC cannot finish deleting - and its EBS volume cannot actually be released - while a running
# pod still has it mounted (kubernetes.io/pvc-protection finalizer blocks it). Confirmed live
# (2026-09-18): deleting the PVCs first, with kafka-0/1/2 still Running, left all 3 PVCs stuck in
# Terminating indefinitely ("Used By: kafka-0" in `kubectl describe pvc`) - the StatefulSet has to
# go first so the pods actually release their volumes.
VOLUME_IDS="$(kubectl get pv -o jsonpath='{.items[*].spec.csi.volumeHandle}' 2>/dev/null || true)"
if [[ -z "$VOLUME_IDS" ]]; then
  echo "No PersistentVolumes found - already deleted, or never created. Skipping."
else
  echo "Found EBS volumes backing current PVs: $VOLUME_IDS"
  kubectl delete statefulset kafka --ignore-not-found
  echo "Waiting for Kafka pods to fully terminate (releases the volumes) ..."
  kubectl wait --for=delete pod -l app=kafka --timeout=120s 2>/dev/null || true
  kubectl delete pvc --all -n default --ignore-not-found
  echo "Waiting for AWS to actually delete the EBS volumes (polling, not a fixed sleep) ..."
  for i in $(seq 1 30); do
    REMAINING="$(aws ec2 describe-volumes --volume-ids $VOLUME_IDS \
      --query 'Volumes[].VolumeId' --output text 2>/dev/null || true)"
    if [[ -z "$REMAINING" ]]; then
      echo "Confirmed: all EBS volumes are gone."
      break
    fi
    sleep 10
  done
  REMAINING="$(aws ec2 describe-volumes --volume-ids $VOLUME_IDS \
    --query 'Volumes[].VolumeId' --output text 2>/dev/null || true)"
  if [[ -n "$REMAINING" ]]; then
    echo "WARNING: these volumes still exist after 5 minutes of polling: $REMAINING - check the" \
         "AWS console (EC2 -> Volumes) before running terraform destroy."
  fi
fi

echo
echo "== Step 4: tear down the observability follow-up slice (kube-prometheus-stack + Loki/Tempo/Alloy), if deployed =="
# Optional, separate layer (k8s/deploy-observability.sh) - not part of every deploy-aws.sh run,
# so this step is itself conditional and safe whether or not it was ever applied. Found live
# (2026-09-24) that none of this carries a real AWS-specific footprint the way the
# LoadBalancer/PVCs above do: no persistence is configured in kube-prometheus-stack-values.yaml
# (confirmed - no PVC showed up for Prometheus after a real deploy), and no additional
# LoadBalancer-type Service exists beyond traefik-web, already handled in Step 2 - terraform
# destroy deleting the whole EKS cluster would clean all of this up regardless. Still done
# explicitly here, matching Steps 2/3's own reasoning: kubectl-applied resources get torn down via
# kubectl, not left to chance, and this stays correct even if a future change (persistence, or a
# publicly-exposed Grafana LoadBalancer) introduces a real footprint later.
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
echo "== Kubernetes-provisioned AWS resources cleared. Now run: =="
echo "    cd $(cd "$K8S_DIR/../terraform/aws" && pwd)"
echo "    terraform plan -destroy"
echo "    terraform destroy"
echo
echo "(Deliberately not run automatically from this script - real, hard-to-reverse infrastructure"
echo " teardown should be a deliberate, reviewed step, not chained onto a kubectl cleanup script.)"
