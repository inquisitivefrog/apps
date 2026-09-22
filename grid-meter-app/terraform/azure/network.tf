resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.azure_region
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region
  address_space       = [var.vnet_cidr]
  tags                = local.common_tags
}

# AKS node subnet. Azure CNI Overlay (aks.tf) means pods draw IPs from a private overlay range
# that never touches this subnet - it only ever needs to hold node IPs, so it's sized small
# (/24) rather than the much larger secondary range GCP's VPC-native GKE needed for pod IPs
# directly in VNet space.
resource "azurerm_subnet" "aks" {
  name                 = "${var.project_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_cidr]
}

# Postgres Flexible Server's private networking requires its own DEDICATED, DELEGATED subnet -
# a real structural requirement neither AWS's RDS (just needs private-subnet placement) nor
# GCP's Cloud SQL (private IP via the shared PSA peering range) has. The delegation tells Azure
# this subnet exists purely to host Flexible Server instances' network interfaces, not general
# compute.
resource "azurerm_subnet" "postgres" {
  name                 = "${var.project_name}-postgres-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.postgres_subnet_cidr]

  delegation {
    name = "postgres-flexible-server-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Private DNS zone Postgres Flexible Server's private networking resolves its own hostname
# through - required alongside the delegated subnet above; Azure's private-networking Postgres
# setup is genuinely more moving parts than AWS's/GCP's own private-database networking, not a
# simplification opportunity skipped here.
resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.project_name}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  # Confirmed via the real provider schema after a validate-time error: this resource takes
  # private_dns_zone_id (not private_dns_zone_name) and has no resource_group_name argument at
  # all (inferred from the zone ID) - my first draft guessed both wrong.
  name                = "${var.project_name}-postgres-dns-link"
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id
  virtual_network_id  = azurerm_virtual_network.main.id
}

# Note: no explicit NSG (Network Security Group) resources here, deliberately - AKS manages the
# node-to-control-plane and node-to-node rules it needs automatically on cluster creation, the
# same "the platform auto-creates what it needs" pattern already confirmed for GKE (network.tf's
# own note there). Re-verify this specific claim against AKS's own documentation before the real
# apply if anything looks blocked at the network layer, rather than assume it holds identically.
