locals {
  # Applied explicitly to every resource that supports `tags` - see providers.tf for why this
  # can't be a provider-level default_tags/default_labels block the way AWS/GCP's configs use.
  common_tags = {
    managed-by = "terraform"
    project    = var.project_name
  }

  resource_group_name = "${var.project_name}-rg"

  # ACR names, like Storage Account names, are globally unique across all of Azure and share the
  # same tight alphabet constraint (alphanumeric only, no hyphens) - see
  # terraform/azure/bootstrap/main.tf's storage_account_name local for the identical reasoning,
  # reused here with the same subscription-ID-suffix approach for uniqueness.
  subscription_suffix = substr(lower(replace(data.azurerm_client_config.current.subscription_id, "-", "")), 0, 8)
  acr_name            = "gridmeterapp${local.subscription_suffix}" # "gridmeterapp" (12) + 8 = 20 chars, under ACR's 5-50 char limit with room to spare
}

data "azurerm_client_config" "current" {}
