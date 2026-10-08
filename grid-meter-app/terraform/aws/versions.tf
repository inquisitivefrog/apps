terraform {
  # Tightened from ">= 1.11.0" (2026-10-08) after a real, live cross-version behavioral
  # difference broke a CI check: on 1.13.2 (this project's CI pin, via
  # hashicorp/setup-terraform@v3), `terraform output -raw <name>` on an output that doesn't
  # exist prints a multi-line "Warning: No outputs found" to STDOUT (not stderr) - a shell
  # `2>/dev/null` never catches it, so the warning text itself gets captured as a "truthy"
  # value by anything doing `VAR="$(terraform output -raw ... 2>/dev/null || true)"`. 1.16.4
  # (this dev machine's actual installed version at the time, confirmed live via `terraform
  # version` - silently drifted from the 1.13.2 this file's own prior comment claimed, via an
  # unpinned `brew upgrade` from an unrelated earlier Terraform project) does NOT reproduce the
  # leak, which is exactly why this wasn't caught testing locally first.
  #
  # `~> 1.13.0` (not an exact `= 1.13.2`): the bug was a MINOR-version behavioral change
  # (1.13 -> 1.16, three minor bumps), and HashiCorp's own versioning policy treats patch
  # releases as bug-fix-only with no behavior changes - so `~> 1.13.0` (>= 1.13.0, < 1.14.0)
  # blocks exactly the drift that caused this bug while still allowing safe patch bumps
  # (1.13.3, 1.13.4, ...) without a commit each time. Matches this file's own
  # `required_providers` convention below, which already uses `~>` throughout. If this
  # constraint is ever deliberately widened past 1.13.x, re-verify `terraform output -raw` on
  # empty state against the new version first and log what changed here, the same way this
  # entry does. Local dev should also pin via `tfenv` + a `.terraform-version` file (see
  # docs/tech-stack-versions.md) so `terraform -version` matches CI exactly, not just satisfies
  # this range.
  required_version = "~> 1.13.0"

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
