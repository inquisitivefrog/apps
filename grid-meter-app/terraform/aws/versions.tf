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
    random = {
      source = "hashicorp/random"
      # Generates the disabled default ElastiCache user's throwaway password
      # (elasticache-iam-auth.tf) - Valkey, unlike Redis OSS, doesn't support
      # a true no-password-required auth mode at all (confirmed live,
      # 2026-09-23), so a real, never-used password is required even for a
      # disabled user.
      version = "~> 3.6"
    }
  }
}
