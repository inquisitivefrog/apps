# Generated from terraform/azure/bootstrap/'s `backend_config_snippet` output (2026-09-22) - real
# values, not placeholders. Mirrors terraform/aws/backend.tf and terraform/gcp/backend.tf's role
# exactly: wires this main config's state to the Storage Account the bootstrap module created.
terraform {
  backend "azurerm" {
    resource_group_name  = "grid-meter-app-tfstate-rg"
    storage_account_name = "gridmeterapptf3caa5ec0"
    container_name       = "tfstate"
    key                  = "grid-meter-app/terraform.tfstate"
  }
}
