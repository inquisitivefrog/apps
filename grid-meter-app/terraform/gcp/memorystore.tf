# Memorystore for Valkey (google_memorystore_instance) - not the legacy
# "Memorystore for Redis" (google_redis_instance), which tops out at Redis
# 7.2 with no 8.x/9.x offered at all. See variables.tf's
# memorystore_engine_version comment - the same shape of gap AWS's
# ElastiCache "redis" engine had, resolved the same way (a Valkey product).
#
# Networking model here is genuinely different from Cloud SQL's: Valkey
# uses Private Service Connect (a per-instance auto-created PSC endpoint
# into this VPC), not the classic VPC-peering "Private Service Access"
# cloudsql.tf uses - two different GCP private-connectivity generations,
# not an inconsistency.
resource "google_memorystore_instance" "main" {
  instance_id = "${var.project_name}-cache"
  location    = var.gcp_region
  shard_count = 1

  # CLUSTER_DISABLED = single shard, no HA failover - GCP's closest
  # equivalent to AWS's num_cache_clusters=1 single-node ElastiCache
  # replication group. Same accepted tradeoff: this app's own Redis/Valkey
  # usage already has a documented cache-miss fallback to Postgres
  # (docs/architecture.md), so a single cache node's lack of failover is
  # low-consequence here.
  mode = "CLUSTER_DISABLED"

  node_type      = var.memorystore_node_type
  engine_version = var.memorystore_engine_version

  # IAM auth - backported 2026-09-23 after Azure Managed Redis's forced move to Entra-ID-only
  # auth (see terraform/azure/rediscache.tf); AWS got the equivalent ElastiCache IAM-auth
  # treatment the same day (terraform/aws/elasticache-iam-auth.tf). Confirmed live this resource
  # type (google_memorystore_instance, the Valkey product actually used here - not
  # google_redis_cluster, a different resource this project doesn't use) supports IAM_AUTH
  # directly. TLS is not strictly auto-required by the API for IAM_AUTH, but GCP's own docs
  # state it's required in practice to avoid leaking the IAM token itself in transit - declared
  # explicitly rather than left an implicit "works but insecure" gap.
  authorization_mode      = "IAM_AUTH"
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  desired_auto_created_endpoints {
    network    = google_compute_network.main.id
    project_id = var.gcp_project_id
  }

  deletion_protection_enabled = false # Same reasoning as gke.tf/cloudsql.tf - needs to destroy cleanly for a demo.

  # Found via a real, live apply failure (2026-09-21): the PSC auto-connection
  # errors ("No service connection policy is associated...") if this doesn't
  # exist yet - see network.tf's google_network_connectivity_service_connection_policy.
  depends_on = [google_network_connectivity_service_connection_policy.memorystore]
}
