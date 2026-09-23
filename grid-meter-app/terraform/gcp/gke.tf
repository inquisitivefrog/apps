# --- Node service account (least-privilege, not the default Compute Engine SA) ---
# Confirmed live (2026-09-21, web search against GCP's own "Configure GKE
# node service accounts" doc): Google's current recommended pattern is a
# dedicated minimally-privileged SA plus IAM roles bound directly to it
# (roles/container.nodeServiceAccount bundles the logging/monitoring
# permissions nodes need), not broad OAuth scopes as the enforcement layer -
# same "least-privilege dedicated role, not a shared default" reasoning as
# AWS's aws_iam_role.eks_node.
resource "google_service_account" "gke_node" {
  account_id   = "${var.project_name}-gke-node"
  display_name = "${var.project_name} GKE node service account"
}

resource "google_project_iam_member" "gke_node_sa" {
  project = var.gcp_project_id
  role    = "roles/container.nodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

# Found via a real live deploy-gcp.sh failure (2026-09-21): roles/container.nodeServiceAccount
# alone does NOT include Artifact Registry pull permission - every api/frontend pod failed with
# ErrImagePull, "403 Forbidden" fetching the pull OAuth token, confirmed via `kubectl describe
# pod`'s events. This is the direct GCP equivalent of AWS's
# aws_iam_role_policy_attachment.eks_node_registry_policy
# (AmazonEC2ContainerRegistryReadOnly) - omitted here originally because AWS's managed node role
# needed 3 explicit policy attachments (worker/CNI/registry) and this got missed by analogy to
# the GCP side needing only 1 role for the same worker/logging/monitoring bundle; registry pull
# is a genuinely separate permission on GCP that has no equivalent bundling.
resource "google_project_iam_member" "gke_node_artifact_registry" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

# --- Cluster ---
# Zonal (single-zone control plane), not regional - covered by GKE's own
# free-tier credit ($74.40/month per billing account, confirmed live via
# web search against GCP's GKE pricing page - equivalent to one free
# zonal-Standard-or-Autopilot cluster's management fee) in a way a regional
# cluster's 3x control-plane replicas may not be. Node-level zone spread
# (still 3 zones, matching Kafka's topologySpreadConstraints) comes from the
# node pool's node_locations below, independent of this.
resource "google_container_cluster" "main" {
  name     = local.cluster_name
  location = var.gcp_zone

  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.main.id

  # remove_default_node_pool + initial_node_count=1 is the standard
  # Terraform-idiomatic GKE pattern: the API always creates a default node
  # pool, which is immediately deleted here and replaced by the
  # purpose-configured google_container_node_pool.main below - avoids
  # having to manage the auto-created pool's config by hand.
  remove_default_node_pool = true
  initial_node_count       = 1

  # VPC-native (alias IP) networking - empty block means "use the
  # secondary ranges already defined on the subnet by name", the modern
  # default GKE steers new clusters toward; the older routes-based
  # networking mode is deprecated.
  ip_allocation_policy {
    cluster_secondary_range_name  = local.pods_range_name
    services_secondary_range_name = local.services_range_name
  }

  release_channel {
    channel = var.gke_release_channel
  }

  # Declared explicitly rather than left at whatever the provider/GKE
  # version resolves to implicitly - this is the addon that makes
  # k8s/storageclass-gcp.yaml able to provision anything at all (the direct
  # GCP equivalent of AWS's aws_eks_addon "ebs_csi_driver"). Confirmed live
  # via web search (2026-09-21): GKE 1.18.10-gke.2100+/1.19.3-gke.2100+
  # enables this by default when the block is omitted entirely, well below
  # this cluster's REGULAR-channel version - but this project's own
  # standing rule is to declare load-bearing defaults, not lean on an
  # implicit one, regardless of how safe that implicit default currently
  # is (CLAUDE.md's "undeclared defaults" lesson, found 9 separate times
  # elsewhere in this project's HA work).
  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Private nodes (no external IP on any node - egress via the Cloud NAT in
  # network.tf), same private-worker-subnet pattern as AWS's private
  # subnets. Public endpoint left enabled (enable_private_endpoint=false)
  # so kubectl from this laptop reaches the control plane directly over the
  # internet - matching how the AWS EKS cluster was actually used (its
  # vpc_config left endpoint_public_access at its own default-true).
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Declared explicitly rather than left at the provider's own default
  # (true in recent versions) - this is a demo project's cluster and needs
  # to come down cleanly via `terraform destroy`, the same reasoning as
  # AWS's rds.tf skip_final_snapshot=true and access_config's explicit
  # authentication_mode.
  deletion_protection = false

  # Workload Identity Federation for GKE - not previously enabled (this cluster only had
  # node-level identity via google_service_account.gke_node above). Required so the app's own
  # pods can present a distinct GCP identity (google_service_account.app below) rather than
  # riding the node SA's broader permissions - added 2026-09-23 for Memorystore IAM auth, see
  # memorystore.tf.
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  depends_on = [google_compute_router_nat.main]
}

# --- App workload identity (distinct from the node-level SA above) ---
# Backported 2026-09-23 after Azure Managed Redis's forced move to Entra-ID-only auth prompted an
# explicit decision (user sign-off) to align AWS/GCP onto the same tighter posture rather than
# leave them on AUTH-string auth just because nothing forced it yet - same reasoning as AWS's new
# elasticache-iam-auth.tf. The app has never needed its own GCP identity before now (Cloud SQL
# uses a Secrets-Manager-equivalent-stored password, not IAM DB auth).
resource "google_service_account" "app" {
  account_id   = "${var.project_name}-app"
  display_name = "${var.project_name} application workload identity"
}

# Binds the K8s ServiceAccount "grid-meter-app" in the "default" namespace to this GSA - the K8s
# side (the ServiceAccount object itself, with the
# iam.gke.io/gcp-service-account annotation, plus k8s/api-gcp.yaml's serviceAccountName field) is
# real manifest/app-deploy work, tracked as a required follow-up alongside the Lettuce
# credential-provider app code (AWS/GCP/Azure all three now need one) - not attempted inline
# here. This binding is inert (no pod can impersonate this GSA yet) until that follow-up lands.
#
# Found via a real live apply failure (2026-09-23): "Identity Pool does not exist
# (<project>.svc.id.goog)" - the workload identity pool this binding targets is backed by
# google_container_cluster.main's own workload_identity_config and doesn't exist until that
# cluster actually finishes creating. No implicit Terraform dependency exists between this
# resource and the cluster (the member string is built from var.gcp_project_id, a plain
# variable, not a cluster attribute), so nothing forced the ordering - added explicitly.
resource "google_service_account_iam_member" "app_workload_identity" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[default/grid-meter-app]"
  depends_on         = [google_container_cluster.main]
}

# Confirmed live (2026-09-23, web search against Memorystore for Valkey's own IAM-auth docs):
# roles/memorystore.dbConnectionUser is the specific predefined role granting the
# memorystore.instances.connect permission IAM auth needs - not a generic Memorystore
# viewer/editor role.
resource "google_project_iam_member" "app_memorystore_connect" {
  project = var.gcp_project_id
  role    = "roles/memorystore.dbConnectionUser"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# --- Managed node pool ---
resource "google_container_node_pool" "main" {
  name    = "${var.project_name}-nodes"
  cluster = google_container_cluster.main.id

  # gke_node_count is PER ZONE (GKE's own node_count semantics for a
  # multi-zone pool) - 1 x 3 zones in node_locations below = 3 total nodes,
  # matching AWS's node count. See variables.tf's gke_node_count comment
  # for the real live bug this corrects (the original default of 3 here
  # actually produced 9 nodes).
  node_count     = var.gke_node_count
  node_locations = var.gke_node_locations

  node_config {
    machine_type    = var.gke_node_machine_type
    disk_size_gb    = var.gke_node_disk_size_gb
    disk_type       = var.gke_node_disk_type
    service_account = google_service_account.gke_node.email

    # Google's own documented default node scopes (logging write,
    # monitoring, read-only Cloud Storage for image pulls) - deliberately
    # NOT the broad cloud-platform scope, since real access control here is
    # enforced by the dedicated SA's IAM role above, and cloud-platform
    # would let any pod on the node ride that SA's access regardless of
    # what the SA's own IAM roles are scoped to (confirmed live via web
    # search against GCP's node-service-account security guidance).
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]
  }

  depends_on = [google_project_iam_member.gke_node_sa]
}

# --- Extra single-zone node pool: real node-overcommitment fix ---
# Found via a real live deploy-gcp.sh run (2026-09-21): with all 3 e2-medium nodes at 74-94%
# memory *requests* already (Kafka's 3x768Mi + api's 2x1Gi + frontend's 2x64Mi + Traefik's 128Mi,
# on top of GKE's own system-pod reservation per node), kafka-2 couldn't schedule at all
# ("0/3 nodes are available: 3 Insufficient memory"). Same shape of finding as AWS's node
# overcommitment (terraform/aws/variables.tf's eks_node_count comment) - presented as a real
# sizing/cost decision rather than resolved silently, per this project's own standing practice.
# User chose a 4th e2-medium node over a larger machine type (e2-standard-2) - GKE's node_count on
# the main pool is per-zone (see that variable's own comment on the live bug this already
# corrected once), so a single pool can't give one specific zone an extra node on its own; this
# second pool is scoped to one zone only (matching the cluster's own control-plane zone,
# gcp_zone) to add exactly 1 more node there, landing at 4 total rather than a uniform 6
# (node_count=2 across all 3 zones) that would have added CPU capacity nobody asked for.
resource "google_container_node_pool" "extra" {
  name    = "${var.project_name}-nodes-extra"
  cluster = google_container_cluster.main.id

  node_count     = 1
  node_locations = [var.gcp_zone]

  node_config {
    machine_type    = var.gke_node_machine_type
    disk_size_gb    = var.gke_node_disk_size_gb
    disk_type       = var.gke_node_disk_type
    service_account = google_service_account.gke_node.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]
  }

  depends_on = [google_project_iam_member.gke_node_sa]
}

# Note: unlike EKS (which needed an explicit aws_eks_addon "metrics_server"
# in terraform/aws/eks.tf), GKE Standard clusters ship Metrics Server
# pre-installed in kube-system by default - no equivalent resource needed
# here for `kubectl top nodes/pods` to work.

