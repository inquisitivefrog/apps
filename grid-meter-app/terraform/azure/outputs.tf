output "resource_group_name" {
  description = "Main Resource Group holding everything this config creates (AKS's own separate auto-created node-resource-group is NOT this - see aks.tf's comment)."
  value       = azurerm_resource_group.main.name
}

output "azure_region" {
  value = var.azure_region
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "kubeconfig_update_command" {
  description = "Run this to fetch/merge real kubeconfig credentials for this cluster - mirrors terraform/aws's/gcp's own kubeconfig_update_command outputs."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name} --overwrite-existing"
}

output "node_resource_group" {
  description = "AKS's own auto-created second Resource Group (MC_<rg>_<name>_<region>, see aks.tf's header comment) - NOT azurerm_resource_group.main above. This is where a `type: LoadBalancer` Service's real Azure Load Balancer/Public IP and Kafka's real Managed Disks actually land (kubectl creates them indirectly, AKS provisions them here) - k8s/deploy-azure.sh's/teardown-azure.sh's/check-resources-azure.sh's own `az network`/`az disk` lookups need this, not the main resource group, or they'll find nothing."
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "acr_login_server" {
  description = "Registry hostname for docker login/build/push - e.g. docker build -t $(acr_login_server)/api:latest ."
  value       = azurerm_container_registry.main.login_server
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_db_name" {
  value = azurerm_postgresql_flexible_server_database.main.name
}

output "postgres_user" {
  value = var.postgres_admin_user
}

output "postgres_password_secret_name" {
  description = "Key Vault secret name holding the real Postgres admin password - fetch at deploy time (az keyvault secret show), never hardcoded."
  value       = azurerm_key_vault_secret.postgres_password.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "redis_hostname" {
  description = "No top-level password/access-key attribute exists on azurerm_managed_redis at all (confirmed via the real provider schema - it authenticates via Entra ID tokens exclusively, see rediscache.tf), so no redis_access_key output exists here on purpose - there's nothing to output. redis_port below, from the required default_database block added 2026-09-23, IS available despite that block's other live-auth-relevant fields (primary_access_key etc.) being equally inapplicable here."
  value       = azurerm_managed_redis.main.hostname
}

output "redis_port" {
  description = "From default_database[0].port (rediscache.tf) - a real, usable value despite Managed Redis having no password/access-key to pair it with. The app can't actually authenticate to this yet (Entra ID token auth needs the Lettuce credential-provider work tracked in README.md's \"What's next\") - wired into deploy-azure.sh's ConfigMap anyway, same as the host, so the config is forward-compatible with that work landing rather than needing a second script change then."
  value       = azurerm_managed_redis.main.default_database[0].port
}
