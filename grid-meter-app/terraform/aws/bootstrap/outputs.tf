output "state_bucket_name" {
  description = "S3 bucket holding remote Terraform state for the rest of terraform/aws/. Paste into ../backend.tf's bucket argument."
  value       = aws_s3_bucket.tfstate.id
}

output "state_bucket_region" {
  description = "Region the state bucket lives in. Paste into ../backend.tf's region argument."
  value       = var.aws_region
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
