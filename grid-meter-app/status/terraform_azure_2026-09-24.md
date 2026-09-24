
tim@Timothys-MacBook-Air grid-meter-app % cd terraform/azure 
tim@Timothys-MacBook-Air azure % az login
WARNING: A web browser has been opened at https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize. Please continue the login in the web browser. If no web browser is available or if the web browser fails to open, use device code flow with `az login --use-device-code`.

Retrieving tenants and subscriptions for the selection...

[Tenant and subscription selection]

No     Subscription name     Subscription ID                       Tenant
-----  --------------------  ------------------------------------  -----------------
[1] *  Azure subscription 1  3caa5ec0-0d3e-4cd0-98ec-a584c3421a54  Default Directory

The default is marked with an *; the default tenant is 'Default Directory' and subscription is 'Azure subscription 1' (3caa5ec0-0d3e-4cd0-98ec-a584c3421a54).

Select a subscription and tenant (Type a number or Enter for no changes): 1

Tenant: Default Directory
Subscription: Azure subscription 1 (3caa5ec0-0d3e-4cd0-98ec-a584c3421a54)

[Announcements]
With the new Azure CLI login experience, you can select the subscription you want to use more easily. Learn more about it and its configuration at https://go.microsoft.com/fwlink/?linkid=2271236

If you encounter any problem, please open an issue at https://aka.ms/azclibug

WARNING: [Warning] The login output has been updated. Please be aware that it no longer displays the full list of available subscriptions by default.

tim@Timothys-MacBook-Air azure % az provider list --output table | grep 'Name\|Registered' | grep -v NotRegistered
Namespace                                                RegistrationPolicy    RegistrationState
Microsoft.ManagedIdentity                                RegistrationRequired  Registered
Microsoft.Storage                                        RegistrationRequired  Registered
Microsoft.ContainerService                               RegistrationRequired  Registered
Microsoft.DBforPostgreSQL                                RegistrationRequired  Registered
Microsoft.Cache                                          RegistrationRequired  Registered
Microsoft.ContainerRegistry                              RegistrationRequired  Registered
Microsoft.Network                                        RegistrationRequired  Registered
Microsoft.Compute                                        RegistrationRequired  Registered
Microsoft.OperationalInsights                            RegistrationRequired  Registered
microsoft.insights                                       RegistrationRequired  Registered
Microsoft.KeyVault                                       RegistrationRequired  Registered
Microsoft.ADHybridHealthService                          RegistrationFree      Registered
Microsoft.Authorization                                  RegistrationFree      Registered
Microsoft.Billing                                        RegistrationFree      Registered
Microsoft.ChangeSafety                                   RegistrationFree      Registered
Microsoft.Commerce                                       RegistrationFree      Registered
Microsoft.Consumption                                    RegistrationFree      Registered
Microsoft.CostManagement                                 RegistrationFree      Registered
Microsoft.Features                                       RegistrationFree      Registered
Microsoft.MarketplaceOrdering                            RegistrationFree      Registered
Microsoft.Portal                                         RegistrationFree      Registered
Microsoft.ResourceGraph                                  RegistrationFree      Registered
Microsoft.ResourceIntelligence                           RegistrationFree      Registered
Microsoft.ResourceNotifications                          RegistrationFree      Registered
Microsoft.Resources                                      RegistrationFree      Registered
Microsoft.SerialConsole                                  RegistrationFree      Registered
microsoft.support                                        RegistrationFree      Registered

tim@Timothys-MacBook-Air azure % terraform init
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Reusing previous version of hashicorp/random from the dependency lock file
- Reusing previous version of hashicorp/time from the dependency lock file
- Using previously-installed hashicorp/azurerm v5.6.0
- Using previously-installed hashicorp/random v3.9.1
- Using previously-installed hashicorp/time v0.14.2

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
tim@Timothys-MacBook-Air azure % terraform fmt 
tim@Timothys-MacBook-Air azure % terraform validate
Success! The configuration is valid.

tim@Timothys-MacBook-Air azure % terraform plan -out tfplan
Acquiring state lock. This may take a few moments...
data.azurerm_client_config.current: Reading...
data.azurerm_client_config.current: Read complete after 0s [id=Y2xpZW50Q29uZmlncy9jbGllbnRJZD0wNGIwNzc5NS04ZGRiLTQ2MWEtYmJlZS0wMmY5ZTFiZjdiNDY7b2JqZWN0SWQ9Njk3MGVjMzUtYTQxNi00MTY3LThiOGQtNzU5MmM3MjY5ZGM3O3N1YnNjcmlwdGlvbklkPTNjYWE1ZWMwLTBkM2UtNGNkMC05OGVjLWE1ODRjMzQyMWE1NDt0ZW5hbnRJZD05MTczNzQ2OS00OTY1LTRkMmYtYTcyZC05YmE4YTUzMWEzNTU=]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_container_registry.main will be created
  + resource "azurerm_container_registry" "main" {
      + admin_enabled                                = false
      + admin_password                               = (sensitive value)
      + admin_username                               = (known after apply)
      + azuread_authentication_as_arm_policy_enabled = true
      + data_endpoint_host_names                     = (known after apply)
      + export_policy_enabled                        = true
      + id                                           = (known after apply)
      + location                                     = "centralus"
      + login_server                                 = (known after apply)
      + name                                         = "gridmeterapp3caa5ec0"
      + network_rule_bypass_for_tasks_enabled        = false
      + network_rule_bypass_option                   = "AzureServices"
      + network_rule_set                             = (known after apply)
      + public_network_access_enabled                = true
      + resource_group_name                          = "grid-meter-app-rg"
      + role_assignment_mode                         = "LegacyRegistryPermissions"
      + sku                                          = "Basic"
      + tags                                         = {
          + "managed-by" = "terraform"
          + "project"    = "grid-meter-app"
        }
      + zone_redundancy_enabled                      = false
    }

  # azurerm_federated_identity_credential.app will be created
  + resource "azurerm_federated_identity_credential" "app" {
      + audience                  = [
          + "api://AzureADTokenExchange",
        ]
      + id                        = (known after apply)
      + issuer                    = (known after apply)
      + name                      = "grid-meter-app-app-fic"
      + subject                   = "system:serviceaccount:default:grid-meter-app"
      + user_assigned_identity_id = (known after apply)
    }

  # azurerm_key_vault.main will be created
  + resource "azurerm_key_vault" "main" {
      + access_policy                 = (known after apply)
      + id                            = (known after apply)
      + location                      = "centralus"
      + name                          = "grid-meter-app-kv"
      + public_network_access_enabled = true
      + purge_protection_enabled      = false
      + rbac_authorization_enabled    = true
      + resource_group_name           = "grid-meter-app-rg"
      + sku_name                      = "standard"
      + soft_delete_retention_days    = 7
      + tags                          = {
          + "managed-by" = "terraform"
          + "project"    = "grid-meter-app"
        }
      + tenant_id                     = "91737469-4965-4d2f-a72d-9ba8a531a355"
      + vault_uri                     = (known after apply)

      + network_acls (known after apply)
    }

  # azurerm_key_vault_secret.postgres_password will be created
  + resource "azurerm_key_vault_secret" "postgres_password" {
      + id                      = (known after apply)
      + key_vault_id            = (known after apply)
      + name                    = "postgres-admin-password"
      + resource_id             = (known after apply)
      + resource_versionless_id = (known after apply)
      + value                   = (sensitive value)
      + value_wo                = (write-only attribute)
      + version                 = (known after apply)
      + versionless_id          = (known after apply)
    }

  # azurerm_kubernetes_cluster.main will be created
  + resource "azurerm_kubernetes_cluster" "main" {
      + ai_toolchain_operator_enabled       = false
      + current_kubernetes_version          = (known after apply)
      + dns_prefix                          = "grid-meter-app"
      + fqdn                                = (known after apply)
      + http_application_routing_zone_name  = (known after apply)
      + id                                  = (known after apply)
      + kube_admin_config                   = (sensitive value)
      + kube_admin_config_raw               = (sensitive value)
      + kube_config                         = (sensitive value)
      + kube_config_raw                     = (sensitive value)
      + kubernetes_version                  = (known after apply)
      + location                            = "centralus"
      + name                                = "grid-meter-app-aks"
      + node_os_upgrade_channel             = "NodeImage"
      + node_resource_group                 = (known after apply)
      + node_resource_group_id              = (known after apply)
      + oidc_issuer_enabled                 = true
      + oidc_issuer_url                     = (known after apply)
      + portal_fqdn                         = (known after apply)
      + private_cluster_enabled             = false
      + private_cluster_public_fqdn_enabled = false
      + private_dns_zone_id                 = (known after apply)
      + private_fqdn                        = (known after apply)
      + resource_group_name                 = "grid-meter-app-rg"
      + role_based_access_control_enabled   = true
      + run_command_enabled                 = true
      + sku_tier                            = "Free"
      + support_plan                        = "KubernetesOfficial"
      + tags                                = {
          + "managed-by" = "terraform"
          + "project"    = "grid-meter-app"
        }
      + workload_identity_enabled           = true

      + auto_scaler_profile (known after apply)

      + bootstrap_profile (known after apply)

      + default_node_pool {
          + kubelet_disk_type            = (known after apply)
          + max_pods                     = (known after apply)
          + name                         = "system"
          + node_count                   = 2
          + node_labels                  = (known after apply)
          + only_critical_addons_enabled = false
          + orchestrator_version         = (known after apply)
          + os_disk_size_gb              = 30
          + os_disk_type                 = "Managed"
          + os_sku                       = (known after apply)
          + scale_down_mode              = "Delete"
          + type                         = "VirtualMachineScaleSets"
          + ultra_ssd_enabled            = false
          + vm_size                      = "Standard_D2as_v7"
          + vnet_subnet_id               = (known after apply)
          + workload_runtime             = (known after apply)

          + upgrade_settings {
              + drain_timeout_in_minutes      = 0
              + max_surge                     = "10%"
              + node_soak_duration_in_minutes = 0
            }
        }

      + identity {
          + principal_id = (known after apply)
          + tenant_id    = (known after apply)
          + type         = "SystemAssigned"
        }

      + kubelet_identity (known after apply)

      + network_profile {
          + dns_service_ip      = "10.245.0.10"
          + ip_versions         = (known after apply)
          + load_balancer_sku   = "standard"
          + network_data_plane  = "azure"
          + network_mode        = (known after apply)
          + network_plugin      = "azure"
          + network_plugin_mode = "overlay"
          + network_policy      = "azure"
          + outbound_type       = "loadBalancer"
          + pod_cidr            = "10.244.0.0/16"
          + pod_cidrs           = (known after apply)
          + service_cidr        = "10.245.0.0/16"
          + service_cidrs       = (known after apply)

          + load_balancer_profile (known after apply)

          + nat_gateway_profile (known after apply)
        }

      + node_provisioning_profile {
          + default_node_pools = "Auto"
          + mode               = "Manual"
        }

      + windows_profile (known after apply)
    }

  # azurerm_managed_redis.main will be created
  + resource "azurerm_managed_redis" "main" {
      + high_availability_enabled = false
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + location                  = "centralus"
      + name                      = "grid-meter-app-redis"
      + public_network_access     = "Enabled"
      + resource_group_name       = "grid-meter-app-rg"
      + sku_name                  = "Balanced_B0"
      + tags                      = {
          + "managed-by" = "terraform"
          + "project"    = "grid-meter-app"
        }

      + default_database {
          + access_keys_authentication_enabled = false
          + client_protocol                    = "Encrypted"
          + clustering_policy                  = "OSSCluster"
          + eviction_policy                    = "VolatileLRU"
          + id                                 = (known after apply)
          + port                               = (known after apply)
          + primary_access_key                 = (sensitive value)
          + secondary_access_key               = (sensitive value)
        }
    }

  # azurerm_managed_redis_access_policy_assignment.app will be created
  + resource "azurerm_managed_redis_access_policy_assignment" "app" {
      + id               = (known after apply)
      + managed_redis_id = (known after apply)
      + object_id        = (known after apply)
    }

  # azurerm_postgresql_flexible_server.main will be created
  + resource "azurerm_postgresql_flexible_server" "main" {
      + administrator_login           = "gridmeter"
      + administrator_password        = (sensitive value)
      + administrator_password_wo     = (write-only attribute)
      + auto_grow_enabled             = false
      + backup_retention_days         = (known after apply)
      + delegated_subnet_id           = (known after apply)
      + fqdn                          = (known after apply)
      + geo_redundant_backup_enabled  = false
      + id                            = (known after apply)
      + location                      = "centralus"
      + name                          = "grid-meter-app-postgres"
      + private_dns_zone_id           = (known after apply)
      + public_network_access_enabled = false
      + resource_group_name           = "grid-meter-app-rg"
      + sku_name                      = "B_Standard_B1ms"
      + storage_iops                  = (known after apply)
      + storage_mb                    = 32768
      + storage_throughput            = (known after apply)
      + storage_tier                  = (known after apply)
      + storage_type                  = "Premium_LRS"
      + tags                          = {
          + "managed-by" = "terraform"
          + "project"    = "grid-meter-app"
        }
      + version                       = "18"

      + authentication (known after apply)
    }

  # azurerm_postgresql_flexible_server_database.main will be created
  + resource "azurerm_postgresql_flexible_server_database" "main" {
      + charset   = "UTF8"
      + collation = "en_US.utf8"
      + id        = (known after apply)
      + name      = "gridmeter"
      + server_id = (known after apply)
    }

  # azurerm_private_dns_zone.postgres will be created
  + resource "azurerm_private_dns_zone" "postgres" {
      + id                                                    = (known after apply)
      + max_number_of_record_sets                             = (known after apply)
      + max_number_of_virtual_network_links                   = (known after apply)
      + max_number_of_virtual_network_links_with_registration = (known after apply)
      + name                                                  = "grid-meter-app.postgres.database.azure.com"
      + number_of_record_sets                                 = (known after apply)
      + resource_group_name                                   = "grid-meter-app-rg"
      + tags                                                  = {
          + "managed-by" = "terraform"
          + "project"    = "grid-meter-app"
        }

      + soa_record (known after apply)
    }

  # azurerm_private_dns_zone_virtual_network_link.postgres will be created
  + resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
      + id                   = (known after apply)
      + name                 = "grid-meter-app-postgres-dns-link"
      + private_dns_zone_id  = (known after apply)
      + registration_enabled = false
      + resolution_policy    = (known after apply)
      + virtual_network_id   = (known after apply)
    }

  # azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + id       = (known after apply)
      + location = "centralus"
      + name     = "grid-meter-app-rg"
      + tags     = {
          + "managed-by" = "terraform"
          + "project"    = "grid-meter-app"
        }
    }

  # azurerm_role_assignment.aks_acr_pull will be created
  + resource "azurerm_role_assignment" "aks_acr_pull" {
      + condition_version                = (known after apply)
      + id                               = (known after apply)
      + name                             = (known after apply)
      + principal_id                     = (known after apply)
      + principal_type                   = (known after apply)
      + role_definition_id               = (known after apply)
      + role_definition_name             = "AcrPull"
      + scope                            = (known after apply)
      + skip_service_principal_aad_check = (known after apply)
    }

  # azurerm_role_assignment.deployer_kv_secrets will be created
  + resource "azurerm_role_assignment" "deployer_kv_secrets" {
      + condition_version                = (known after apply)
      + id                               = (known after apply)
      + name                             = (known after apply)
      + principal_id                     = "6970ec35-a416-4167-8b8d-7592c7269dc7"
      + principal_type                   = (known after apply)
      + role_definition_id               = (known after apply)
      + role_definition_name             = "Key Vault Secrets Officer"
      + scope                            = (known after apply)
      + skip_service_principal_aad_check = (known after apply)
    }

  # azurerm_subnet.aks will be created
  + resource "azurerm_subnet" "aks" {
      + address_prefixes                              = [
          + "10.20.0.0/24",
        ]
      + default_outbound_access_enabled               = true
      + id                                            = (known after apply)
      + name                                          = "grid-meter-app-aks-subnet"
      + network_security_group_id                     = (known after apply)
      + network_security_group_id_wo                  = (write-only attribute)
      + private_endpoint_network_policies             = "Disabled"
      + private_link_service_network_policies_enabled = true
      + resource_group_name                           = "grid-meter-app-rg"
      + route_table_id                                = (known after apply)
      + route_table_id_wo                             = (write-only attribute)
      + virtual_network_name                          = "grid-meter-app-vnet"
    }

  # azurerm_subnet.postgres will be created
  + resource "azurerm_subnet" "postgres" {
      + address_prefixes                              = [
          + "10.20.1.0/24",
        ]
      + default_outbound_access_enabled               = true
      + id                                            = (known after apply)
      + name                                          = "grid-meter-app-postgres-subnet"
      + network_security_group_id                     = (known after apply)
      + network_security_group_id_wo                  = (write-only attribute)
      + private_endpoint_network_policies             = "Disabled"
      + private_link_service_network_policies_enabled = true
      + resource_group_name                           = "grid-meter-app-rg"
      + route_table_id                                = (known after apply)
      + route_table_id_wo                             = (write-only attribute)
      + virtual_network_name                          = "grid-meter-app-vnet"

      + delegation {
          + name = "postgres-flexible-server-delegation"

          + service_delegation {
              + actions = [
                  + "Microsoft.Network/virtualNetworks/subnets/join/action",
                ]
              + name    = "Microsoft.DBforPostgreSQL/flexibleServers"
            }
        }
    }

  # azurerm_user_assigned_identity.app will be created
  + resource "azurerm_user_assigned_identity" "app" {
      + client_id           = (known after apply)
      + id                  = (known after apply)
      + location            = "centralus"
      + name                = "grid-meter-app-app-identity"
      + principal_id        = (known after apply)
      + resource_group_name = "grid-meter-app-rg"
      + tags                = {
          + "managed-by" = "terraform"
          + "project"    = "grid-meter-app"
        }
      + tenant_id           = (known after apply)
    }

  # azurerm_virtual_network.main will be created
  + resource "azurerm_virtual_network" "main" {
      + address_space                  = [
          + "10.20.0.0/16",
        ]
      + dns_servers                    = (known after apply)
      + guid                           = (known after apply)
      + id                             = (known after apply)
      + location                       = "centralus"
      + name                           = "grid-meter-app-vnet"
      + private_endpoint_vnet_policies = "Disabled"
      + resource_group_name            = "grid-meter-app-rg"
      + subnet                         = (known after apply)
      + tags                           = {
          + "managed-by" = "terraform"
          + "project"    = "grid-meter-app"
        }
    }

  # random_password.postgres will be created
  + resource "random_password" "postgres" {
      + bcrypt_hash = (sensitive value)
      + id          = (known after apply)
      + length      = 32
      + lower       = true
      + min_lower   = 0
      + min_numeric = 0
      + min_special = 0
      + min_upper   = 0
      + number      = true
      + numeric     = true
      + result      = (sensitive value)
      + special     = false
      + upper       = true
    }

  # time_sleep.rbac_propagation will be created
  + resource "time_sleep" "rbac_propagation" {
      + create_duration = "30s"
      + id              = (known after apply)
    }

Plan: 20 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + acr_login_server              = (known after apply)
  + aks_cluster_name              = "grid-meter-app-aks"
  + app_identity_client_id        = (known after apply)
  + azure_region                  = "centralus"
  + key_vault_name                = "grid-meter-app-kv"
  + kubeconfig_update_command     = "az aks get-credentials --resource-group grid-meter-app-rg --name grid-meter-app-aks --overwrite-existing"
  + node_resource_group           = (known after apply)
  + postgres_db_name              = "gridmeter"
  + postgres_fqdn                 = (known after apply)
  + postgres_password_secret_name = "postgres-admin-password"
  + postgres_user                 = "gridmeter"
  + redis_hostname                = (known after apply)
  + redis_port                    = (known after apply)
  + resource_group_name           = "grid-meter-app-rg"

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
Releasing state lock. This may take a few moments...

tim@Timothys-MacBook-Air azure % terraform apply tfplan
Acquiring state lock. This may take a few moments...
random_password.postgres: Creating...
random_password.postgres: Creation complete after 0s [id=none]
azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Still creating... [00m10s elapsed]
azurerm_resource_group.main: Still creating... [00m20s elapsed]
azurerm_resource_group.main: Creation complete after 23s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg]
azurerm_user_assigned_identity.app: Creating...
azurerm_virtual_network.main: Creating...
azurerm_private_dns_zone.postgres: Creating...
azurerm_key_vault.main: Creating...
azurerm_managed_redis.main: Creating...
azurerm_container_registry.main: Creating...
azurerm_virtual_network.main: Creation complete after 5s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet]
azurerm_subnet.aks: Creating...
azurerm_subnet.postgres: Creating...
azurerm_user_assigned_identity.app: Still creating... [00m10s elapsed]
azurerm_private_dns_zone.postgres: Still creating... [00m10s elapsed]
azurerm_key_vault.main: Still creating... [00m10s elapsed]
azurerm_managed_redis.main: Still creating... [00m10s elapsed]
azurerm_container_registry.main: Still creating... [00m10s elapsed]
azurerm_subnet.aks: Creation complete after 5s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-aks-subnet]
azurerm_kubernetes_cluster.main: Creating...
azurerm_subnet.postgres: Creation complete after 9s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-postgres-subnet]
azurerm_container_registry.main: Creation complete after 18s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0]
azurerm_user_assigned_identity.app: Still creating... [00m20s elapsed]
azurerm_key_vault.main: Still creating... [00m20s elapsed]
azurerm_private_dns_zone.postgres: Still creating... [00m20s elapsed]
azurerm_managed_redis.main: Still creating... [00m20s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [00m10s elapsed]
azurerm_user_assigned_identity.app: Creation complete after 28s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity]
azurerm_private_dns_zone.postgres: Still creating... [00m30s elapsed]
azurerm_key_vault.main: Still creating... [00m30s elapsed]
azurerm_managed_redis.main: Still creating... [00m30s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [00m20s elapsed]
azurerm_private_dns_zone.postgres: Creation complete after 32s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com]
azurerm_private_dns_zone_virtual_network_link.postgres: Creating...
azurerm_key_vault.main: Still creating... [00m40s elapsed]
azurerm_managed_redis.main: Still creating... [00m40s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [00m30s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still creating... [00m10s elapsed]
azurerm_key_vault.main: Still creating... [00m50s elapsed]
azurerm_managed_redis.main: Still creating... [00m50s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [00m40s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still creating... [00m20s elapsed]
azurerm_key_vault.main: Still creating... [01m00s elapsed]
azurerm_managed_redis.main: Still creating... [01m00s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [00m50s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still creating... [00m30s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Creation complete after 32s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com/virtualNetworkLinks/grid-meter-app-postgres-dns-link]
azurerm_postgresql_flexible_server.main: Creating...
azurerm_key_vault.main: Still creating... [01m10s elapsed]
azurerm_managed_redis.main: Still creating... [01m10s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [01m00s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [00m10s elapsed]
azurerm_key_vault.main: Still creating... [01m20s elapsed]
azurerm_managed_redis.main: Still creating... [01m20s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [01m10s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [00m20s elapsed]
azurerm_key_vault.main: Still creating... [01m30s elapsed]
azurerm_managed_redis.main: Still creating... [01m30s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [01m20s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [00m30s elapsed]
azurerm_key_vault.main: Still creating... [01m40s elapsed]
azurerm_managed_redis.main: Still creating... [01m40s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [01m30s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [00m40s elapsed]
azurerm_key_vault.main: Still creating... [01m50s elapsed]
azurerm_managed_redis.main: Still creating... [01m50s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [01m40s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [00m50s elapsed]
azurerm_managed_redis.main: Still creating... [02m00s elapsed]
azurerm_key_vault.main: Still creating... [02m00s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [01m50s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [01m00s elapsed]
azurerm_key_vault.main: Still creating... [02m10s elapsed]
azurerm_managed_redis.main: Still creating... [02m10s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [02m00s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [01m10s elapsed]
azurerm_key_vault.main: Still creating... [02m20s elapsed]
azurerm_managed_redis.main: Still creating... [02m20s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [02m10s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [01m20s elapsed]
azurerm_key_vault.main: Creation complete after 2m27s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv]
azurerm_role_assignment.deployer_kv_secrets: Creating...
azurerm_managed_redis.main: Still creating... [02m30s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [02m20s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [01m30s elapsed]
azurerm_role_assignment.deployer_kv_secrets: Still creating... [00m10s elapsed]
azurerm_managed_redis.main: Still creating... [02m40s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [02m30s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [01m40s elapsed]
azurerm_role_assignment.deployer_kv_secrets: Still creating... [00m20s elapsed]
azurerm_managed_redis.main: Still creating... [02m50s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [02m40s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [01m50s elapsed]
azurerm_role_assignment.deployer_kv_secrets: Creation complete after 30s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv/providers/Microsoft.Authorization/roleAssignments/84603059-1681-d148-2b5e-b5ebb956b045]
time_sleep.rbac_propagation: Creating...
azurerm_managed_redis.main: Still creating... [03m00s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [02m50s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [02m00s elapsed]
time_sleep.rbac_propagation: Still creating... [00m10s elapsed]
azurerm_managed_redis.main: Still creating... [03m10s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [03m00s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [02m10s elapsed]
time_sleep.rbac_propagation: Still creating... [00m20s elapsed]
azurerm_managed_redis.main: Still creating... [03m20s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [03m10s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [02m20s elapsed]
time_sleep.rbac_propagation: Still creating... [00m30s elapsed]
time_sleep.rbac_propagation: Creation complete after 30s [id=2026-09-24T21:44:24Z]
azurerm_key_vault_secret.postgres_password: Creating...
azurerm_key_vault_secret.postgres_password: Creation complete after 1s [id=https://grid-meter-app-kv.vault.azure.net/secrets/postgres-admin-password/bd014a7c638c4a21a49729175e0e45a8]
azurerm_managed_redis.main: Still creating... [03m30s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [03m20s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [02m30s elapsed]
azurerm_managed_redis.main: Still creating... [03m40s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [03m30s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [02m40s elapsed]
azurerm_managed_redis.main: Still creating... [03m50s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [03m40s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [02m50s elapsed]
azurerm_managed_redis.main: Still creating... [04m00s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [03m50s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [03m00s elapsed]
azurerm_managed_redis.main: Still creating... [04m10s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [04m00s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [03m10s elapsed]
azurerm_managed_redis.main: Still creating... [04m20s elapsed]
azurerm_kubernetes_cluster.main: Still creating... [04m10s elapsed]
azurerm_kubernetes_cluster.main: Creation complete after 4m10s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerService/managedClusters/grid-meter-app-aks]
azurerm_federated_identity_credential.app: Creating...
azurerm_role_assignment.aks_acr_pull: Creating...
azurerm_postgresql_flexible_server.main: Still creating... [03m20s elapsed]
azurerm_managed_redis.main: Still creating... [04m30s elapsed]
azurerm_role_assignment.aks_acr_pull: Still creating... [00m10s elapsed]
azurerm_federated_identity_credential.app: Still creating... [00m10s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [03m30s elapsed]
azurerm_managed_redis.main: Still creating... [04m40s elapsed]
azurerm_federated_identity_credential.app: Still creating... [00m20s elapsed]
azurerm_role_assignment.aks_acr_pull: Still creating... [00m20s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [03m40s elapsed]
azurerm_federated_identity_credential.app: Creation complete after 28s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity/federatedIdentityCredentials/grid-meter-app-app-fic]
azurerm_managed_redis.main: Still creating... [04m50s elapsed]
azurerm_role_assignment.aks_acr_pull: Creation complete after 30s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0/providers/Microsoft.Authorization/roleAssignments/0e6d8c48-53c6-8a37-c613-a263a97cfe7b]
azurerm_postgresql_flexible_server.main: Still creating... [03m50s elapsed]
azurerm_managed_redis.main: Still creating... [05m00s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [04m00s elapsed]
azurerm_managed_redis.main: Still creating... [05m10s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [04m10s elapsed]
azurerm_managed_redis.main: Still creating... [05m20s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [04m20s elapsed]
azurerm_managed_redis.main: Still creating... [05m30s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [04m30s elapsed]
azurerm_managed_redis.main: Still creating... [05m40s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [04m40s elapsed]
azurerm_managed_redis.main: Still creating... [05m50s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [04m50s elapsed]
azurerm_managed_redis.main: Still creating... [06m00s elapsed]
azurerm_postgresql_flexible_server.main: Still creating... [05m00s elapsed]
azurerm_managed_redis.main: Still creating... [06m10s elapsed]
azurerm_postgresql_flexible_server.main: Creation complete after 5m6s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres]
azurerm_postgresql_flexible_server_database.main: Creating...
azurerm_managed_redis.main: Still creating... [06m20s elapsed]
azurerm_postgresql_flexible_server_database.main: Still creating... [00m10s elapsed]
azurerm_postgresql_flexible_server_database.main: Creation complete after 14s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres/databases/gridmeter]
azurerm_managed_redis.main: Still creating... [06m30s elapsed]
azurerm_managed_redis.main: Still creating... [06m40s elapsed]
azurerm_managed_redis.main: Still creating... [06m50s elapsed]
azurerm_managed_redis.main: Still creating... [07m00s elapsed]
azurerm_managed_redis.main: Still creating... [07m10s elapsed]
azurerm_managed_redis.main: Still creating... [07m20s elapsed]
azurerm_managed_redis.main: Still creating... [07m30s elapsed]
azurerm_managed_redis.main: Creation complete after 7m32s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis]
azurerm_managed_redis_access_policy_assignment.app: Creating...
azurerm_managed_redis_access_policy_assignment.app: Still creating... [00m10s elapsed]
azurerm_managed_redis_access_policy_assignment.app: Creation complete after 12s [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis/databases/default/accessPolicyAssignments/8932f5b8-6174-4777-bfaa-fc47dd72e9a7]
Releasing state lock. This may take a few moments...

Apply complete! Resources: 20 added, 0 changed, 0 destroyed.

Outputs:

acr_login_server = "gridmeterapp3caa5ec0.azurecr.io"
aks_cluster_name = "grid-meter-app-aks"
app_identity_client_id = "e7d5af6c-2d03-448d-8438-a5e26896838c"
azure_region = "centralus"
key_vault_name = "grid-meter-app-kv"
kubeconfig_update_command = "az aks get-credentials --resource-group grid-meter-app-rg --name grid-meter-app-aks --overwrite-existing"
node_resource_group = "MC_grid-meter-app-rg_grid-meter-app-aks_centralus"
postgres_db_name = "gridmeter"
postgres_fqdn = "grid-meter-app-postgres.postgres.database.azure.com"
postgres_password_secret_name = "postgres-admin-password"
postgres_user = "gridmeter"
redis_hostname = "grid-meter-app-redis.centralus.redis.azure.net"
redis_port = 10000
resource_group_name = "grid-meter-app-rg"
tim@Timothys-MacBook-Air azure % 

tim@Timothys-MacBook-Air azure % terraform state list
data.azurerm_client_config.current
azurerm_container_registry.main
azurerm_federated_identity_credential.app
azurerm_key_vault.main
azurerm_key_vault_secret.postgres_password
azurerm_kubernetes_cluster.main
azurerm_managed_redis.main
azurerm_managed_redis_access_policy_assignment.app
azurerm_postgresql_flexible_server.main
azurerm_postgresql_flexible_server_database.main
azurerm_private_dns_zone.postgres
azurerm_private_dns_zone_virtual_network_link.postgres
azurerm_resource_group.main
azurerm_role_assignment.aks_acr_pull
azurerm_role_assignment.deployer_kv_secrets
azurerm_subnet.aks
azurerm_subnet.postgres
azurerm_user_assigned_identity.app
azurerm_virtual_network.main
random_password.postgres
time_sleep.rbac_propagation
tim@Timothys-MacBook-Air azure % 

tim@Timothys-MacBook-Air azure % ./check-resources-azure.sh 
== Checking Terraform-provisioned Azure resources for cluster 'grid-meter-app-aks' (resource group: grid-meter-app-rg) ==

-- Networking --
  PASS  Resource Group: Succeeded
  PASS  VNet: Succeeded
  PASS  AKS subnet: Succeeded
  PASS  Postgres delegated subnet: Succeeded
  PASS  Postgres private DNS zone: Succeeded
  PASS  Postgres private DNS VNet link: Succeeded

-- AKS --
  PASS  AKS cluster provisioning state: Succeeded
  PASS  AKS system node pool state: Succeeded
  PASS  AKS node count (expect 2): 2
  PASS  AKS workload identity enabled: true

-- Data tier --
  PASS  Postgres Flexible Server state: Ready
  PASS  Postgres version: 18
  PASS  Postgres database: gridmeter: gridmeter
  PASS  Managed Redis provisioning state: Succeeded
  PASS  Managed Redis database access policy assignment: WARNING: This command is in preview and under development. Reference and support levels: https://aka.ms/CLI_refstatus
8932f5b8-6174-4777-bfaa-fc47dd72e9a7

-- Key Vault --
  PASS  Key Vault: Succeeded
  PASS  Postgres password secret exists: https://grid-meter-app-kv.vault.azure.net/secrets/postgres-admin-password/bd014a7c638c4a21a49729175e0e45a8
  PASS  Key Vault RBAC role assignment (deployer): Key Vault Secrets Officer

-- Container Registry --
  PASS  ACR provisioning state: Succeeded
  PASS  ACR AcrPull role assignment (AKS kubelet identity): AcrPull

-- App workload identity (IAM-auth backport, 2026-09-23 - see README.md) --
  PASS  User-assigned identity: 8932f5b8-6174-4777-bfaa-fc47dd72e9a7
  PASS  Federated identity credential: grid-meter-app-app-fic

== Summary: 22 passed, 0 failed ==
All expected Terraform-provisioned resources confirmed present and healthy.
tim@Timothys-MacBook-Air azure % 

tim@Timothys-MacBook-Air grid-meter-app % cd terraform/azure 
tim@Timothys-MacBook-Air azure % terraform plan -destroy -out tfplan-destroy
Acquiring state lock. This may take a few moments...
random_password.postgres: Refreshing state... [id=none]
data.azurerm_client_config.current: Reading...
azurerm_resource_group.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg]
data.azurerm_client_config.current: Read complete after 0s [id=Y2xpZW50Q29uZmlncy9jbGllbnRJZD0wNGIwNzc5NS04ZGRiLTQ2MWEtYmJlZS0wMmY5ZTFiZjdiNDY7b2JqZWN0SWQ9Njk3MGVjMzUtYTQxNi00MTY3LThiOGQtNzU5MmM3MjY5ZGM3O3N1YnNjcmlwdGlvbklkPTNjYWE1ZWMwLTBkM2UtNGNkMC05OGVjLWE1ODRjMzQyMWE1NDt0ZW5hbnRJZD05MTczNzQ2OS00OTY1LTRkMmYtYTcyZC05YmE4YTUzMWEzNTU=]
azurerm_user_assigned_identity.app: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity]
azurerm_container_registry.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0]
azurerm_private_dns_zone.postgres: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com]
azurerm_managed_redis.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis]
azurerm_virtual_network.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet]
azurerm_key_vault.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv]
azurerm_subnet.aks: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-aks-subnet]
azurerm_subnet.postgres: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-postgres-subnet]
azurerm_kubernetes_cluster.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerService/managedClusters/grid-meter-app-aks]
azurerm_private_dns_zone_virtual_network_link.postgres: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com/virtualNetworkLinks/grid-meter-app-postgres-dns-link]
azurerm_managed_redis_access_policy_assignment.app: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis/databases/default/accessPolicyAssignments/8932f5b8-6174-4777-bfaa-fc47dd72e9a7]
azurerm_postgresql_flexible_server.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres]
azurerm_role_assignment.deployer_kv_secrets: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv/providers/Microsoft.Authorization/roleAssignments/84603059-1681-d148-2b5e-b5ebb956b045]
azurerm_postgresql_flexible_server_database.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres/databases/gridmeter]
time_sleep.rbac_propagation: Refreshing state... [id=2026-09-24T21:44:24Z]
azurerm_key_vault_secret.postgres_password: Refreshing state... [id=https://grid-meter-app-kv.vault.azure.net/secrets/postgres-admin-password/bd014a7c638c4a21a49729175e0e45a8]
azurerm_role_assignment.aks_acr_pull: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0/providers/Microsoft.Authorization/roleAssignments/0e6d8c48-53c6-8a37-c613-a263a97cfe7b]
azurerm_federated_identity_credential.app: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity/federatedIdentityCredentials/grid-meter-app-app-fic]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # azurerm_container_registry.main will be destroyed
  - resource "azurerm_container_registry" "main" {
      - admin_enabled                                = false -> null
      - anonymous_pull_enabled                       = false -> null
      - azuread_authentication_as_arm_policy_enabled = true -> null
      - data_endpoint_enabled                        = false -> null
      - data_endpoint_host_names                     = [] -> null
      - encryption                                   = [] -> null
      - export_policy_enabled                        = true -> null
      - id                                           = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0" -> null
      - location                                     = "centralus" -> null
      - login_server                                 = "gridmeterapp3caa5ec0.azurecr.io" -> null
      - name                                         = "gridmeterapp3caa5ec0" -> null
      - network_rule_bypass_for_tasks_enabled        = false -> null
      - network_rule_bypass_option                   = "AzureServices" -> null
      - network_rule_set                             = [] -> null
      - public_network_access_enabled                = true -> null
      - quarantine_policy_enabled                    = false -> null
      - resource_group_name                          = "grid-meter-app-rg" -> null
      - retention_policy_in_days                     = 0 -> null
      - role_assignment_mode                         = "LegacyRegistryPermissions" -> null
      - sku                                          = "Basic" -> null
      - tags                                         = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
      - zone_redundancy_enabled                      = false -> null
        # (2 unchanged attributes hidden)
    }

  # azurerm_federated_identity_credential.app will be destroyed
  - resource "azurerm_federated_identity_credential" "app" {
      - audience                  = [
          - "api://AzureADTokenExchange",
        ] -> null
      - id                        = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity/federatedIdentityCredentials/grid-meter-app-app-fic" -> null
      - issuer                    = "https://centralus.oic.prod-aks.azure.com/91737469-4965-4d2f-a72d-9ba8a531a355/f9ad87c0-5389-462b-854e-d705fbef1426/" -> null
      - name                      = "grid-meter-app-app-fic" -> null
      - subject                   = "system:serviceaccount:default:grid-meter-app" -> null
      - user_assigned_identity_id = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity" -> null
    }

  # azurerm_key_vault.main will be destroyed
  - resource "azurerm_key_vault" "main" {
      - access_policy                   = [] -> null
      - enabled_for_deployment          = false -> null
      - enabled_for_disk_encryption     = false -> null
      - enabled_for_template_deployment = false -> null
      - id                              = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv" -> null
      - location                        = "centralus" -> null
      - name                            = "grid-meter-app-kv" -> null
      - public_network_access_enabled   = true -> null
      - purge_protection_enabled        = false -> null
      - rbac_authorization_enabled      = true -> null
      - resource_group_name             = "grid-meter-app-rg" -> null
      - sku_name                        = "standard" -> null
      - soft_delete_retention_days      = 7 -> null
      - tags                            = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
      - tenant_id                       = "91737469-4965-4d2f-a72d-9ba8a531a355" -> null
      - vault_uri                       = "https://grid-meter-app-kv.vault.azure.net/" -> null

      - network_acls {
          - bypass                     = "AzureServices" -> null
          - default_action             = "Allow" -> null
          - ip_rules                   = [] -> null
          - virtual_network_subnet_ids = [] -> null
        }
    }

  # azurerm_key_vault_secret.postgres_password will be destroyed
  - resource "azurerm_key_vault_secret" "postgres_password" {
      - id                      = "https://grid-meter-app-kv.vault.azure.net/secrets/postgres-admin-password/bd014a7c638c4a21a49729175e0e45a8" -> null
      - key_vault_id            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv" -> null
      - name                    = "postgres-admin-password" -> null
      - resource_id             = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv/secrets/postgres-admin-password/versions/bd014a7c638c4a21a49729175e0e45a8" -> null
      - resource_versionless_id = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv/secrets/postgres-admin-password" -> null
      - tags                    = {} -> null
      - value                   = (sensitive value) -> null
      - value_wo                = (write-only attribute) -> null
      - value_wo_version        = 0 -> null
      - version                 = "bd014a7c638c4a21a49729175e0e45a8" -> null
      - versionless_id          = "https://grid-meter-app-kv.vault.azure.net/secrets/postgres-admin-password" -> null
        # (3 unchanged attributes hidden)
    }

  # azurerm_kubernetes_cluster.main will be destroyed
  - resource "azurerm_kubernetes_cluster" "main" {
      - ai_toolchain_operator_enabled       = false -> null
      - azure_policy_enabled                = false -> null
      - cost_analysis_enabled               = false -> null
      - current_kubernetes_version          = "1.35.7" -> null
      - custom_ca_trust_certificates_base64 = [] -> null
      - dns_prefix                          = "grid-meter-app" -> null
      - fqdn                                = "grid-meter-app-u6w5ryqd.hcp.centralus.azmk8s.io" -> null
      - http_application_routing_enabled    = false -> null
      - id                                  = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerService/managedClusters/grid-meter-app-aks" -> null
      - kube_admin_config                   = (sensitive value) -> null
      - kube_config                         = (sensitive value) -> null
      - kube_config_raw                     = (sensitive value) -> null
      - kubernetes_version                  = "1.35" -> null
      - local_account_disabled              = false -> null
      - location                            = "centralus" -> null
      - name                                = "grid-meter-app-aks" -> null
      - node_os_upgrade_channel             = "NodeImage" -> null
      - node_resource_group                 = "MC_grid-meter-app-rg_grid-meter-app-aks_centralus" -> null
      - node_resource_group_id              = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/MC_grid-meter-app-rg_grid-meter-app-aks_centralus" -> null
      - oidc_issuer_enabled                 = true -> null
      - oidc_issuer_url                     = "https://centralus.oic.prod-aks.azure.com/91737469-4965-4d2f-a72d-9ba8a531a355/f9ad87c0-5389-462b-854e-d705fbef1426/" -> null
      - open_service_mesh_enabled           = false -> null
      - portal_fqdn                         = "grid-meter-app-u6w5ryqd.portal.hcp.centralus.azmk8s.io" -> null
      - private_cluster_enabled             = false -> null
      - private_cluster_public_fqdn_enabled = false -> null
      - resource_group_name                 = "grid-meter-app-rg" -> null
      - role_based_access_control_enabled   = true -> null
      - run_command_enabled                 = true -> null
      - sku_tier                            = "Free" -> null
      - support_plan                        = "KubernetesOfficial" -> null
      - tags                                = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
      - workload_identity_enabled           = true -> null
        # (8 unchanged attributes hidden)

      - bootstrap_profile {
          - artifact_source       = "Direct" -> null
            # (1 unchanged attribute hidden)
        }

      - default_node_pool {
          - auto_scaling_enabled          = false -> null
          - fips_enabled                  = false -> null
          - host_encryption_enabled       = false -> null
          - kubelet_disk_type             = "OS" -> null
          - max_count                     = 0 -> null
          - max_pods                      = 250 -> null
          - min_count                     = 0 -> null
          - name                          = "system" -> null
          - node_count                    = 2 -> null
          - node_labels                   = {} -> null
          - node_public_ip_enabled        = false -> null
          - only_critical_addons_enabled  = false -> null
          - orchestrator_version          = "1.35" -> null
          - os_disk_size_gb               = 30 -> null
          - os_disk_type                  = "Managed" -> null
          - os_sku                        = "Ubuntu" -> null
          - scale_down_mode               = "Delete" -> null
          - tags                          = {} -> null
          - type                          = "VirtualMachineScaleSets" -> null
          - ultra_ssd_enabled             = false -> null
          - vm_size                       = "Standard_D2as_v7" -> null
          - vnet_subnet_id                = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-aks-subnet" -> null
          - zones                         = [] -> null
            # (10 unchanged attributes hidden)

          - upgrade_settings {
              - drain_timeout_in_minutes      = 0 -> null
              - max_surge                     = "10%" -> null
              - node_soak_duration_in_minutes = 0 -> null
                # (1 unchanged attribute hidden)
            }
        }

      - identity {
          - identity_ids = [] -> null
          - principal_id = "a31a6bc9-4cda-4fce-9349-f9cac185adc1" -> null
          - tenant_id    = "91737469-4965-4d2f-a72d-9ba8a531a355" -> null
          - type         = "SystemAssigned" -> null
        }

      - kubelet_identity {
          - client_id                 = "4f4e3033-a80a-4a66-a5f5-ca529581a0e0" -> null
          - object_id                 = "bd9d8514-2966-48e6-a07b-860cbf73bd50" -> null
          - user_assigned_identity_id = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/MC_grid-meter-app-rg_grid-meter-app-aks_centralus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-aks-agentpool" -> null
        }

      - network_profile {
          - dns_service_ip      = "10.245.0.10" -> null
          - ip_versions         = [
              - "IPv4",
            ] -> null
          - load_balancer_sku   = "standard" -> null
          - network_data_plane  = "azure" -> null
          - network_plugin      = "azure" -> null
          - network_plugin_mode = "overlay" -> null
          - network_policy      = "azure" -> null
          - outbound_type       = "loadBalancer" -> null
          - pod_cidr            = "10.244.0.0/16" -> null
          - pod_cidrs           = [
              - "10.244.0.0/16",
            ] -> null
          - service_cidr        = "10.245.0.0/16" -> null
          - service_cidrs       = [
              - "10.245.0.0/16",
            ] -> null
            # (1 unchanged attribute hidden)

          - load_balancer_profile {
              - backend_pool_type           = "NodeIPConfiguration" -> null
              - effective_outbound_ips      = [
                  - "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/MC_grid-meter-app-rg_grid-meter-app-aks_centralus/providers/Microsoft.Network/publicIPAddresses/06bd9596-211f-4130-b7e6-b1efe449bf26",
                ] -> null
              - idle_timeout_in_minutes     = 0 -> null
              - managed_outbound_ip_count   = 1 -> null
              - managed_outbound_ipv6_count = 0 -> null
              - outbound_ip_address_ids     = [] -> null
              - outbound_ip_prefix_ids      = [] -> null
              - outbound_ports_allocated    = 0 -> null
            }
        }

      - node_provisioning_profile {
          - default_node_pools = "Auto" -> null
          - mode               = "Manual" -> null
        }

      - windows_profile {
          - admin_username = "azureuser" -> null
            # (2 unchanged attributes hidden)
        }
    }

  # azurerm_managed_redis.main will be destroyed
  - resource "azurerm_managed_redis" "main" {
      - high_availability_enabled = false -> null
      - hostname                  = "grid-meter-app-redis.centralus.redis.azure.net" -> null
      - id                        = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis" -> null
      - location                  = "centralus" -> null
      - name                      = "grid-meter-app-redis" -> null
      - public_network_access     = "Enabled" -> null
      - resource_group_name       = "grid-meter-app-rg" -> null
      - sku_name                  = "Balanced_B0" -> null
      - tags                      = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null

      - default_database {
          - access_keys_authentication_enabled            = false -> null
          - client_protocol                               = "Encrypted" -> null
          - clustering_policy                             = "OSSCluster" -> null
          - eviction_policy                               = "VolatileLRU" -> null
          - id                                            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis/databases/default" -> null
          - port                                          = 10000 -> null
            # (5 unchanged attributes hidden)
        }
    }

  # azurerm_managed_redis_access_policy_assignment.app will be destroyed
  - resource "azurerm_managed_redis_access_policy_assignment" "app" {
      - id               = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis/databases/default/accessPolicyAssignments/8932f5b8-6174-4777-bfaa-fc47dd72e9a7" -> null
      - managed_redis_id = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis" -> null
      - object_id        = "8932f5b8-6174-4777-bfaa-fc47dd72e9a7" -> null
    }

  # azurerm_postgresql_flexible_server.main will be destroyed
  - resource "azurerm_postgresql_flexible_server" "main" {
      - administrator_login               = "gridmeter" -> null
      - administrator_password            = (sensitive value) -> null
      - administrator_password_wo         = (write-only attribute) -> null
      - administrator_password_wo_version = 0 -> null
      - auto_grow_enabled                 = false -> null
      - backup_retention_days             = 7 -> null
      - delegated_subnet_id               = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-postgres-subnet" -> null
      - fqdn                              = "grid-meter-app-postgres.postgres.database.azure.com" -> null
      - geo_redundant_backup_enabled      = false -> null
      - id                                = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres" -> null
      - location                          = "centralus" -> null
      - name                              = "grid-meter-app-postgres" -> null
      - private_dns_zone_id               = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com" -> null
      - public_network_access_enabled     = false -> null
      - resource_group_name               = "grid-meter-app-rg" -> null
      - sku_name                          = "B_Standard_B1ms" -> null
      - storage_iops                      = 120 -> null
      - storage_mb                        = 32768 -> null
      - storage_tier                      = "P4" -> null
      - storage_type                      = "Premium_LRS" -> null
      - tags                              = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
      - version                           = "18" -> null
      - zone                              = "1" -> null
        # (3 unchanged attributes hidden)

      - authentication {
          - active_directory_auth_enabled = false -> null
          - password_auth_enabled         = true -> null
            # (1 unchanged attribute hidden)
        }
    }

  # azurerm_postgresql_flexible_server_database.main will be destroyed
  - resource "azurerm_postgresql_flexible_server_database" "main" {
      - charset   = "UTF8" -> null
      - collation = "en_US.utf8" -> null
      - id        = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres/databases/gridmeter" -> null
      - name      = "gridmeter" -> null
      - server_id = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres" -> null
    }

  # azurerm_private_dns_zone.postgres will be destroyed
  - resource "azurerm_private_dns_zone" "postgres" {
      - id                                                    = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com" -> null
      - max_number_of_record_sets                             = 25000 -> null
      - max_number_of_virtual_network_links                   = 1000 -> null
      - max_number_of_virtual_network_links_with_registration = 100 -> null
      - name                                                  = "grid-meter-app.postgres.database.azure.com" -> null
      - number_of_record_sets                                 = 2 -> null
      - resource_group_name                                   = "grid-meter-app-rg" -> null
      - tags                                                  = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null

      - soa_record {
          - email         = "azureprivatedns-host.microsoft.com" -> null
          - expire_time   = 2419200 -> null
          - fqdn          = "grid-meter-app.postgres.database.azure.com." -> null
          - host_name     = "azureprivatedns.net" -> null
          - minimum_ttl   = 10 -> null
          - refresh_time  = 3600 -> null
          - retry_time    = 300 -> null
          - serial_number = 1 -> null
          - tags          = {} -> null
          - ttl           = 3600 -> null
        }
    }

  # azurerm_private_dns_zone_virtual_network_link.postgres will be destroyed
  - resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
      - id                   = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com/virtualNetworkLinks/grid-meter-app-postgres-dns-link" -> null
      - name                 = "grid-meter-app-postgres-dns-link" -> null
      - private_dns_zone_id  = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com" -> null
      - registration_enabled = false -> null
      - tags                 = {} -> null
      - virtual_network_id   = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet" -> null
        # (1 unchanged attribute hidden)
    }

  # azurerm_resource_group.main will be destroyed
  - resource "azurerm_resource_group" "main" {
      - id         = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg" -> null
      - location   = "centralus" -> null
      - name       = "grid-meter-app-rg" -> null
      - tags       = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
        # (1 unchanged attribute hidden)
    }

  # azurerm_role_assignment.aks_acr_pull will be destroyed
  - resource "azurerm_role_assignment" "aks_acr_pull" {
      - id                                     = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0/providers/Microsoft.Authorization/roleAssignments/0e6d8c48-53c6-8a37-c613-a263a97cfe7b" -> null
      - name                                   = "0e6d8c48-53c6-8a37-c613-a263a97cfe7b" -> null
      - principal_id                           = "bd9d8514-2966-48e6-a07b-860cbf73bd50" -> null
      - principal_type                         = "ServicePrincipal" -> null
      - role_definition_id                     = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d" -> null
      - role_definition_name                   = "AcrPull" -> null
      - scope                                  = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0" -> null
        # (4 unchanged attributes hidden)
    }

  # azurerm_role_assignment.deployer_kv_secrets will be destroyed
  - resource "azurerm_role_assignment" "deployer_kv_secrets" {
      - id                                     = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv/providers/Microsoft.Authorization/roleAssignments/84603059-1681-d148-2b5e-b5ebb956b045" -> null
      - name                                   = "84603059-1681-d148-2b5e-b5ebb956b045" -> null
      - principal_id                           = "6970ec35-a416-4167-8b8d-7592c7269dc7" -> null
      - principal_type                         = "User" -> null
      - role_definition_id                     = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/providers/Microsoft.Authorization/roleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7" -> null
      - role_definition_name                   = "Key Vault Secrets Officer" -> null
      - scope                                  = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv" -> null
        # (4 unchanged attributes hidden)
    }

  # azurerm_subnet.aks will be destroyed
  - resource "azurerm_subnet" "aks" {
      - address_prefixes                              = [
          - "10.20.0.0/24",
        ] -> null
      - default_outbound_access_enabled               = true -> null
      - id                                            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-aks-subnet" -> null
      - name                                          = "grid-meter-app-aks-subnet" -> null
      - network_security_group_id_wo                  = (write-only attribute) -> null
      - network_security_group_id_wo_version          = 0 -> null
      - private_endpoint_network_policies             = "Disabled" -> null
      - private_link_service_network_policies_enabled = true -> null
      - resource_group_name                           = "grid-meter-app-rg" -> null
      - route_table_id_wo                             = (write-only attribute) -> null
      - route_table_id_wo_version                     = 0 -> null
      - service_endpoint_policy_ids                   = [] -> null
      - virtual_network_name                          = "grid-meter-app-vnet" -> null
        # (3 unchanged attributes hidden)
    }

  # azurerm_subnet.postgres will be destroyed
  - resource "azurerm_subnet" "postgres" {
      - address_prefixes                              = [
          - "10.20.1.0/24",
        ] -> null
      - default_outbound_access_enabled               = true -> null
      - id                                            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-postgres-subnet" -> null
      - name                                          = "grid-meter-app-postgres-subnet" -> null
      - network_security_group_id_wo                  = (write-only attribute) -> null
      - network_security_group_id_wo_version          = 0 -> null
      - private_endpoint_network_policies             = "Disabled" -> null
      - private_link_service_network_policies_enabled = true -> null
      - resource_group_name                           = "grid-meter-app-rg" -> null
      - route_table_id_wo                             = (write-only attribute) -> null
      - route_table_id_wo_version                     = 0 -> null
      - service_endpoint_policy_ids                   = [] -> null
      - virtual_network_name                          = "grid-meter-app-vnet" -> null
        # (3 unchanged attributes hidden)

      - delegation {
          - name = "postgres-flexible-server-delegation" -> null

          - service_delegation {
              - actions = [
                  - "Microsoft.Network/virtualNetworks/subnets/join/action",
                ] -> null
              - name    = "Microsoft.DBforPostgreSQL/flexibleServers" -> null
            }
        }

      - service_endpoint {
          - service            = "Microsoft.Storage" -> null
            # (1 unchanged attribute hidden)
        }
    }

  # azurerm_user_assigned_identity.app will be destroyed
  - resource "azurerm_user_assigned_identity" "app" {
      - client_id           = "e7d5af6c-2d03-448d-8438-a5e26896838c" -> null
      - id                  = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity" -> null
      - location            = "centralus" -> null
      - name                = "grid-meter-app-app-identity" -> null
      - principal_id        = "8932f5b8-6174-4777-bfaa-fc47dd72e9a7" -> null
      - resource_group_name = "grid-meter-app-rg" -> null
      - tags                = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
      - tenant_id           = "91737469-4965-4d2f-a72d-9ba8a531a355" -> null
        # (1 unchanged attribute hidden)
    }

  # azurerm_virtual_network.main will be destroyed
  - resource "azurerm_virtual_network" "main" {
      - address_space                  = [
          - "10.20.0.0/16",
        ] -> null
      - dns_servers                    = [] -> null
      - flow_timeout_in_minutes        = 0 -> null
      - guid                           = "6b252056-f759-4f15-93e3-0de9be445958" -> null
      - id                             = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet" -> null
      - location                       = "centralus" -> null
      - name                           = "grid-meter-app-vnet" -> null
      - private_endpoint_vnet_policies = "Disabled" -> null
      - resource_group_name            = "grid-meter-app-rg" -> null
      - subnet                         = [
          - {
              - address_prefixes                              = [
                  - "10.20.0.0/24",
                ]
              - default_outbound_access_enabled               = true
              - delegation                                    = []
              - id                                            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-aks-subnet"
              - name                                          = "grid-meter-app-aks-subnet"
              - private_endpoint_network_policies             = "Disabled"
              - private_link_service_network_policies_enabled = true
              - service_endpoint                              = []
              - service_endpoint_policy_ids                   = []
                # (2 unchanged attributes hidden)
            },
          - {
              - address_prefixes                              = [
                  - "10.20.1.0/24",
                ]
              - default_outbound_access_enabled               = true
              - delegation                                    = [
                  - {
                      - name               = "postgres-flexible-server-delegation"
                      - service_delegation = [
                          - {
                              - actions = [
                                  - "Microsoft.Network/virtualNetworks/subnets/join/action",
                                ]
                              - name    = "Microsoft.DBforPostgreSQL/flexibleServers"
                            },
                        ]
                    },
                ]
              - id                                            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-postgres-subnet"
              - name                                          = "grid-meter-app-postgres-subnet"
              - private_endpoint_network_policies             = "Disabled"
              - private_link_service_network_policies_enabled = true
              - service_endpoint                              = [
                  - {
                      - service            = "Microsoft.Storage"
                        # (1 unchanged attribute hidden)
                    },
                ]
              - service_endpoint_policy_ids                   = []
                # (2 unchanged attributes hidden)
            },
        ] -> null
      - tags                           = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
        # (2 unchanged attributes hidden)
    }

  # random_password.postgres will be destroyed
  - resource "random_password" "postgres" {
      - bcrypt_hash = (sensitive value) -> null
      - id          = "none" -> null
      - length      = 32 -> null
      - lower       = true -> null
      - min_lower   = 0 -> null
      - min_numeric = 0 -> null
      - min_special = 0 -> null
      - min_upper   = 0 -> null
      - number      = true -> null
      - numeric     = true -> null
      - result      = (sensitive value) -> null
      - special     = false -> null
      - upper       = true -> null
    }

  # time_sleep.rbac_propagation will be destroyed
  - resource "time_sleep" "rbac_propagation" {
      - create_duration = "30s" -> null
      - id              = "2026-09-24T21:44:24Z" -> null
    }

Plan: 0 to add, 0 to change, 20 to destroy.

Changes to Outputs:
  - acr_login_server              = "gridmeterapp3caa5ec0.azurecr.io" -> null
  - aks_cluster_name              = "grid-meter-app-aks" -> null
  - app_identity_client_id        = "e7d5af6c-2d03-448d-8438-a5e26896838c" -> null
  - azure_region                  = "centralus" -> null
  - key_vault_name                = "grid-meter-app-kv" -> null
  - kubeconfig_update_command     = "az aks get-credentials --resource-group grid-meter-app-rg --name grid-meter-app-aks --overwrite-existing" -> null
  - node_resource_group           = "MC_grid-meter-app-rg_grid-meter-app-aks_centralus" -> null
  - postgres_db_name              = "gridmeter" -> null
  - postgres_fqdn                 = "grid-meter-app-postgres.postgres.database.azure.com" -> null
  - postgres_password_secret_name = "postgres-admin-password" -> null
  - postgres_user                 = "gridmeter" -> null
  - redis_hostname                = "grid-meter-app-redis.centralus.redis.azure.net" -> null
  - redis_port                    = 10000 -> null
  - resource_group_name           = "grid-meter-app-rg" -> null

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan-destroy

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan-destroy"
Releasing state lock. This may take a few moments...
tim@Timothys-MacBook-Air azure % terraform destroy
Acquiring state lock. This may take a few moments...
random_password.postgres: Refreshing state... [id=none]
data.azurerm_client_config.current: Reading...
azurerm_resource_group.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg]
data.azurerm_client_config.current: Read complete after 0s [id=Y2xpZW50Q29uZmlncy9jbGllbnRJZD0wNGIwNzc5NS04ZGRiLTQ2MWEtYmJlZS0wMmY5ZTFiZjdiNDY7b2JqZWN0SWQ9Njk3MGVjMzUtYTQxNi00MTY3LThiOGQtNzU5MmM3MjY5ZGM3O3N1YnNjcmlwdGlvbklkPTNjYWE1ZWMwLTBkM2UtNGNkMC05OGVjLWE1ODRjMzQyMWE1NDt0ZW5hbnRJZD05MTczNzQ2OS00OTY1LTRkMmYtYTcyZC05YmE4YTUzMWEzNTU=]
azurerm_user_assigned_identity.app: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity]
azurerm_container_registry.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0]
azurerm_managed_redis.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis]
azurerm_virtual_network.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet]
azurerm_private_dns_zone.postgres: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com]
azurerm_key_vault.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv]
azurerm_subnet.aks: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-aks-subnet]
azurerm_subnet.postgres: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-postgres-subnet]
azurerm_kubernetes_cluster.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerService/managedClusters/grid-meter-app-aks]
azurerm_private_dns_zone_virtual_network_link.postgres: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com/virtualNetworkLinks/grid-meter-app-postgres-dns-link]
azurerm_postgresql_flexible_server.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres]
azurerm_role_assignment.deployer_kv_secrets: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv/providers/Microsoft.Authorization/roleAssignments/84603059-1681-d148-2b5e-b5ebb956b045]
azurerm_postgresql_flexible_server_database.main: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres/databases/gridmeter]
time_sleep.rbac_propagation: Refreshing state... [id=2026-09-24T21:44:24Z]
azurerm_key_vault_secret.postgres_password: Refreshing state... [id=https://grid-meter-app-kv.vault.azure.net/secrets/postgres-admin-password/bd014a7c638c4a21a49729175e0e45a8]
azurerm_role_assignment.aks_acr_pull: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0/providers/Microsoft.Authorization/roleAssignments/0e6d8c48-53c6-8a37-c613-a263a97cfe7b]
azurerm_managed_redis_access_policy_assignment.app: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis/databases/default/accessPolicyAssignments/8932f5b8-6174-4777-bfaa-fc47dd72e9a7]
azurerm_federated_identity_credential.app: Refreshing state... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity/federatedIdentityCredentials/grid-meter-app-app-fic]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # azurerm_container_registry.main will be destroyed
  - resource "azurerm_container_registry" "main" {
      - admin_enabled                                = false -> null
      - anonymous_pull_enabled                       = false -> null
      - azuread_authentication_as_arm_policy_enabled = true -> null
      - data_endpoint_enabled                        = false -> null
      - data_endpoint_host_names                     = [] -> null
      - encryption                                   = [] -> null
      - export_policy_enabled                        = true -> null
      - id                                           = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0" -> null
      - location                                     = "centralus" -> null
      - login_server                                 = "gridmeterapp3caa5ec0.azurecr.io" -> null
      - name                                         = "gridmeterapp3caa5ec0" -> null
      - network_rule_bypass_for_tasks_enabled        = false -> null
      - network_rule_bypass_option                   = "AzureServices" -> null
      - network_rule_set                             = [] -> null
      - public_network_access_enabled                = true -> null
      - quarantine_policy_enabled                    = false -> null
      - resource_group_name                          = "grid-meter-app-rg" -> null
      - retention_policy_in_days                     = 0 -> null
      - role_assignment_mode                         = "LegacyRegistryPermissions" -> null
      - sku                                          = "Basic" -> null
      - tags                                         = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
      - zone_redundancy_enabled                      = false -> null
        # (2 unchanged attributes hidden)
    }

  # azurerm_federated_identity_credential.app will be destroyed
  - resource "azurerm_federated_identity_credential" "app" {
      - audience                  = [
          - "api://AzureADTokenExchange",
        ] -> null
      - id                        = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity/federatedIdentityCredentials/grid-meter-app-app-fic" -> null
      - issuer                    = "https://centralus.oic.prod-aks.azure.com/91737469-4965-4d2f-a72d-9ba8a531a355/f9ad87c0-5389-462b-854e-d705fbef1426/" -> null
      - name                      = "grid-meter-app-app-fic" -> null
      - subject                   = "system:serviceaccount:default:grid-meter-app" -> null
      - user_assigned_identity_id = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity" -> null
    }

  # azurerm_key_vault.main will be destroyed
  - resource "azurerm_key_vault" "main" {
      - access_policy                   = [] -> null
      - enabled_for_deployment          = false -> null
      - enabled_for_disk_encryption     = false -> null
      - enabled_for_template_deployment = false -> null
      - id                              = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv" -> null
      - location                        = "centralus" -> null
      - name                            = "grid-meter-app-kv" -> null
      - public_network_access_enabled   = true -> null
      - purge_protection_enabled        = false -> null
      - rbac_authorization_enabled      = true -> null
      - resource_group_name             = "grid-meter-app-rg" -> null
      - sku_name                        = "standard" -> null
      - soft_delete_retention_days      = 7 -> null
      - tags                            = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
      - tenant_id                       = "91737469-4965-4d2f-a72d-9ba8a531a355" -> null
      - vault_uri                       = "https://grid-meter-app-kv.vault.azure.net/" -> null

      - network_acls {
          - bypass                     = "AzureServices" -> null
          - default_action             = "Allow" -> null
          - ip_rules                   = [] -> null
          - virtual_network_subnet_ids = [] -> null
        }
    }

  # azurerm_key_vault_secret.postgres_password will be destroyed
  - resource "azurerm_key_vault_secret" "postgres_password" {
      - id                      = "https://grid-meter-app-kv.vault.azure.net/secrets/postgres-admin-password/bd014a7c638c4a21a49729175e0e45a8" -> null
      - key_vault_id            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv" -> null
      - name                    = "postgres-admin-password" -> null
      - resource_id             = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv/secrets/postgres-admin-password/versions/bd014a7c638c4a21a49729175e0e45a8" -> null
      - resource_versionless_id = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv/secrets/postgres-admin-password" -> null
      - tags                    = {} -> null
      - value                   = (sensitive value) -> null
      - value_wo                = (write-only attribute) -> null
      - value_wo_version        = 0 -> null
      - version                 = "bd014a7c638c4a21a49729175e0e45a8" -> null
      - versionless_id          = "https://grid-meter-app-kv.vault.azure.net/secrets/postgres-admin-password" -> null
        # (3 unchanged attributes hidden)
    }

  # azurerm_kubernetes_cluster.main will be destroyed
  - resource "azurerm_kubernetes_cluster" "main" {
      - ai_toolchain_operator_enabled       = false -> null
      - azure_policy_enabled                = false -> null
      - cost_analysis_enabled               = false -> null
      - current_kubernetes_version          = "1.35.7" -> null
      - custom_ca_trust_certificates_base64 = [] -> null
      - dns_prefix                          = "grid-meter-app" -> null
      - fqdn                                = "grid-meter-app-u6w5ryqd.hcp.centralus.azmk8s.io" -> null
      - http_application_routing_enabled    = false -> null
      - id                                  = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerService/managedClusters/grid-meter-app-aks" -> null
      - kube_admin_config                   = (sensitive value) -> null
      - kube_config                         = (sensitive value) -> null
      - kube_config_raw                     = (sensitive value) -> null
      - kubernetes_version                  = "1.35" -> null
      - local_account_disabled              = false -> null
      - location                            = "centralus" -> null
      - name                                = "grid-meter-app-aks" -> null
      - node_os_upgrade_channel             = "NodeImage" -> null
      - node_resource_group                 = "MC_grid-meter-app-rg_grid-meter-app-aks_centralus" -> null
      - node_resource_group_id              = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/MC_grid-meter-app-rg_grid-meter-app-aks_centralus" -> null
      - oidc_issuer_enabled                 = true -> null
      - oidc_issuer_url                     = "https://centralus.oic.prod-aks.azure.com/91737469-4965-4d2f-a72d-9ba8a531a355/f9ad87c0-5389-462b-854e-d705fbef1426/" -> null
      - open_service_mesh_enabled           = false -> null
      - portal_fqdn                         = "grid-meter-app-u6w5ryqd.portal.hcp.centralus.azmk8s.io" -> null
      - private_cluster_enabled             = false -> null
      - private_cluster_public_fqdn_enabled = false -> null
      - resource_group_name                 = "grid-meter-app-rg" -> null
      - role_based_access_control_enabled   = true -> null
      - run_command_enabled                 = true -> null
      - sku_tier                            = "Free" -> null
      - support_plan                        = "KubernetesOfficial" -> null
      - tags                                = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
      - workload_identity_enabled           = true -> null
        # (8 unchanged attributes hidden)

      - bootstrap_profile {
          - artifact_source       = "Direct" -> null
            # (1 unchanged attribute hidden)
        }

      - default_node_pool {
          - auto_scaling_enabled          = false -> null
          - fips_enabled                  = false -> null
          - host_encryption_enabled       = false -> null
          - kubelet_disk_type             = "OS" -> null
          - max_count                     = 0 -> null
          - max_pods                      = 250 -> null
          - min_count                     = 0 -> null
          - name                          = "system" -> null
          - node_count                    = 2 -> null
          - node_labels                   = {} -> null
          - node_public_ip_enabled        = false -> null
          - only_critical_addons_enabled  = false -> null
          - orchestrator_version          = "1.35" -> null
          - os_disk_size_gb               = 30 -> null
          - os_disk_type                  = "Managed" -> null
          - os_sku                        = "Ubuntu" -> null
          - scale_down_mode               = "Delete" -> null
          - tags                          = {} -> null
          - type                          = "VirtualMachineScaleSets" -> null
          - ultra_ssd_enabled             = false -> null
          - vm_size                       = "Standard_D2as_v7" -> null
          - vnet_subnet_id                = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-aks-subnet" -> null
          - zones                         = [] -> null
            # (10 unchanged attributes hidden)

          - upgrade_settings {
              - drain_timeout_in_minutes      = 0 -> null
              - max_surge                     = "10%" -> null
              - node_soak_duration_in_minutes = 0 -> null
                # (1 unchanged attribute hidden)
            }
        }

      - identity {
          - identity_ids = [] -> null
          - principal_id = "a31a6bc9-4cda-4fce-9349-f9cac185adc1" -> null
          - tenant_id    = "91737469-4965-4d2f-a72d-9ba8a531a355" -> null
          - type         = "SystemAssigned" -> null
        }

      - kubelet_identity {
          - client_id                 = "4f4e3033-a80a-4a66-a5f5-ca529581a0e0" -> null
          - object_id                 = "bd9d8514-2966-48e6-a07b-860cbf73bd50" -> null
          - user_assigned_identity_id = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/MC_grid-meter-app-rg_grid-meter-app-aks_centralus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-aks-agentpool" -> null
        }

      - network_profile {
          - dns_service_ip      = "10.245.0.10" -> null
          - ip_versions         = [
              - "IPv4",
            ] -> null
          - load_balancer_sku   = "standard" -> null
          - network_data_plane  = "azure" -> null
          - network_plugin      = "azure" -> null
          - network_plugin_mode = "overlay" -> null
          - network_policy      = "azure" -> null
          - outbound_type       = "loadBalancer" -> null
          - pod_cidr            = "10.244.0.0/16" -> null
          - pod_cidrs           = [
              - "10.244.0.0/16",
            ] -> null
          - service_cidr        = "10.245.0.0/16" -> null
          - service_cidrs       = [
              - "10.245.0.0/16",
            ] -> null
            # (1 unchanged attribute hidden)

          - load_balancer_profile {
              - backend_pool_type           = "NodeIPConfiguration" -> null
              - effective_outbound_ips      = [
                  - "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/MC_grid-meter-app-rg_grid-meter-app-aks_centralus/providers/Microsoft.Network/publicIPAddresses/06bd9596-211f-4130-b7e6-b1efe449bf26",
                ] -> null
              - idle_timeout_in_minutes     = 0 -> null
              - managed_outbound_ip_count   = 1 -> null
              - managed_outbound_ipv6_count = 0 -> null
              - outbound_ip_address_ids     = [] -> null
              - outbound_ip_prefix_ids      = [] -> null
              - outbound_ports_allocated    = 0 -> null
            }
        }

      - node_provisioning_profile {
          - default_node_pools = "Auto" -> null
          - mode               = "Manual" -> null
        }

      - windows_profile {
          - admin_username = "azureuser" -> null
            # (2 unchanged attributes hidden)
        }
    }

  # azurerm_managed_redis.main will be destroyed
  - resource "azurerm_managed_redis" "main" {
      - high_availability_enabled = false -> null
      - hostname                  = "grid-meter-app-redis.centralus.redis.azure.net" -> null
      - id                        = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis" -> null
      - location                  = "centralus" -> null
      - name                      = "grid-meter-app-redis" -> null
      - public_network_access     = "Enabled" -> null
      - resource_group_name       = "grid-meter-app-rg" -> null
      - sku_name                  = "Balanced_B0" -> null
      - tags                      = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null

      - default_database {
          - access_keys_authentication_enabled            = false -> null
          - client_protocol                               = "Encrypted" -> null
          - clustering_policy                             = "OSSCluster" -> null
          - eviction_policy                               = "VolatileLRU" -> null
          - id                                            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis/databases/default" -> null
          - port                                          = 10000 -> null
            # (5 unchanged attributes hidden)
        }
    }

  # azurerm_managed_redis_access_policy_assignment.app will be destroyed
  - resource "azurerm_managed_redis_access_policy_assignment" "app" {
      - id               = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis/databases/default/accessPolicyAssignments/8932f5b8-6174-4777-bfaa-fc47dd72e9a7" -> null
      - managed_redis_id = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis" -> null
      - object_id        = "8932f5b8-6174-4777-bfaa-fc47dd72e9a7" -> null
    }

  # azurerm_postgresql_flexible_server.main will be destroyed
  - resource "azurerm_postgresql_flexible_server" "main" {
      - administrator_login               = "gridmeter" -> null
      - administrator_password            = (sensitive value) -> null
      - administrator_password_wo         = (write-only attribute) -> null
      - administrator_password_wo_version = 0 -> null
      - auto_grow_enabled                 = false -> null
      - backup_retention_days             = 7 -> null
      - delegated_subnet_id               = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-postgres-subnet" -> null
      - fqdn                              = "grid-meter-app-postgres.postgres.database.azure.com" -> null
      - geo_redundant_backup_enabled      = false -> null
      - id                                = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres" -> null
      - location                          = "centralus" -> null
      - name                              = "grid-meter-app-postgres" -> null
      - private_dns_zone_id               = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com" -> null
      - public_network_access_enabled     = false -> null
      - resource_group_name               = "grid-meter-app-rg" -> null
      - sku_name                          = "B_Standard_B1ms" -> null
      - storage_iops                      = 120 -> null
      - storage_mb                        = 32768 -> null
      - storage_tier                      = "P4" -> null
      - storage_type                      = "Premium_LRS" -> null
      - tags                              = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
      - version                           = "18" -> null
      - zone                              = "1" -> null
        # (3 unchanged attributes hidden)

      - authentication {
          - active_directory_auth_enabled = false -> null
          - password_auth_enabled         = true -> null
            # (1 unchanged attribute hidden)
        }
    }

  # azurerm_postgresql_flexible_server_database.main will be destroyed
  - resource "azurerm_postgresql_flexible_server_database" "main" {
      - charset   = "UTF8" -> null
      - collation = "en_US.utf8" -> null
      - id        = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres/databases/gridmeter" -> null
      - name      = "gridmeter" -> null
      - server_id = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres" -> null
    }

  # azurerm_private_dns_zone.postgres will be destroyed
  - resource "azurerm_private_dns_zone" "postgres" {
      - id                                                    = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com" -> null
      - max_number_of_record_sets                             = 25000 -> null
      - max_number_of_virtual_network_links                   = 1000 -> null
      - max_number_of_virtual_network_links_with_registration = 100 -> null
      - name                                                  = "grid-meter-app.postgres.database.azure.com" -> null
      - number_of_record_sets                                 = 2 -> null
      - resource_group_name                                   = "grid-meter-app-rg" -> null
      - tags                                                  = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null

      - soa_record {
          - email         = "azureprivatedns-host.microsoft.com" -> null
          - expire_time   = 2419200 -> null
          - fqdn          = "grid-meter-app.postgres.database.azure.com." -> null
          - host_name     = "azureprivatedns.net" -> null
          - minimum_ttl   = 10 -> null
          - refresh_time  = 3600 -> null
          - retry_time    = 300 -> null
          - serial_number = 1 -> null
          - tags          = {} -> null
          - ttl           = 3600 -> null
        }
    }

  # azurerm_private_dns_zone_virtual_network_link.postgres will be destroyed
  - resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
      - id                   = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com/virtualNetworkLinks/grid-meter-app-postgres-dns-link" -> null
      - name                 = "grid-meter-app-postgres-dns-link" -> null
      - private_dns_zone_id  = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com" -> null
      - registration_enabled = false -> null
      - tags                 = {} -> null
      - virtual_network_id   = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet" -> null
        # (1 unchanged attribute hidden)
    }

  # azurerm_resource_group.main will be destroyed
  - resource "azurerm_resource_group" "main" {
      - id         = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg" -> null
      - location   = "centralus" -> null
      - name       = "grid-meter-app-rg" -> null
      - tags       = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
        # (1 unchanged attribute hidden)
    }

  # azurerm_role_assignment.aks_acr_pull will be destroyed
  - resource "azurerm_role_assignment" "aks_acr_pull" {
      - id                                     = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0/providers/Microsoft.Authorization/roleAssignments/0e6d8c48-53c6-8a37-c613-a263a97cfe7b" -> null
      - name                                   = "0e6d8c48-53c6-8a37-c613-a263a97cfe7b" -> null
      - principal_id                           = "bd9d8514-2966-48e6-a07b-860cbf73bd50" -> null
      - principal_type                         = "ServicePrincipal" -> null
      - role_definition_id                     = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d" -> null
      - role_definition_name                   = "AcrPull" -> null
      - scope                                  = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0" -> null
        # (4 unchanged attributes hidden)
    }

  # azurerm_role_assignment.deployer_kv_secrets will be destroyed
  - resource "azurerm_role_assignment" "deployer_kv_secrets" {
      - id                                     = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv/providers/Microsoft.Authorization/roleAssignments/84603059-1681-d148-2b5e-b5ebb956b045" -> null
      - name                                   = "84603059-1681-d148-2b5e-b5ebb956b045" -> null
      - principal_id                           = "6970ec35-a416-4167-8b8d-7592c7269dc7" -> null
      - principal_type                         = "User" -> null
      - role_definition_id                     = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/providers/Microsoft.Authorization/roleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7" -> null
      - role_definition_name                   = "Key Vault Secrets Officer" -> null
      - scope                                  = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv" -> null
        # (4 unchanged attributes hidden)
    }

  # azurerm_subnet.aks will be destroyed
  - resource "azurerm_subnet" "aks" {
      - address_prefixes                              = [
          - "10.20.0.0/24",
        ] -> null
      - default_outbound_access_enabled               = true -> null
      - id                                            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-aks-subnet" -> null
      - name                                          = "grid-meter-app-aks-subnet" -> null
      - network_security_group_id_wo                  = (write-only attribute) -> null
      - network_security_group_id_wo_version          = 0 -> null
      - private_endpoint_network_policies             = "Disabled" -> null
      - private_link_service_network_policies_enabled = true -> null
      - resource_group_name                           = "grid-meter-app-rg" -> null
      - route_table_id_wo                             = (write-only attribute) -> null
      - route_table_id_wo_version                     = 0 -> null
      - service_endpoint_policy_ids                   = [] -> null
      - virtual_network_name                          = "grid-meter-app-vnet" -> null
        # (3 unchanged attributes hidden)
    }

  # azurerm_subnet.postgres will be destroyed
  - resource "azurerm_subnet" "postgres" {
      - address_prefixes                              = [
          - "10.20.1.0/24",
        ] -> null
      - default_outbound_access_enabled               = true -> null
      - id                                            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-postgres-subnet" -> null
      - name                                          = "grid-meter-app-postgres-subnet" -> null
      - network_security_group_id_wo                  = (write-only attribute) -> null
      - network_security_group_id_wo_version          = 0 -> null
      - private_endpoint_network_policies             = "Disabled" -> null
      - private_link_service_network_policies_enabled = true -> null
      - resource_group_name                           = "grid-meter-app-rg" -> null
      - route_table_id_wo                             = (write-only attribute) -> null
      - route_table_id_wo_version                     = 0 -> null
      - service_endpoint_policy_ids                   = [] -> null
      - virtual_network_name                          = "grid-meter-app-vnet" -> null
        # (3 unchanged attributes hidden)

      - delegation {
          - name = "postgres-flexible-server-delegation" -> null

          - service_delegation {
              - actions = [
                  - "Microsoft.Network/virtualNetworks/subnets/join/action",
                ] -> null
              - name    = "Microsoft.DBforPostgreSQL/flexibleServers" -> null
            }
        }

      - service_endpoint {
          - service            = "Microsoft.Storage" -> null
            # (1 unchanged attribute hidden)
        }
    }

  # azurerm_user_assigned_identity.app will be destroyed
  - resource "azurerm_user_assigned_identity" "app" {
      - client_id           = "e7d5af6c-2d03-448d-8438-a5e26896838c" -> null
      - id                  = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity" -> null
      - location            = "centralus" -> null
      - name                = "grid-meter-app-app-identity" -> null
      - principal_id        = "8932f5b8-6174-4777-bfaa-fc47dd72e9a7" -> null
      - resource_group_name = "grid-meter-app-rg" -> null
      - tags                = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
      - tenant_id           = "91737469-4965-4d2f-a72d-9ba8a531a355" -> null
        # (1 unchanged attribute hidden)
    }

  # azurerm_virtual_network.main will be destroyed
  - resource "azurerm_virtual_network" "main" {
      - address_space                  = [
          - "10.20.0.0/16",
        ] -> null
      - dns_servers                    = [] -> null
      - flow_timeout_in_minutes        = 0 -> null
      - guid                           = "6b252056-f759-4f15-93e3-0de9be445958" -> null
      - id                             = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet" -> null
      - location                       = "centralus" -> null
      - name                           = "grid-meter-app-vnet" -> null
      - private_endpoint_vnet_policies = "Disabled" -> null
      - resource_group_name            = "grid-meter-app-rg" -> null
      - subnet                         = [
          - {
              - address_prefixes                              = [
                  - "10.20.0.0/24",
                ]
              - default_outbound_access_enabled               = true
              - delegation                                    = []
              - id                                            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-aks-subnet"
              - name                                          = "grid-meter-app-aks-subnet"
              - private_endpoint_network_policies             = "Disabled"
              - private_link_service_network_policies_enabled = true
              - service_endpoint                              = []
              - service_endpoint_policy_ids                   = []
                # (2 unchanged attributes hidden)
            },
          - {
              - address_prefixes                              = [
                  - "10.20.1.0/24",
                ]
              - default_outbound_access_enabled               = true
              - delegation                                    = [
                  - {
                      - name               = "postgres-flexible-server-delegation"
                      - service_delegation = [
                          - {
                              - actions = [
                                  - "Microsoft.Network/virtualNetworks/subnets/join/action",
                                ]
                              - name    = "Microsoft.DBforPostgreSQL/flexibleServers"
                            },
                        ]
                    },
                ]
              - id                                            = "/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-postgres-subnet"
              - name                                          = "grid-meter-app-postgres-subnet"
              - private_endpoint_network_policies             = "Disabled"
              - private_link_service_network_policies_enabled = true
              - service_endpoint                              = [
                  - {
                      - service            = "Microsoft.Storage"
                        # (1 unchanged attribute hidden)
                    },
                ]
              - service_endpoint_policy_ids                   = []
                # (2 unchanged attributes hidden)
            },
        ] -> null
      - tags                           = {
          - "managed-by" = "terraform"
          - "project"    = "grid-meter-app"
        } -> null
        # (2 unchanged attributes hidden)
    }

  # random_password.postgres will be destroyed
  - resource "random_password" "postgres" {
      - bcrypt_hash = (sensitive value) -> null
      - id          = "none" -> null
      - length      = 32 -> null
      - lower       = true -> null
      - min_lower   = 0 -> null
      - min_numeric = 0 -> null
      - min_special = 0 -> null
      - min_upper   = 0 -> null
      - number      = true -> null
      - numeric     = true -> null
      - result      = (sensitive value) -> null
      - special     = false -> null
      - upper       = true -> null
    }

  # time_sleep.rbac_propagation will be destroyed
  - resource "time_sleep" "rbac_propagation" {
      - create_duration = "30s" -> null
      - id              = "2026-09-24T21:44:24Z" -> null
    }

Plan: 0 to add, 0 to change, 20 to destroy.

Changes to Outputs:
  - acr_login_server              = "gridmeterapp3caa5ec0.azurecr.io" -> null
  - aks_cluster_name              = "grid-meter-app-aks" -> null
  - app_identity_client_id        = "e7d5af6c-2d03-448d-8438-a5e26896838c" -> null
  - azure_region                  = "centralus" -> null
  - key_vault_name                = "grid-meter-app-kv" -> null
  - kubeconfig_update_command     = "az aks get-credentials --resource-group grid-meter-app-rg --name grid-meter-app-aks --overwrite-existing" -> null
  - node_resource_group           = "MC_grid-meter-app-rg_grid-meter-app-aks_centralus" -> null
  - postgres_db_name              = "gridmeter" -> null
  - postgres_fqdn                 = "grid-meter-app-postgres.postgres.database.azure.com" -> null
  - postgres_password_secret_name = "postgres-admin-password" -> null
  - postgres_user                 = "gridmeter" -> null
  - redis_hostname                = "grid-meter-app-redis.centralus.redis.azure.net" -> null
  - redis_port                    = 10000 -> null
  - resource_group_name           = "grid-meter-app-rg" -> null

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

azurerm_postgresql_flexible_server_database.main: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres/databases/gridmeter]
azurerm_managed_redis_access_policy_assignment.app: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis/databases/default/accessPolicyAssignments/8932f5b8-6174-4777-bfaa-fc47dd72e9a7]
azurerm_key_vault_secret.postgres_password: Destroying... [id=https://grid-meter-app-kv.vault.azure.net/secrets/postgres-admin-password/bd014a7c638c4a21a49729175e0e45a8]
azurerm_federated_identity_credential.app: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity/federatedIdentityCredentials/grid-meter-app-app-fic]
azurerm_role_assignment.aks_acr_pull: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0/providers/Microsoft.Authorization/roleAssignments/0e6d8c48-53c6-8a37-c613-a263a97cfe7b]
azurerm_federated_identity_credential.app: Destruction complete after 1s
azurerm_role_assignment.aks_acr_pull: Destruction complete after 2s
azurerm_container_registry.main: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerRegistry/registries/gridmeterapp3caa5ec0]
azurerm_kubernetes_cluster.main: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ContainerService/managedClusters/grid-meter-app-aks]
azurerm_managed_redis_access_policy_assignment.app: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...s/8932f5b8-6174-4777-bfaa-fc47dd72e9a7, 00m10s elapsed]
azurerm_postgresql_flexible_server_database.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...meter-app-postgres/databases/gridmeter, 00m10s elapsed]
azurerm_key_vault_secret.postgres_password: Still destroying... [id=https://grid-meter-app-kv.vault.azure.n...sword/bd014a7c638c4a21a49729175e0e45a8, 00m10s elapsed]
azurerm_postgresql_flexible_server_database.main: Destruction complete after 11s
azurerm_postgresql_flexible_server.main: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/grid-meter-app-postgres]
azurerm_managed_redis_access_policy_assignment.app: Destruction complete after 12s
azurerm_user_assigned_identity.app: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/grid-meter-app-app-identity]
azurerm_managed_redis.main: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Cache/redisEnterprise/grid-meter-app-redis]
azurerm_container_registry.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...gistry/registries/gridmeterapp3caa5ec0, 00m10s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 00m10s elapsed]
azurerm_container_registry.main: Destruction complete after 11s
azurerm_user_assigned_identity.app: Destruction complete after 3s
azurerm_key_vault_secret.postgres_password: Still destroying... [id=https://grid-meter-app-kv.vault.azure.n...sword/bd014a7c638c4a21a49729175e0e45a8, 00m20s elapsed]
azurerm_postgresql_flexible_server.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...lexibleServers/grid-meter-app-postgres, 00m10s elapsed]
azurerm_managed_redis.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...e/redisEnterprise/grid-meter-app-redis, 00m10s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 00m20s elapsed]
azurerm_key_vault_secret.postgres_password: Destruction complete after 25s
time_sleep.rbac_propagation: Destroying... [id=2026-09-24T21:44:24Z]
time_sleep.rbac_propagation: Destruction complete after 0s
azurerm_role_assignment.deployer_kv_secrets: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv/providers/Microsoft.Authorization/roleAssignments/84603059-1681-d148-2b5e-b5ebb956b045]
azurerm_role_assignment.deployer_kv_secrets: Destruction complete after 1s
azurerm_key_vault.main: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.KeyVault/vaults/grid-meter-app-kv]
azurerm_postgresql_flexible_server.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...lexibleServers/grid-meter-app-postgres, 00m20s elapsed]
azurerm_managed_redis.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...e/redisEnterprise/grid-meter-app-redis, 00m20s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 00m30s elapsed]
azurerm_key_vault.main: Destruction complete after 9s
azurerm_postgresql_flexible_server.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...lexibleServers/grid-meter-app-postgres, 00m30s elapsed]
azurerm_managed_redis.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...e/redisEnterprise/grid-meter-app-redis, 00m30s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 00m40s elapsed]
azurerm_postgresql_flexible_server.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...lexibleServers/grid-meter-app-postgres, 00m40s elapsed]
azurerm_managed_redis.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...e/redisEnterprise/grid-meter-app-redis, 00m40s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 00m50s elapsed]
azurerm_postgresql_flexible_server.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...lexibleServers/grid-meter-app-postgres, 00m50s elapsed]
azurerm_managed_redis.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...e/redisEnterprise/grid-meter-app-redis, 00m50s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 01m00s elapsed]
azurerm_postgresql_flexible_server.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...lexibleServers/grid-meter-app-postgres, 01m00s elapsed]
azurerm_managed_redis.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...e/redisEnterprise/grid-meter-app-redis, 01m00s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 01m10s elapsed]
azurerm_postgresql_flexible_server.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...lexibleServers/grid-meter-app-postgres, 01m10s elapsed]
azurerm_managed_redis.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...e/redisEnterprise/grid-meter-app-redis, 01m10s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 01m20s elapsed]
azurerm_postgresql_flexible_server.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...lexibleServers/grid-meter-app-postgres, 01m20s elapsed]
azurerm_managed_redis.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...e/redisEnterprise/grid-meter-app-redis, 01m20s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 01m30s elapsed]
azurerm_postgresql_flexible_server.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...lexibleServers/grid-meter-app-postgres, 01m30s elapsed]
azurerm_managed_redis.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...e/redisEnterprise/grid-meter-app-redis, 01m30s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 01m40s elapsed]
azurerm_postgresql_flexible_server.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...lexibleServers/grid-meter-app-postgres, 01m40s elapsed]
azurerm_managed_redis.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...e/redisEnterprise/grid-meter-app-redis, 01m40s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 01m50s elapsed]
azurerm_postgresql_flexible_server.main: Destruction complete after 1m50s
azurerm_private_dns_zone_virtual_network_link.postgres: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com/virtualNetworkLinks/grid-meter-app-postgres-dns-link]
azurerm_subnet.postgres: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-postgres-subnet]
random_password.postgres: Destroying... [id=none]
random_password.postgres: Destruction complete after 0s
azurerm_managed_redis.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...e/redisEnterprise/grid-meter-app-redis, 01m50s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 02m00s elapsed]
azurerm_managed_redis.main: Destruction complete after 1m56s
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 00m10s elapsed]
azurerm_subnet.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...subnets/grid-meter-app-postgres-subnet, 00m10s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 02m10s elapsed]
azurerm_subnet.postgres: Destruction complete after 11s
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 00m20s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 02m20s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 00m30s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 02m30s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 00m40s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 02m40s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 00m50s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 02m50s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 01m00s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 03m00s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 01m10s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 03m10s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 01m20s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 03m20s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 01m30s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 03m30s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 01m40s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 03m40s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 01m50s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 03m50s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 02m00s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 04m00s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...Links/grid-meter-app-postgres-dns-link, 02m10s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 04m10s elapsed]
azurerm_private_dns_zone_virtual_network_link.postgres: Destruction complete after 2m14s
azurerm_private_dns_zone.postgres: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/privateDnsZones/grid-meter-app.postgres.database.azure.com]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 04m20s elapsed]
azurerm_private_dns_zone.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...-meter-app.postgres.database.azure.com, 00m10s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 04m30s elapsed]
azurerm_private_dns_zone.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...-meter-app.postgres.database.azure.com, 00m20s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 04m40s elapsed]
azurerm_private_dns_zone.postgres: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...-meter-app.postgres.database.azure.com, 00m30s elapsed]
azurerm_private_dns_zone.postgres: Destruction complete after 31s
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 04m50s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 05m00s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 05m10s elapsed]
azurerm_kubernetes_cluster.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...ice/managedClusters/grid-meter-app-aks, 05m20s elapsed]
azurerm_kubernetes_cluster.main: Destruction complete after 5m24s
azurerm_subnet.aks: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet/subnets/grid-meter-app-aks-subnet]
azurerm_subnet.aks: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...vnet/subnets/grid-meter-app-aks-subnet, 00m10s elapsed]
azurerm_subnet.aks: Destruction complete after 11s
azurerm_virtual_network.main: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg/providers/Microsoft.Network/virtualNetworks/grid-meter-app-vnet]
azurerm_virtual_network.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...rk/virtualNetworks/grid-meter-app-vnet, 00m10s elapsed]
azurerm_virtual_network.main: Destruction complete after 10s
azurerm_resource_group.main: Destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/grid-meter-app-rg]
azurerm_resource_group.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...21a54/resourceGroups/grid-meter-app-rg, 00m10s elapsed]
azurerm_resource_group.main: Still destroying... [id=/subscriptions/3caa5ec0-0d3e-4cd0-98ec-...21a54/resourceGroups/grid-meter-app-rg, 00m20s elapsed]
azurerm_resource_group.main: Destruction complete after 26s
Releasing state lock. This may take a few moments...

Destroy complete! Resources: 20 destroyed.
tim@Timothys-MacBook-Air azure % terraform state list
tim@Timothys-MacBook-Air azure % terraform show      
The state file is empty. No resources are represented.
tim@Timothys-MacBook-Air azure % ./check-resources-azure.sh 
Could not read resource group/cluster name from terraform output - has 'terraform apply' been run yet?
tim@Timothys-MacBook-Air azure % 


