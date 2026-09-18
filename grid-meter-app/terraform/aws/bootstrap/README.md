# terraform/aws/bootstrap

One-time setup: creates the S3 bucket the rest of `terraform/aws/` uses as a remote state
backend. Run this once per AWS account before touching anything else in `terraform/aws/`.

Uses **local** state itself, deliberately — it can't depend on the S3 backend it's creating
without a circular bootstrap problem. Once applied, this module is rarely touched again (only if
the state bucket itself needs to change).

No DynamoDB table: as of Terraform 1.11+, the S3 backend supports native state locking via
`use_lockfile = true` (S3 conditional writes) — the older S3+DynamoDB locking pattern is now
deprecated by HashiCorp. This dev machine runs Terraform 1.13.2, confirmed via `terraform version`.

## Usage

```bash
cd terraform/aws/bootstrap
terraform init
terraform plan   # review what will be created - one S3 bucket, versioned + encrypted
terraform apply
terraform output backend_config_snippet   # paste this into ../backend.tf
```

## What this creates

- One S3 bucket (`<project_name>-tfstate-<your-account-id>`), versioned, AES256-encrypted at
  rest, all public access blocked. `prevent_destroy` is set so a stray `terraform destroy` here
  can't take the state bucket (and therefore every other module's state) down with it.

## Teardown

Only tear this down after every other `terraform/aws/*` module has already been destroyed and
you're certain the state history isn't needed. `prevent_destroy` will block a plain `destroy` -
remove that lifecycle block deliberately first if you really mean to delete the bucket.
