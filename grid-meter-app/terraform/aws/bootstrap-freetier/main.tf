provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

data "aws_caller_identity" "current" {}

# S3 bucket names are globally unique across every AWS account, so the
# account ID is baked into the name rather than risking a collision with
# someone else's "grid-meter-app-tfstate" bucket.
locals {
  bucket_name = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = local.bucket_name

  # Never let a stray `terraform destroy` of this bootstrap module take the
  # state bucket (and therefore every other module's state) with it.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    # Versioning is what makes a bad `apply` recoverable - a corrupted or
    # accidentally-overwritten state file can be rolled back to a prior
    # object version.
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
