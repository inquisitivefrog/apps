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
    tls = {
      source = "hashicorp/tls"
      # Used only to compute the EKS cluster's OIDC issuer certificate
      # thumbprint dynamically (ebs-csi.tf) rather than hardcoding a value -
      # AWS has rotated the underlying CA before, which broke hardcoded
      # thumbprints project-wide for anyone who'd pinned one.
      version = "~> 4.4"
    }
  }
}
