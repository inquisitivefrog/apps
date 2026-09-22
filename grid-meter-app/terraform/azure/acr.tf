# Azure Container Registry - the Azure equivalent of AWS's ECR / GCP's Artifact Registry. Unlike
# GCP's Artifact Registry (a namespace holding separately-named images - the real bug found live
# in the GCP session's outputs.tf) or AWS's ECR (repo IS the image), ACR is closer to GCP's model:
# ONE registry instance per subscription is typical, holding multiple image repositories inside it
# by path (e.g. "grid-meter-app-api", "grid-meter-app-frontend" as repository paths within this
# single registry, not two separate azurerm_container_registry resources) - confirmed via ACR's
# own documented image-naming model (<registry>.azurecr.io/<repository-path>:<tag>) before writing
# this as a single resource rather than two, avoiding the GCP session's own "assumed the wrong
# repo-vs-image model" mistake a second time.
resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region
  sku                 = var.acr_sku

  # Basic SKU doesn't support disabling admin_enabled's default meaningfully differently from
  # explicit false - declared explicitly anyway per this project's "declare load-bearing defaults"
  # habit. Pulls/pushes go through the AKS kubelet identity's AcrPull role assignment (aks.tf) and
  # this dev machine's own `az acr login`-based Docker credential helper, not the registry's
  # built-in admin account.
  admin_enabled = false

  tags = local.common_tags
}
