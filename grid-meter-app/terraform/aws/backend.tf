# Generated from terraform/aws/bootstrap-freetier's own `terraform output backend_config_snippet`
# after that module was applied (2026-10-06) - bucket already exists, not created by this
# config. See bootstrap-freetier/README.md for why this project's state lives in S3 rather than
# locally, and why there's no dynamodb_table argument (S3-native locking via use_lockfile,
# Terraform 1.11+, confirmed against HashiCorp's own docs - the older DynamoDB pattern is
# now deprecated).
#
# Repointed 2026-10-06 from the original account (084375569056, bucket
# grid-meter-app-tfstate-084375569056, now dormant/unused - its own bootstrap/ directory is
# left intact in case that account is ever needed again) to a second, newer AWS account
# (184375956348) created specifically for low-cost interview-cycle hosting under a free-tier/
# credits program. region is us-east-2, not this project's usual us-west-2 - confirmed live
# that an AWS Organizations SCP applied to this account (managed by a separate org/payer
# account this project has no visibility into) explicitly denies EC2/S3 operations in
# us-east-1 and us-west-2, but allows us-east-2 - see variables.tf's aws_region default for
# the full finding.
terraform {
  backend "s3" {
    bucket       = "grid-meter-app-tfstate-184375956348"
    key          = "grid-meter-app/terraform.tfstate"
    region       = "us-east-2"
    profile      = "grid-meter-freetier"
    use_lockfile = true
  }
}
