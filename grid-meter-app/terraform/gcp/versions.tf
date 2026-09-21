terraform {
  # Same floor as terraform/gcp/bootstrap/ - required for consistency across
  # this project's Terraform trees.
  required_version = ">= 1.11.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      # Current stable on the Terraform Registry as of 2026-09-21, verified
      # directly - and comfortably clears the >= 6.20 floor
      # google_memorystore_instance (memorystore.tf) needs.
      version = "~> 8.3"
    }
    random = {
      source = "hashicorp/random"
      # Generates the Cloud SQL master password (cloudsql.tf) - GCP has no
      # RDS-style manage_master_user_password convenience, so this plus
      # Secret Manager is the standard idiomatic substitute.
      version = "~> 3.6"
    }
  }

  # No backend block yet, deliberately - this pass is plan-only (see
  # README.md). Once terraform/gcp/bootstrap/ is actually applied (a
  # separate, later user decision, same sequencing as terraform/aws/), add
  # a backend.tf here with that module's `backend_config_snippet` output,
  # matching how terraform/aws/backend.tf was created. Until then this
  # config runs on local state.
}
