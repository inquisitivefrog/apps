terraform {
  # Same floor as terraform/aws/bootstrap/ - this dev machine runs 1.13.2,
  # confirmed live via `terraform version`, well above the >= 1.11.0 this
  # project has standardized on.
  required_version = ">= 1.11.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      # Current stable on the Terraform Registry as of 2026-09-21 - verified
      # directly against registry.terraform.io, not assumed. Needs to be
      # >= 6.20 for the main config's google_memorystore_instance resource
      # (see ../memorystore.tf) - 8.3 clears that with room to spare.
      version = "~> 8.3"
    }
  }

  # Deliberately local state for this module only, same reasoning as
  # terraform/aws/bootstrap/: it creates the GCS bucket the rest of
  # terraform/gcp/ uses as a *remote* backend, so it can't depend on that
  # backend without a circular bootstrap problem.
}
