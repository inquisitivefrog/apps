# terraform/azure/bootstrap

One-time setup: creates the Resource Group + Storage Account + Blob Container the rest of
`terraform/azure/` uses as a remote state backend. Run this once per Azure subscription before
touching anything else in `terraform/azure/`. Mirrors `terraform/aws/bootstrap/` and
`terraform/gcp/bootstrap/`'s role exactly.

Uses **local** state itself, deliberately — it can't depend on the Storage Account backend it's
creating without a circular bootstrap problem. Once applied, this module is rarely touched again
(only if the state Storage Account itself needs to change).

**Naming**: Azure Storage Account names are the strictest of the three clouds' state-backend
naming rules — 3-24 characters, lowercase letters and digits only (no hyphens), globally unique
across *every* Azure customer, not just this subscription. `grid-meter-app`'s own hyphens don't
fit that alphabet, so `main.tf` strips them and appends the first 8 characters of this
subscription's own GUID for uniqueness (`gridmeterapptf<8-char-suffix>`, 22 characters) — the same
"derive uniqueness from a real identifier already on hand" reasoning as AWS's account-ID suffix and
GCP's project-ID suffix, just adapted to a tighter character budget.

**Locking**: confirmed live (web search against Terraform's own `azurerm` backend docs,
2026-09-22) that state locking is built on Azure Blob's native lease mechanism — enabled by
default, no `use_lockfile`-style flag to declare (like GCS, unlike S3's opt-in flag or
DynamoDB-table approach) and no separate lock-table resource to create.

**Provider schema verified live, not assumed from docs**: installed `azurerm` into a scratch
directory and inspected `terraform providers schema -json` directly before writing `main.tf` —
azurerm 4.0 and 5.0 both carried real breaking schema changes (e.g. `azurerm_storage_container`
now takes `storage_account_id`, not the older `storage_account_name` argument some still-current
blog posts and even one web search summary suggested), so trusting stale secondary sources here
specifically was worth avoiding. Current stable as of 2026-09-22: 5.6.0; pinned `~> 5.5`.

## Usage

```bash
cd terraform/azure/bootstrap
terraform init
terraform plan   # review what will be created - one Resource Group, one Storage Account, one container
terraform apply
terraform output backend_config_snippet   # paste this into ../backend.tf
```

## What this creates

- One Resource Group (`grid-meter-app-tfstate-rg`).
- One Storage Account (`gridmeterapptf<8-char-subscription-suffix>`), Standard/LRS (cheapest,
  single-region — same cost-conscious sizing reasoning as AWS's/GCP's single-region state
  buckets), blob versioning enabled, all public access blocked
  (`allow_nested_items_to_be_public = false`), TLS 1.2 minimum.
- One private Blob Container (`tfstate`) inside it, to hold the actual state blob.

`prevent_destroy` is set on both the Resource Group and the Storage Account so a stray
`terraform destroy` here can't take the state backend (and therefore every other module's state)
down with it.

## Teardown

Only tear this down after every other `terraform/azure/*` module has already been destroyed and
you're certain the state history isn't needed. `prevent_destroy` will block a plain `destroy` —
remove those lifecycle blocks deliberately first if you really mean to delete the Storage Account.
