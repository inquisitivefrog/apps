output "state_bucket_name" {
  description = "S3 bucket holding remote Terraform state for the rest of terraform/aws/. Paste into ../backend.tf's bucket argument."
  value       = aws_s3_bucket.tfstate.id
}

output "state_bucket_region" {
  description = "Region the state bucket lives in. Paste into ../backend.tf's region argument."
  value       = var.aws_region
}

output "ecr_api_repository_url" {
  description = "ECR repository URL for the api image. Used by the AWS CI workflow (build+push) and the AWS CD startup workflow (deploy). Persistent across the main stack's nightly destroy/apply - see ecr.tf."
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_frontend_repository_url" {
  description = "ECR repository URL for the frontend image. Same persistence reasoning as ecr_api_repository_url."
  value       = aws_ecr_repository.frontend.repository_url
}

output "app_eip_allocation_id" {
  description = "Allocation ID of the persistent Elastic IP the demo's NLB is pinned to (see eip.tf). Used by k8s/deploy-aws.sh for the aws-load-balancer-eip-allocations Service annotation."
  value       = aws_eip.app.id
}

output "app_eip_public_ip" {
  description = "The stable public IP address of the demo app - this is the actual resume-facing URL (http://<this>/meters), unlike the NLB's own hostname which is NOT stable across nightly rebuilds."
  value       = aws_eip.app.public_ip
}

output "backend_config_snippet" {
  description = "Ready-to-paste backend \"s3\" block for ../backend.tf."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket       = "${aws_s3_bucket.tfstate.id}"
        key          = "grid-meter-app/terraform.tfstate"
        region       = "${var.aws_region}"
        use_lockfile = true
      }
    }
  EOT
}
