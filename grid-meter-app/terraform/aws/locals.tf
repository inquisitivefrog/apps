locals {
  # Shared across vpc.tf (subnet auto-discovery tags) and eks.tf (the actual
  # cluster resource) - defined once here so both stay in sync by
  # construction rather than by two people remembering to match a string.
  cluster_name = "${var.project_name}-eks"
}
