# --- Shared / provider ---

variable "gcp_project_id" {
  description = "GCP project to deploy into."
  type        = string
  default     = "project-4c5a8821-da4c-4c68-97f"
}

variable "gcp_region" {
  description = "GCP region to deploy into. us-central1 confirmed live (2026-09-21, via web search against current GCP pricing pages) as GCP's baseline/cheapest pricing tier - the same reasoning behind AWS's us-west-2 choice."
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "Primary zone within gcp_region - used for the GKE cluster's control plane (a zonal, not regional, cluster - see gke.tf) and as the provider's default zone."
  type        = string
  default     = "us-central1-a"
}

variable "gke_node_locations" {
  description = "Zones the GKE node pool spreads across, independent of the cluster's own (single) control-plane zone. Originally 3 zones, matching this project's existing Kafka topologySpreadConstraints (k8s/kafka.yaml) and AWS's 3-AZ node spread (vpc.tf's az_count) - one node per zone, giving Kafka's 3 brokers a real shot at one-broker-per-zone. Reduced to us-central1-a only (2026-09-24) after a real live apply hit GCE_STOCKOUT simultaneously in both us-central1-b and us-central1-c (confirmed via `gcloud container node-pools describe`'s conditions - both zones' single-instance IGM never reached RUNNING after 35+ minutes) - a more widespread stockout than the earlier single-zone (us-central1-b only) instance already documented in status/claude_code_2026-09-21.md, which had resolved on a plain retry. Dropping to one zone trades away Kafka's one-broker-per-zone placement (an accepted, already-precedented tradeoff - see terraform/azure/README.md's AKS node-count-vs-quota tradeoff for the same shape of decision) for actually being able to provision nodes at all when a stockout spans multiple zones at once."
  type        = list(string)
  default     = ["us-central1-a"]
}

variable "project_name" {
  description = "Short project identifier, used to name/label resources."
  type        = string
  default     = "grid-meter-app"
}

# --- Networking ---

variable "subnet_cidr" {
  description = "Primary IP range for the GKE subnet (node IPs)."
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary IP range for pod IPs (VPC-native/alias IP GKE requirement)."
  type        = string
  default     = "10.11.0.0/16"
}

variable "services_cidr" {
  description = "Secondary IP range for Kubernetes Service ClusterIPs (VPC-native/alias IP GKE requirement)."
  type        = string
  default     = "10.12.0.0/20"
}

variable "master_ipv4_cidr_block" {
  # Found via a second real live apply failure (2026-09-22), right after the psa_range_address fix
  # below resolved the *first* 172.16.0.0/28 collision: even with the PSA range moved off 172.16.x.x
  # entirely (to 10.1.0.0/16), cluster creation failed again with a DIFFERENT error against this same
  # /28 - "New subnetwork IP range (172.16.0.0/28) overlaps with an active peer network
  # (servicenetworking-googleapis-com)". Researched rather than guessed: 172.16.0.0/23 is GKE's own
  # long-standing historical default master CIDR (confirmed via GCP's own troubleshooting docs), and
  # Google's Private Service Access peering (the servicenetworking-googleapis-com connection this
  # project's own PSA range creates) commonly imports/exports routes touching that same 172.16.0.0/12
  # block on the producer side - a known category of conflict independent of whatever range this
  # project explicitly reserves for its own PSA connection. Moved off 172.16.0.0/12 entirely rather
  # than continuing to hunt for a "safe" subrange within it - onto the same low 10.x.x.x scheme
  # psa_range_address now uses (user preference, 2026-09-22), disjoint from subnet_cidr (10.10.0.0/20),
  # pods_cidr (10.11.0.0/16), services_cidr (10.12.0.0/20), and psa_range_address (10.1.0.0/16) above.
  description = "/28 range for the GKE control plane's private endpoint peering - required whenever enable_private_nodes is true, regardless of whether the public endpoint is also enabled. Deliberately outside 172.16.0.0/12 (GKE's own common default, which collides with Private Service Access peering routes) - kept in the same low 10.x.x.x scheme as psa_range_address."
  type        = string
  default     = "10.0.0.0/28"
}

variable "psa_range_address" {
  # Found via a real live apply failure (2026-09-22): google_compute_global_address.private_service_access
  # (network.tf) originally declared only prefix_length = 16 with no explicit `address`, letting GCP
  # auto-pick a /16 block from its own internal allocation pool on each apply - non-deterministic across
  # applies (10.81.0.0/16 on an earlier apply, 172.16.0.0/16 on this one). The second landed squarely on
  # top of master_ipv4_cidr_block above (172.16.0.0/28), and GKE cluster creation failed outright:
  # "Invalid IPCidrRange: 172.16.0.0/28 conflicts with reserved IP range '172.16.0.0/16'" - the exact
  # "undeclared default silently colliding with something assumed fixed" shape this project has hit
  # many times before (CLAUDE.md), just for an IP range instead of a timeout/durability setting.
  #
  # Pinned to 10.1.0.0/16 (user preference, 2026-09-22): kept within 10.x.x.x rather than the 172.16.x.x
  # space GCP happened to auto-pick, and deliberately small/low in the 10.x range so 10.2.0.0/16 stays
  # free and reserved for a second region's VPC-peering range if this project ever adds cross-region
  # replication - not colliding with this region's own subnet_cidr (10.10.0.0/20), pods_cidr
  # (10.11.0.0/16), services_cidr (10.12.0.0/20), or master_ipv4_cidr_block (172.16.0.0/28) above.
  description = "Explicit starting address for the Private Service Access VPC-peering range (paired with a /16 prefix_length in network.tf) - must stay disjoint from subnet_cidr/pods_cidr/services_cidr/master_ipv4_cidr_block above. Kept low in 10.x.x.x (10.1.0.0) so 10.2.x.x stays reserved for a future second-region VPC if cross-region replication is ever added."
  type        = string
  default     = "10.1.0.0"
}

# --- GKE ---

variable "gke_release_channel" {
  description = "GKE release channel. Checked live (2026-09-21) via `gcloud container get-server-config --region us-central1`: REGULAR's current default version is 1.35.8-gke.1036000 - GKE's own recommended default balance (monthly-ish auto-upgrades), the same 'declare the mechanism explicitly, don't leave the provider's own implicit default unstated' reasoning AWS's eks.tf access_config used. GKE deliberately doesn't support pinning a bare Kubernetes version outside a channel as its primary interface the way EKS does - channels are the idiomatic mechanism here."
  type        = string
  default     = "REGULAR"
}

variable "gke_node_machine_type" {
  description = "GCE machine type for the GKE node pool. e2-medium (2 vCPU / 4GiB) is GCP's closest sizing match to AWS's t3.medium, chosen for the same 'smallest viable to run the existing manifests' reasoning."
  type        = string
  default     = "e2-medium"
}

variable "gke_node_count" {
  description = "Nodes PER ZONE in gke_node_locations, not a total - GKE's own documented node_count semantics for a multi-zone node pool (confirmed live 2026-09-21, after a real apply created 9 actual GCE instances, not the intended 3: total nodes = node_count x len(node_locations)). Was 1 (x 3 zones = 3 total nodes, matching AWS's eks_node_count=3 exactly, terraform/aws/variables.tf) - that AWS value was itself already the post-live-debugging-corrected number (2 nodes were found genuinely overcommitted, 2026-09-18), so 1x3=3 was the direct transfer of that lesson, not a fresh guess. Raised to 3 (2026-09-24) alongside gke_node_locations dropping to a single zone (us-central1-a only, after a real GCE_STOCKOUT spanning both other zones) - 3 x 1 zone = 3 total nodes, preserving the original total-node intent rather than silently shrinking capacity to 1 along with the zone reduction."
  type        = number
  default     = 3
}

variable "gke_node_disk_size_gb" {
  description = "Boot disk size per node, GB. Declared explicitly rather than left at the provider/GKE default (100GB pd-balanced) - a meaningfully pricier undeclared default than this project's own cost-conscious sizing elsewhere; 30GB is real headroom for this app's small container images plus kubelet/containerd overhead."
  type        = number
  default     = 30
}

variable "gke_node_disk_type" {
  description = "Boot disk type per node. pd-standard (HDD-backed) is GCP's cheapest disk type - fine for boot disks that aren't on this app's own I/O-sensitive path (that's Kafka/Postgres/Redis, all on managed services or their own PVCs, not node boot disks)."
  type        = string
  default     = "pd-standard"
}

# --- Cloud SQL (PostgreSQL, replaces self-hosted Patroni for the cloud target) ---

variable "cloudsql_tier" {
  description = "Cloud SQL machine tier. Checked live (2026-09-21) via `gcloud sql tiers list`: db-f1-micro (614.4 MiB RAM) is the smallest available tier, GCP's closest match to AWS's db.t4g.micro for the same cost-conscious sizing reasoning."
  type        = string
  default     = "db-f1-micro"
}

variable "cloudsql_postgres_version" {
  description = "Cloud SQL PostgreSQL major version. Checked live (2026-09-21) via `gcloud sql instances create --help`'s --database-version enum: POSTGRES_18 is directly supported, matching this project's own pinned version in docs/tech-stack-versions.md exactly - same clean result AWS's RDS version check found."
  type        = string
  default     = "POSTGRES_18"
}

variable "cloudsql_disk_size_gb" {
  description = "Allocated storage in GB. 20 matches AWS's rds_allocated_storage - the practical minimum for this instance size."
  type        = number
  default     = 20
}

variable "cloudsql_db_name" {
  description = "Initial database name, matching the app's existing spring.datasource.url convention (docker-compose.yml: 'gridmeter')."
  type        = string
  default     = "gridmeter"
}

variable "cloudsql_user" {
  description = "Application database username. The password is NOT a variable here - it's generated and stored in Secret Manager via a random_password resource + google_secret_manager_secret, so no plaintext credential ever exists in Terraform state or config (see cloudsql.tf) - the GCP-idiomatic equivalent of AWS's manage_master_user_password."
  type        = string
  default     = "gridmeter"
}

# --- Memorystore for Valkey (replaces self-hosted Redis Sentinel for the cloud target) ---

variable "memorystore_node_type" {
  description = "Memorystore for Valkey node type. Checked live (2026-09-21) via Terraform provider docs: SHARED_CORE_NANO is explicitly recommended for dev/test only (no SLA) - the same cost/HA tradeoff AWS's cache.t4g.micro + single-node ElastiCache replication group already accepted."
  type        = string
  default     = "SHARED_CORE_NANO"
}

variable "memorystore_engine_version" {
  description = "Valkey engine version. Checked live (2026-09-21) via Google's own supported-versions doc: Memorystore for Valkey supports 7.2/8.0/9.0/9.1, with 9.0 as the current GA default and 9.1 still in Preview. Chosen: 9.0 (newest GA, not the Preview version) - same 'newest available, not experimental' reasoning as AWS's Valkey 9.1 pick, adjusted for what's actually GA on this cloud. Mirrors AWS's exact finding: GCP's legacy 'Memorystore for Redis' product (google_redis_instance) tops out at Redis 7.2 with no Redis 8.x/9.x offered at all - Memorystore for Valkey (google_memorystore_instance) is the current path for anything past that, same shape of gap AWS's ElastiCache 'redis' engine had."
  type        = string
  default     = "VALKEY_9_0"
}
