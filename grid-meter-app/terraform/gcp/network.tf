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
  address       = var.psa_range_address # pinned explicitly - see variables.tf's psa_range_address for why (a real live collision with the GKE master CIDR, 2026-09-22)
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_service_access" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access.name]

  # Found via a real live `terraform destroy` failure (2026-09-21): this resource's own delete API
  # call (servicenetworking.services.connections.delete) refuses with "Producer services (e.g.
  # CloudSQL, Cloud Memstore, etc.) are still using this connection" even well after every real
  # Cloud SQL/Memorystore instance is confirmed destroyed (checked live via `gcloud sql instances
  # list`/`gcloud memorystore instances list` - genuinely zero remain) and even after the
  # underlying VPC-side peering object is deleted directly (`gcloud compute networks peerings
  # delete` - a different, Console-equivalent code path, confirmed via
  # `gcloud compute networks peerings list` afterward showing zero). This is a known, longstanding
  # upstream bug (hashicorp/terraform-provider-google#19908, #16275, #3979 - multiple, still-open,
  # spanning provider major versions): Google's Service Networking API tracks producer-service
  # usage in its own internal bookkeeping, separate from the VPC peering object, and that
  # bookkeeping's release can reportedly take days after the last producer is deleted - not a
  # propagation delay a short wait or a different Terraform ordering fixes. deletion_policy =
  # "ABANDON" is the documented community workaround: it drops this resource from Terraform state
  # without calling its (currently un-satisfiable) delete API. Confirmed low-consequence to abandon
  # here specifically - the connection object itself carries no ongoing GCP cost, and the VPC-side
  # peering it represented is already independently confirmed deleted.
  deletion_policy = "ABANDON"
}

# --- Service Connection Policy: authorizes Memorystore's PSC auto-connections ---
# Found via a real, live apply failure (2026-09-21), not anticipated in advance: Memorystore for
# Valkey's `desired_auto_created_endpoints` (memorystore.tf) needs an explicit
# ServiceConnectionPolicy to exist for this region/network/service-class combination BEFORE the
# instance can create its PSC endpoint - "No service connection policy is associated with
# project... network... region" (error code 9), not a resource Terraform creates implicitly as
# part of google_memorystore_instance itself. service_class = "gcp-memorystore" is Google's fixed,
# documented value for this exact purpose (confirmed via web search against GCP's own Memorystore
# networking docs) - reuses the existing GKE subnet for PSC endpoint IP allocation rather than
# provisioning a second, dedicated subnet purely for this.
resource "google_network_connectivity_service_connection_policy" "memorystore" {
  name          = "${var.project_name}-memorystore-scp"
  location      = var.gcp_region
  network       = google_compute_network.main.id
  service_class = "gcp-memorystore"

  psc_config {
    subnetworks = [google_compute_subnetwork.main.id]
  }
}

# Note: GKE itself needs no explicit firewall rules declared here - GKE
# auto-creates the required ingress rules (control-plane-to-node,
# node-to-pod, etc.) for both auto- and custom-mode VPCs, relying on the
# VPC's implied-allow-egress default rule for the return path (confirmed
# against GCP's own GKE firewall-rules docs, not assumed). That implied
# default is untouched here - this config adds no egress-deny rules - so no
# additional egress rule is needed either.
