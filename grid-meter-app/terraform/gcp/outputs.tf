output "vpc_id" {
  description = "VPC ID."
  value       = google_compute_network.main.id
}

output "gcp_project_id" {
  description = "GCP project this was deployed into. Sourced from here by a future k8s/deploy-gcp.sh, mirroring how deploy-aws.sh reads terraform output rather than hardcoding values."
  value       = var.gcp_project_id
}

output "gcp_region" {
  description = "Region this was deployed into."
  value       = var.gcp_region
}

output "gcp_zone" {
  description = "Zone the GKE cluster's control plane lives in."
  value       = var.gcp_zone
}

output "gke_cluster_name" {
  description = "GKE cluster name."
  value       = google_container_cluster.main.name
}

output "gke_cluster_endpoint" {
  description = "GKE API server endpoint."
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "kubeconfig_update_command" {
  description = "Run this to point kubectl (and therefore a future k8s/deploy-gcp.sh) at the real cluster instead of kind."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --zone ${var.gcp_zone} --project ${var.gcp_project_id}"
}

output "cloudsql_connection_name" {
  description = "Cloud SQL instance connection name (project:region:instance) - the identifier the Cloud SQL Auth Proxy/connector needs, distinct from a bare host:port."
  value       = google_sql_database_instance.main.connection_name
}

output "cloudsql_private_ip" {
  description = "Cloud SQL private IP address."
  value       = google_sql_database_instance.main.private_ip_address
}

output "cloudsql_user" {
  description = "Cloud SQL application username. Not secret (it's a var default, not the generated password) - sourced from here rather than duplicated as a hardcoded literal in a future deploy script."
  value       = var.cloudsql_user
}

output "cloudsql_password_secret_id" {
  description = "Secret Manager secret ID holding the generated database password. Retrieve with: gcloud secrets versions access latest --secret=<this value> --project <gcp_project_id>"
  value       = google_secret_manager_secret.cloudsql_password.secret_id
}

output "memorystore_endpoint" {
  description = "Memorystore for Valkey connection endpoint(s) - only known after apply, since it's assigned by the auto-created PSC connection. Uses `endpoints`, not the deprecated `discovery_endpoints` attribute (confirmed via `terraform providers schema`, not assumed)."
  value       = google_memorystore_instance.main.endpoints
}
