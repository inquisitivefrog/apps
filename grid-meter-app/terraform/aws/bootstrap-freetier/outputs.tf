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
