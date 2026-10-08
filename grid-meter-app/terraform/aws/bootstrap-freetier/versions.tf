terraform {
  # Tightened from ">= 1.11.0" to `~> 1.13.0`, matching terraform/aws/versions.tf's identical
  # change (2026-10-08) - see that file's own comment for the full account: a real cross-version
  # behavioral difference in `terraform output -raw` on empty state (1.13.2 leaks a warning onto
  # stdout, 1.16.4 doesn't) broke a live CI check, and this dev machine's actual installed
  # version had silently drifted from the 1.13.2 this comment used to claim (via an unpinned
  # `brew upgrade` from an unrelated earlier Terraform project) without anyone noticing until
  # that bug surfaced. `~>` (not an exact pin) blocks that same minor-version drift while still
  # allowing bug-fix-only patch bumps, matching the `required_providers` convention below.
  required_version = "~> 1.13.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Current stable on the Terraform Registry as of 2026-09-17 - verified
      # directly against registry.terraform.io, not assumed.
      version = "~> 6.65"
    }
  }

  # Deliberately local state for this module only. It creates the S3
  # bucket + DynamoDB table that the rest of terraform/aws/ uses as a
  # *remote* backend - this module can't depend on that backend without a
  # circular bootstrap problem, so its own state stays on disk. Run once,
  # rarely touched again after the bucket/table exist.
}
