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
  description = "Zones the GKE node pool spreads across, independent of the cluster's own (single) control-plane zone. 3 zones matches this project's existing Kafka topologySpreadConstraints (k8s/kafka.yaml) and AWS's 3-AZ node spread (vpc.tf's az_count) - one node per zone, giving Kafka's 3 brokers a real shot at one-broker-per-zone."
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
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
  description = "/28 range for the GKE control plane's private endpoint peering - required whenever enable_private_nodes is true, regardless of whether the public endpoint is also enabled."
  type        = string
  default     = "172.16.0.0/28"
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
  description = "Nodes per zone in gke_node_locations (3 zones x 1 = 3 total nodes). Started at 3 directly rather than repeating AWS's 2-then-3 live-debugging cycle (terraform/aws/variables.tf's eks_node_count comment) - that finding (2 nodes structurally can't give Kafka's 3 brokers one-node-per-zone regardless of sizing, and a corrected realistic api memory limit alone pushed one node to 94% memory requests) is a directly transferable lesson, not something worth re-discovering on a second cloud."
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
