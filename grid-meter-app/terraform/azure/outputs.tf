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
  value = azurerm_redis_cache.main.hostname
}

output "redis_ssl_port" {
  value = azurerm_redis_cache.main.ssl_port
}
