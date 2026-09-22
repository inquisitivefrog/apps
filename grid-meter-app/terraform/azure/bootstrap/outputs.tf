output "resource_group_name" {
  description = "Resource Group holding the state Storage Account. Paste into ../backend.tf's resource_group_name argument."
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Storage Account holding remote Terraform state for the rest of terraform/azure/. Paste into ../backend.tf's storage_account_name argument."
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Blob container holding the tfstate blob. Paste into ../backend.tf's container_name argument."
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config_snippet" {
  description = "Ready-to-paste backend \"azurerm\" block for ../backend.tf."
  value       = <<-EOT
    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.tfstate.name}"
        storage_account_name = "${azurerm_storage_account.tfstate.name}"
        container_name       = "${azurerm_storage_container.tfstate.name}"
        key                  = "grid-meter-app/terraform.tfstate"
      }
    }
  EOT
}
