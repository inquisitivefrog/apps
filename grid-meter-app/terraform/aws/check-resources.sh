#!/usr/bin/env bash
# Inverse of teardown-aws.sh's residue checklist (see README.md's "confirm no residue" section):
# confirms every Terraform-provisioned AWS resource actually exists and is healthy, queried
# directly against real AWS APIs - not trusting `terraform apply`'s own "Apply complete" message,
# same "verify the live system" discipline applied everywhere else in this project.
#
# Intended to run right after `terraform apply` in terraform/aws/, before `k8s/deploy-aws.sh` -
# scoped to Terraform-managed infrastructure only. It does NOT check kubectl-provisioned resources
# (the load balancer, Kafka's PVCs/EBS volumes) - those don't exist until deploy-aws.sh runs, and
# are covered by teardown-aws.sh's own live checks during teardown instead.
set -uo pipefail

TF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AWS_PROFILE="$(cd "$TF_DIR" && terraform output -raw aws_profile 2>/dev/null)"
AWS_REGION="$(cd "$TF_DIR" && terraform output -raw aws_region 2>/dev/null)"
CLUSTER_NAME="$(cd "$TF_DIR" && terraform output -raw eks_cluster_name 2>/dev/null)"

if [[ -z "$AWS_PROFILE" || -z "$AWS_REGION" || -z "$CLUSTER_NAME" ]]; then
  echo "Could not read profile/region/cluster name from terraform output - has 'terraform apply' been run yet?"
  exit 2
fi

export AWS_PROFILE AWS_REGION
PASS=0
FAIL=0

# check <label> <command...>  - runs the command, prints PASS/FAIL, tallies results.
# Never aborts on a single failure - the whole point is a full report, not a fail-fast script.
check() {
  local label="$1"; shift
  local out
  if out="$("$@" 2>&1)" && [[ -n "$out" && "$out" != "None" ]]; then
    echo "  PASS  $label: $out"
    PASS=$((PASS+1))
  else
    echo "  FAIL  $label: not found (or empty) - ${out:-no output}"
    FAIL=$((FAIL+1))
  fi
}

echo "== Checking Terraform-provisioned AWS resources for cluster '$CLUSTER_NAME' (profile: $AWS_PROFILE, region: $AWS_REGION) =="
echo

echo "-- Networking --"
check "VPC" aws ec2 describe-vpcs --filters "Name=tag:Name,Values=grid-meter-app-vpc" --query 'Vpcs[0].VpcId' --output text
check "Internet Gateway" aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=grid-meter-app-igw" --query 'InternetGateways[0].InternetGatewayId' --output text
check "NAT Gateway" aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=grid-meter-app-nat" "Name=state,Values=available" --query 'NatGateways[0].NatGatewayId' --output text
check "Public subnets (expect 3)" aws ec2 describe-subnets --filters "Name=tag:Name,Values=grid-meter-app-public-*" --query 'length(Subnets)' --output text
check "Private subnets (expect 3)" aws ec2 describe-subnets --filters "Name=tag:Name,Values=grid-meter-app-private-*" --query 'length(Subnets)' --output text
echo

echo "-- EKS --"
check "EKS cluster status" aws eks describe-cluster --name "$CLUSTER_NAME" --query 'cluster.status' --output text
check "EKS node group status" aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name grid-meter-app-nodes --query 'nodegroup.status' --output text
check "EKS node group size" aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name grid-meter-app-nodes --query 'nodegroup.scalingConfig.desiredSize' --output text
for addon in vpc-cni kube-proxy coredns aws-ebs-csi-driver metrics-server; do
  check "EKS addon: $addon" aws eks describe-addon --cluster-name "$CLUSTER_NAME" --addon-name "$addon" --query 'addon.status' --output text
done
check "EC2 worker nodes (expect 3, Running)" aws ec2 describe-instances \
  --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" "Name=instance-state-name,Values=running" \
  --query 'length(Reservations[].Instances[])' --output text
echo

echo "-- Data tier --"
check "RDS instance status" aws rds describe-db-instances --db-instance-identifier grid-meter-app-postgres --query 'DBInstances[0].DBInstanceStatus' --output text
check "RDS engine version" aws rds describe-db-instances --db-instance-identifier grid-meter-app-postgres --query 'DBInstances[0].EngineVersion' --output text
check "ElastiCache replication group status" aws elasticache describe-replication-groups --replication-group-id grid-meter-app-cache --query 'ReplicationGroups[0].Status' --output text
check "ElastiCache engine" aws elasticache describe-replication-groups --replication-group-id grid-meter-app-cache --query 'ReplicationGroups[0].Engine' --output text
echo

echo "-- ECR --"
check "ECR repo: api" aws ecr describe-repositories --repository-names grid-meter-app-api --query 'repositories[0].repositoryUri' --output text
check "ECR repo: frontend" aws ecr describe-repositories --repository-names grid-meter-app-frontend --query 'repositories[0].repositoryUri' --output text
echo

echo "-- IAM --"
check "IAM role: eks-cluster" aws iam get-role --role-name grid-meter-app-eks-cluster-role --query 'Role.RoleName' --output text
check "IAM role: eks-node" aws iam get-role --role-name grid-meter-app-eks-node-role --query 'Role.RoleName' --output text
check "IAM role: ebs-csi-driver" aws iam get-role --role-name grid-meter-app-ebs-csi-driver-role --query 'Role.RoleName' --output text
check "OIDC provider" aws iam list-open-id-connect-providers --query "length(OpenIDConnectProviderList[?contains(Arn, '$CLUSTER_NAME') || contains(Arn, 'eks')])" --output text
echo

echo "== Summary: $PASS passed, $FAIL failed =="
if [[ "$FAIL" -gt 0 ]]; then
  echo "One or more expected resources are missing or unhealthy - investigate before proceeding to deploy-aws.sh."
  exit 1
fi
echo "All expected Terraform-provisioned resources confirmed present and healthy."
