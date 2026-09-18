terraform {
  # Same floor as terraform/aws/bootstrap/ - required for use_lockfile
  # support in backend.tf. Verified installed: 1.13.2.
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Current stable on the Terraform Registry as of 2026-09-17.
      version = "~> 6.65"
    }
  }
}
