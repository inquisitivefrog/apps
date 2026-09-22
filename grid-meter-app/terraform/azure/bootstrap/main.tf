# Everything in Azure lives inside a Resource Group - no direct AWS/GCP equivalent (closest analog
# is "a set of tags", but this is a real container resources are created *inside*, not a label
# applied after the fact). One dedicated group for the state backend, separate from whatever
# Resource Group(s) the main config creates later, so this bootstrap module's own lifecycle stays
# independent of the infrastructure it backs.
resource "azurerm_resource_group" "tfstate" {
  name     = "${var.project_name}-tfstate-rg"
  location = var.azure_region

  # Never let a stray `terraform destroy` of this bootstrap module take the state Storage Account
  # (and therefore every other module's state) with it - same protection as the AWS bootstrap
  # module's S3 bucket and the GCP bootstrap module's GCS bucket.
  lifecycle {
    prevent_destroy = true
  }
}

# Storage Account names are globally unique across every Azure customer, not just this
# subscription - same class of constraint as GCS bucket names, but stricter in shape: 3-24
# characters, lowercase letters and digits ONLY, no hyphens allowed. "grid-meter-app" itself
# doesn't fit that alphabet, so the hyphens are stripped and a short, deterministic suffix (the
# first 8 characters of this subscription's own GUID, itself already globally unique) is appended
# for uniqueness - the same "derive uniqueness from a real identifier already on hand" reasoning
# AWS's account-ID suffix and GCP's project-ID suffix both used, adapted to fit Azure's tighter
# character budget (24 total, vs. S3/GCS's much more permissive 63).
data "azurerm_client_config" "current" {}

locals {
  subscription_suffix  = substr(lower(replace(data.azurerm_client_config.current.subscription_id, "-", "")), 0, 8)
  storage_account_name = "gridmeterapptf${local.subscription_suffix}" # 14 + 8 = 22 chars, under the 24-char limit
}

resource "azurerm_storage_account" "tfstate" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.tfstate.name
  location            = var.azure_region

  # Standard/LRS (locally-redundant storage, single-region) - the cheapest replication tier,
  # matching AWS's single-region S3 bucket and GCP's single-region GCS bucket for the same
  # cost-conscious reasoning. Geo-redundancy would be real production hardening this demo project
  # doesn't need.
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false # blocks anonymous public access to blobs/containers at the account level - the Azure equivalent of GCS's public_access_prevention = "enforced" and S3's public access block settings.

  blob_properties {
    # Versioning is what makes a bad `apply` recoverable - a corrupted or accidentally-overwritten
    # state blob can be rolled back to a prior version. Same role as the S3/GCS buckets'
    # versioning = true.
    versioning_enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# The actual container (Azure's rough equivalent of an S3/GCS "folder" - a real sub-resource here,
# not just a key prefix) that will hold the tfstate blob itself.
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id # NOT storage_account_name - confirmed via the real provider schema (azurerm 5.x), a genuine breaking change from older azurerm versions' storage_account_name argument.
  container_access_type = "private"
}

# Locking: unlike AWS's S3 backend (locking is either DynamoDB-based or the newer opt-in
# use_lockfile flag) and consistent with GCS (always-on, no separate flag), the azurerm backend's
# state locking is built on Azure Blob's own lease mechanism - enabled by default, no separate flag
# to declare and no separate resource (no DynamoDB-equivalent table) to create. Confirmed live via
# web search against Terraform's own azurerm backend documentation (2026-09-22), not assumed.
