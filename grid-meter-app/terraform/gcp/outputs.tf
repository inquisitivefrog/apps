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

output "artifact_registry_api_repository" {
  description = "Full pushable image path for the api image (region-docker.pkg.dev/project/repo/image). Found live (2026-09-21, first real deploy-gcp.sh run): unlike AWS ECR, where the repository itself IS the image, an Artifact Registry repository is a namespace that holds one or more separately-named images - a path missing the trailing image-name segment gets NAME_INVALID (\"Missing image name\") from the registry, surfacing as an opaque 400 Bad Request on the docker client's own HEAD-request probe rather than a clear error. This repo holds exactly one image, named 'api'. Used by k8s/deploy-gcp.sh."
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.api.repository_id}/api"
}

output "artifact_registry_frontend_repository" {
  description = "Full pushable image path for the frontend image - see artifact_registry_api_repository's description for why the trailing /frontend image-name segment is required. Used by k8s/deploy-gcp.sh."
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.frontend.repository_id}/frontend"
}

output "memorystore_host" {
  description = "Memorystore for Valkey PSC connection IP - extracted from the nested `endpoints[0].connections[0].psc_auto_connection[0].ip_address` structure (confirmed via `terraform providers schema`, not assumed - `discovery_endpoints` and the flat `psc_auto_connections` attribute are both deprecated) so k8s/deploy-gcp.sh doesn't need to parse that nesting itself. Only known after apply."
  value       = google_memorystore_instance.main.endpoints[0].connections[0].psc_auto_connection[0].ip_address
}

output "memorystore_port" {
  description = "Memorystore for Valkey PSC connection port."
  value       = google_memorystore_instance.main.endpoints[0].connections[0].psc_auto_connection[0].port
}

output "app_service_account_email" {
  description = "Email of the app's Workload-Identity-bound service account - fed to config.gcp.GcpRedisConfig as the accountName IamCredentialsClient.generateAccessToken() self-impersonates to mint the Memorystore IAM-auth token."
  value       = google_service_account.app.email
}

# Found via a real live TLS handshake failure (2026-09-24, first real Redis write attempt against
# a genuinely IAM-auth-wired pod): "PKIX path building failed... unable to find valid
# certification path" - raw TCP reachability to Memorystore was confirmed fine (a real `nc -zv`
# from inside the cluster succeeded), so this was never a network problem, only a TLS trust one.
# Memorystore's server certificate is signed by a private, per-instance Google-managed CA
# (server_ca_mode = GOOGLE_MANAGED_PER_INSTANCE_CA) the JDK's default trust store has no reason to
# know about - matching exactly why Google's own official Java/Lettuce IAM-auth reference sample
# explicitly builds a custom SslOptions trust manager from this same certificate rather than
# relying on useSsl()'s default (JDK-trust-store-based) behavior. managed_server_ca is a nested
# list-of-lists (confirmed live via `terraform state show`: 1 entry -> 1 ca_certs entry -> 2
# certificates, likely a root+intermediate pair or a rotation-overlap pair) - joined into one PEM
# bundle here so config.gcp.GcpRedisConfig's trust manager gets every valid anchor, not just one.
output "memorystore_server_ca_certificates" {
  description = "PEM bundle of Memorystore's per-instance managed CA certificate(s) - mounted into the api pod and used as config.gcp.GcpRedisConfig's Lettuce SSL trust manager, since the JDK's default trust store doesn't recognize Google's private per-instance CA."
  value       = join("\n", google_memorystore_instance.main.managed_server_ca[0].ca_certs[0].certificates)
  sensitive   = false
}
