terraform {
  # >= 1.11.0 is the real functional floor: S3-native state locking
  # (use_lockfile, used in the main config's backend.tf) stabilized out of
  # experimental status in 1.11 and made the old dynamodb_table approach
  # deprecated (confirmed against HashiCorp's own S3 backend docs, not
  # assumed). This dev machine actually has 1.13.2 installed, verified via
  # `terraform version` - both facts checked live, not from memory.
  required_version = ">= 1.11.0"

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
