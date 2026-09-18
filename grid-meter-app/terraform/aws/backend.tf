# Generated from terraform/aws/bootstrap's own `terraform output backend_config_snippet`
# after that module was applied (2026-09-18) - bucket already exists, not created by this
# config. See bootstrap/README.md for why this project's state lives in S3 rather than
# locally, and why there's no dynamodb_table argument (S3-native locking via use_lockfile,
# Terraform 1.11+, confirmed against HashiCorp's own docs - the older DynamoDB pattern is
# now deprecated).
terraform {
  backend "s3" {
    bucket       = "grid-meter-app-tfstate-084375569056"
    key          = "grid-meter-app/terraform.tfstate"
    region       = "us-west-2"
    profile      = "grid-meter"
    use_lockfile = true
  }
}
