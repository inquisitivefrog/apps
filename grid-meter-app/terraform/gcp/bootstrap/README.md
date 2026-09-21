# terraform/gcp/bootstrap

One-time setup: creates the GCS bucket the rest of `terraform/gcp/` uses as a remote state
backend. Run this once per GCP project before touching anything else in `terraform/gcp/`. Mirrors
`terraform/aws/bootstrap/`'s role exactly.

Uses **local** state itself, deliberately — it can't depend on the GCS backend it's creating
without a circular bootstrap problem. Once applied, this module is rarely touched again (only if
the state bucket itself needs to change).

**Locking**: the `gcs` backend has no `use_lockfile`-style flag to declare — unlike S3, GCS-backed
state locking is always on (built on the bucket object's own generation-precondition writes), not
an optional setting. Declaring this explicitly here since it's the kind of "is this actually
guaranteed" question this project's own standing discipline says to check rather than assume — this
one resolved to "yes, unconditionally," not a gap.

**Encryption at rest**: also always-on and not a separate resource to declare — every GCS bucket is
encrypted server-side by default with Google-managed keys, unlike AWS S3 where
`aws_s3_bucket_server_side_encryption_configuration` is a resource you must add yourself.

## Usage

```bash
cd terraform/gcp/bootstrap
terraform init
terraform plan   # review what will be created - one GCS bucket, versioned, public access blocked
terraform apply
terraform output backend_config_snippet   # paste this into ../backend.tf
```

## What this creates

- One GCS bucket (`<project_name>-tfstate-<gcp_project_id>`), versioned, all public access blocked
  (`public_access_prevention = "enforced"` plus `uniform_bucket_level_access = true`).
  `prevent_destroy` is set so a stray `terraform destroy` here can't take the state bucket (and
  therefore every other module's state) down with it.

## Teardown

Only tear this down after every other `terraform/gcp/*` module has already been destroyed and
you're certain the state history isn't needed. `prevent_destroy` will block a plain `destroy` -
remove that lifecycle block deliberately first if you really mean to delete the bucket.
