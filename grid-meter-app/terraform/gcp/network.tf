# Custom-mode VPC (not GCP's "auto" mode, which pre-creates one subnet per
# region with no control over ranges) - same reasoning as AWS's dedicated
# aws_vpc: explicit, purpose-sized ranges rather than an implicit default.
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
}

# One subnet, one region - GKE VPC-native clusters spread nodes across
# zones via the node pool's node_locations (see gke.tf), not via one
# subnet per zone the way AWS's per-AZ subnets work. Secondary ranges for
# pod and Service IPs are what makes this "VPC-native" (alias IP) rather
# than GKE's older, deprecated routes-based networking.
resource "google_compute_subnetwork" "main" {
  name          = "${var.project_name}-subnet"
  network       = google_compute_network.main.id
  region        = var.gcp_region
  ip_cidr_range = var.subnet_cidr

  secondary_ip_range {
    range_name    = local.pods_range_name
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = local.services_range_name
    ip_cidr_range = var.services_cidr
  }

  # Lets nodes without an external IP (this cluster's private-nodes config,
  # see gke.tf) still reach Google APIs (Container Registry/Artifact
  # Registry, Cloud Logging/Monitoring, Secret Manager) directly, without
  # needing a NAT hop for Google-internal traffic specifically.
  private_ip_google_access = true
}

# --- Cloud NAT: internet egress for private nodes ---
# GKE's node pool here has no external IPs (private_cluster_config.
# enable_private_nodes = true, gke.tf) - same private-worker-subnet pattern
# as AWS's private subnets + single NAT gateway. Cloud Router + Cloud NAT is
# GCP's equivalent mechanism; also a single instance, same cost-conscious
# non-HA-edge-component tradeoff AWS's single NAT gateway made.
resource "google_compute_router" "main" {
  name    = "${var.project_name}-router"
  network = google_compute_network.main.id
  region  = var.gcp_region
}

resource "google_compute_router_nat" "main" {
  name                               = "${var.project_name}-nat"
  router                             = google_compute_router.main.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# --- Private Service Access: VPC peering for Cloud SQL's private IP ---
# Cloud SQL's private-IP connectivity (cloudsql.tf) uses the older/classic
# "Private Service Access" VPC peering mechanism, distinct from Memorystore
# for Valkey's newer Private Service Connect model (memorystore.tf) - two
# different private-connectivity mechanisms for two different GCP product
# generations, not an inconsistency to resolve.
resource "google_compute_global_address" "private_service_access" {
  name          = "${var.project_name}-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_service_access" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access.name]
}

# Note: GKE itself needs no explicit firewall rules declared here - GKE
# auto-creates the required ingress rules (control-plane-to-node,
# node-to-pod, etc.) for both auto- and custom-mode VPCs, relying on the
# VPC's implied-allow-egress default rule for the return path (confirmed
# against GCP's own GKE firewall-rules docs, not assumed). That implied
# default is untouched here - this config adds no egress-deny rules - so no
# additional egress rule is needed either.
