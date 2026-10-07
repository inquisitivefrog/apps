output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "aws_region" {
  description = "Region this was deployed into. Sourced from here by k8s/deploy-aws.sh rather than re-reading via `terraform console`."
  value       = var.aws_region
}

output "aws_profile" {
  description = "AWS CLI profile used for this deployment. Sourced from here by k8s/deploy-aws.sh."
  value       = var.aws_profile
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = aws_eks_cluster.main.endpoint
}

output "kubeconfig_update_command" {
  description = "Run this to point kubectl (and therefore k8s/deploy.sh) at the real cluster instead of kind."
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region} --profile ${var.aws_profile}"
}

output "rds_endpoint" {
  description = "RDS Postgres endpoint (host:port)."
  value       = aws_db_instance.main.endpoint
}

output "rds_master_username" {
  description = "RDS master username. Not secret (it's a var default, not the generated password) - sourced from here rather than duplicated as a hardcoded literal in k8s/deploy-aws.sh."
  value       = var.rds_master_username
}

output "rds_master_user_secret_arn" {
  description = "AWS Secrets Manager ARN holding the generated master password. Retrieve with: aws secretsmanager get-secret-value --secret-id <this arn> --profile grid-meter --query SecretString --output text"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "elasticache_endpoint" {
  description = "Valkey primary endpoint (host)."
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "elasticache_port" {
  description = "Valkey port."
  value       = 6379
}

# Added 2026-09-23 alongside the AWS credential-provider app-code work
# (api/src/main/java/com/gridmeter/api/config/aws/), originally for IRSA/IAM-auth. Reverted to
# password auth 2026-10-06 for this account specifically - see elasticache-iam-auth.tf's header
# comment for why. `app_irsa_role_arn` is gone (that role no longer exists); replaced with
# `elasticache_app_password`. The app-side AwsRedisConfig class still expects the IAM-auth env
# vars as of this write - switching it to read a password instead is real, separate app-code
# work, not yet done (see k8s/deploy-aws.sh's own TODO once that lands).
output "elasticache_app_user_id" {
  description = "ElastiCache user ID the app connects as. Feeds whichever env var the app's Redis config expects for the username."
  value       = aws_elasticache_user.app.user_id
}

output "elasticache_app_password" {
  description = "Password for the ElastiCache app user (password auth, not IAM auth, on this account - see elasticache-iam-auth.tf). Never log this value; deploy-aws.sh reads it via `terraform output -raw elasticache_app_password` and injects it directly into the k8s secret."
  value       = random_password.elasticache_app.result
  sensitive   = true
}

output "elasticache_replication_group_id" {
  description = "Replication group ID (not the endpoint) - the identifier the SigV4-signed IAM auth token is built against. Feeds GRID_METER_AWS_ELASTICACHE_REPLICATION_GROUP_ID."
  value       = aws_elasticache_replication_group.main.replication_group_id
}

# ECR outputs removed 2026-10-06 - the repos themselves moved to bootstrap-freetier/ecr.tf (a
# persistent layer, not destroyed by this stack's nightly teardown - see that file's header
# comment). k8s/deploy-aws.sh now computes the ECR URL directly (account ID + region + the
# project's fixed naming convention) instead of reading it from this state.
