output "state_bucket_name" {
  description = "GCS bucket holding remote Terraform state for the rest of terraform/gcp/. Paste into ../backend.tf's bucket argument."
  value       = google_storage_bucket.tfstate.name
}

output "backend_config_snippet" {
  description = "Ready-to-paste backend \"gcs\" block for ../backend.tf."
  value       = <<-EOT
    terraform {
      backend "gcs" {
        bucket = "${google_storage_bucket.tfstate.name}"
        prefix = "grid-meter-app/terraform.tfstate"
      }
    }
  EOT
}
