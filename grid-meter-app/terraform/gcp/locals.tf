locals {
  # Shared across network.tf (secondary range names) and gke.tf (the
  # cluster's ip_allocation_policy references) - defined once so both stay
  # in sync by construction, same reasoning as AWS's locals.tf cluster_name.
  cluster_name        = "${var.project_name}-gke"
  pods_range_name     = "${var.project_name}-pods"
  services_range_name = "${var.project_name}-services"
}
