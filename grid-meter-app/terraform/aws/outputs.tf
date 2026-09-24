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
# (api/src/main/java/com/gridmeter/api/config/aws/) - k8s/deploy-aws.sh needs all three to wire
# up the app's ServiceAccount (IRSA role annotation) and the two GRID_METER_AWS_ELASTICACHE_*
# env vars AwsRedisConfig reads. None of these existed as outputs before now because nothing
# consumed them yet - elasticache-iam-auth.tf's own header comment already flagged this Terraform
# as "inert until the app-code follow-up lands".
output "app_irsa_role_arn" {
  description = "IAM role ARN the app's K8s ServiceAccount (grid-meter-app, namespace default) assumes via IRSA for ElastiCache IAM auth. Annotate the ServiceAccount with eks.amazonaws.com/role-arn=<this value>."
  value       = aws_iam_role.app_irsa.arn
}

output "elasticache_app_user_id" {
  description = "IAM-auth-enabled ElastiCache user ID the app connects as. Feeds GRID_METER_AWS_ELASTICACHE_USER_ID."
  value       = aws_elasticache_user.app.user_id
}

output "elasticache_replication_group_id" {
  description = "Replication group ID (not the endpoint) - the identifier the SigV4-signed IAM auth token is built against. Feeds GRID_METER_AWS_ELASTICACHE_REPLICATION_GROUP_ID."
  value       = aws_elasticache_replication_group.main.replication_group_id
}

output "ecr_api_repository_url" {
  description = "ECR repository URL for the api image. Used by k8s/deploy-aws.sh."
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_frontend_repository_url" {
  description = "ECR repository URL for the frontend image. Used by k8s/deploy-aws.sh."
  value       = aws_ecr_repository.frontend.repository_url
}
