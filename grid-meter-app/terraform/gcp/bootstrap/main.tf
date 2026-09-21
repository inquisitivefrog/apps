provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# GCS bucket names are globally unique across every GCP project, not just
# this one - the project ID (itself already globally unique) is baked into
# the name rather than risking a collision with someone else's
# "grid-meter-app-tfstate" bucket, same reasoning as the AWS bootstrap
# module's account-ID suffix.
locals {
  bucket_name = "${var.project_name}-tfstate-${var.gcp_project_id}"
}

resource "google_storage_bucket" "tfstate" {
  name     = local.bucket_name
  location = upper(var.gcp_region)

  # Never let a stray `terraform destroy` of this bootstrap module take the
  # state bucket (and therefore every other module's state) with it - same
  # protection as the AWS bootstrap module's S3 bucket.
  lifecycle {
    prevent_destroy = true
  }

  versioning {
    # Versioning is what makes a bad `apply` recoverable - a corrupted or
    # accidentally-overwritten state object can be rolled back to a prior
    # generation.
    enabled = true
  }

  # public_access_prevention = "enforced" is the modern, stronger GCS
  # equivalent of the AWS bucket's four aws_s3_bucket_public_access_block
  # settings - it blocks public access at the bucket level regardless of any
  # IAM policy grant, not just ACLs. uniform_bucket_level_access disables
  # the older per-object ACL system entirely so access is IAM-only,
  # confirmed as Google's own current recommended default for new buckets.
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}
