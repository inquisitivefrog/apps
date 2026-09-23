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

# Found via a real live apply failure (2026-09-23): rbac_authorization_enabled = true means
# creating the vault does NOT implicitly grant the deploying principal any access to its secrets -
# unlike the older access_policy model, where the creator could pre-grant themselves permissions
# inline. Writing the secret below failed with a 403 Forbidden until this explicit role assignment
# exists. "Key Vault Secrets Officer" is the standard RBAC role for full secret read/write.
resource "azurerm_role_assignment" "deployer_kv_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Azure RBAC role assignments have a genuine, undocumented-duration propagation delay before
# they're actually enforced (the 403 error above says as much: "If role assignments... were
# changed recently, please observe propagation time") - and unlike every other wait in this
# project (which polls a real status field), there's no live "is this role assignment propagated
# yet" API to poll here. A fixed sleep is the documented, widely-used Terraform workaround for
# this specific, well-known Azure RBAC limitation - a deliberate, explained exception to this
# project's own "poll, don't sleep" rule, not an unexamined shortcut.
resource "time_sleep" "rbac_propagation" {
  depends_on      = [azurerm_role_assignment.deployer_kv_secrets]
  create_duration = "30s"
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  value        = random_password.postgres.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [time_sleep.rbac_propagation]
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

  # Found via a real live apply failure (2026-09-23): "ConflictingPublicNetworkAccessAndVirtualNetworkConfiguration"
  # - public_network_access_enabled's own default (computed, not documented as false) conflicts
  # outright with delegated_subnet_id/private_dns_zone_id below once actually applied. Declared
  # explicitly rather than left as an undeclared default, same "declare load-bearing defaults"
  # principle this project applies everywhere else - and matches the private-only posture AWS's
  # RDS/GCP's Cloud SQL both already have.
  public_network_access_enabled = false

  # No explicit `zone` argument - left out deliberately (was `zone = "1"`) after the same real
  # zone-restriction finding as aks.tf's node pool (variables.tf's aks_availability_zones): this
  # subscription's free-trial tier doesn't support availability-zone pinning at all. Azure picks a
  # zone automatically when it's omitted. Still effectively single-zone either way (this project's
  # local track already builds real Postgres HA by hand, docs/postgres-ha-scope.md) - only the
  # explicit pinning was dropped, not the cost-conscious single-instance sizing itself.
  #
  # zone is optional+computed on this resource: once Azure auto-assigns one at creation, leaving
  # the argument absent from config makes every later plan try to "correct" it back to unset -
  # which a real live apply failure (2026-09-23) confirmed the API rejects outright ("`zone` can
  # only be changed when exchanged with the zone specified in
  # `high_availability.0.standby_availability_zone`", not a true in-place-updatable attribute at
  # all). ignore_changes is the correct tool here, not a workaround: this project genuinely
  # doesn't care which zone Azure picked, so there's nothing to reconcile.
  lifecycle {
    ignore_changes = [zone]
  }

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
