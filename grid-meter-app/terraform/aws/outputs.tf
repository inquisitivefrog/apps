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

output "ecr_api_repository_url" {
  description = "ECR repository URL for the api image. Used by k8s/deploy-aws.sh."
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_frontend_repository_url" {
  description = "ECR repository URL for the frontend image. Used by k8s/deploy-aws.sh."
  value       = aws_ecr_repository.frontend.repository_url
}
