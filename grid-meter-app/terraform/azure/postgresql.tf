# Azure Database for PostgreSQL Flexible Server has no AWS-RDS-style
# manage_master_user_password convenience (confirmed via the real provider schema - only a plain
# administrator_password/administrator_password_wo pair, no auto-generation flag), the same gap
# GCP's Cloud SQL had. Wired up the same idiomatic substitute GCP used: random_password + a
# managed secret store - Azure Key Vault here, filling the role Secret Manager filled for GCP.
resource "random_password" "postgres" {
  length  = 32
  special = false # keeps this simple to pass through shells/connection strings unescaped, same reasoning as the AWS/GCP passwords
}

resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-kv"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard" # cheapest/only non-HSM tier - Premium adds HSM-backed keys this project has no use for

  # Azure RBAC-based authorization (rbac_authorization_enabled = true), not the older
  # access_policy list model - confirmed via the real provider schema that this is a required
  # attribute, not optional, and that its actual name is rbac_authorization_enabled, not the
  # enable_rbac_authorization name some older docs/examples still show. Matches this project's
  # broader preference for RBAC-shaped access control over bespoke policy lists.
  rbac_authorization_enabled = true

  purge_protection_enabled   = false # demo project, not production - a stray `terraform destroy` should actually delete the vault, not leave it in a purge-protected limbo
  soft_delete_retention_days = 7     # Azure's own minimum

  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  value        = random_password.postgres.result
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "${var.project_name}-postgres"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region

  version                = var.postgres_version
  sku_name               = var.postgres_sku_name
  storage_mb             = var.postgres_storage_mb
  administrator_login    = var.postgres_admin_user
  administrator_password = random_password.postgres.result

  zone = "1" # single-zone, matching AWS's multi_az=false and GCP's availability_type=ZONAL cost-conscious sizing - this project's local track already builds real Postgres HA by hand (docs/postgres-ha-scope.md)

  # Private networking via the dedicated delegated subnet + private DNS zone (network.tf) -
  # matches AWS's RDS (private subnet, publicly_accessible=false) and GCP's Cloud SQL
  # (private IP only) posture exactly, just via Azure's own two-extra-resource mechanism rather
  # than a single flag.
  delegated_subnet_id = azurerm_subnet.postgres.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres] # the DNS zone must actually be linked to the VNet before Flexible Server tries to provision into it

  tags = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.postgres_db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8" # Postgres Flexible Server's own Linux-locale-name spelling, not Cloud SQL's "en_US.UTF8" - re-verify the exact accepted string live before apply if this errors
}
