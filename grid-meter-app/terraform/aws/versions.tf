terraform {
  # Tightened from ">= 1.11.0" to an exact pin (2026-10-08) after a real, live cross-version
  # behavioral difference broke a CI check: on 1.13.2 (this project's CI pin, via
  # hashicorp/setup-terraform@v3), `terraform output -raw <name>` on an output that doesn't
  # exist prints a multi-line "Warning: No outputs found" to STDOUT (not stderr) - a shell
  # `2>/dev/null` never catches it, so the warning text itself gets captured as a "truthy"
  # value by anything doing `VAR="$(terraform output -raw ... 2>/dev/null || true)"`. 1.16.4
  # (this dev machine's actual installed version at the time, confirmed live via `terraform
  # version` - silently drifted from the 1.13.2 this file's own prior comment claimed, via an
  # unpinned `brew upgrade` at some point) does NOT reproduce the leak, which is exactly why
  # this wasn't caught testing locally first. An exact pin makes that drift a loud, immediate
  # `terraform init` failure instead of a silent behavioral gap - if this version is ever
  # deliberately bumped, re-verify `terraform output -raw` on empty state against the new
  # version first and log what changed here, the same way this entry does.
  required_version = "= 1.13.2"

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
