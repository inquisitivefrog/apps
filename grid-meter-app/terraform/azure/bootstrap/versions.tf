terraform {
  # Same floor as terraform/aws/bootstrap/ and terraform/gcp/bootstrap/ - this dev machine's
  # installed terraform is well above the >= 1.11.0 this project has standardized on.
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Current stable on the Terraform Registry as of 2026-09-22 - confirmed live by actually
      # installing it into a scratch dir and inspecting `terraform providers schema -json`, not
      # assumed from documentation text (azurerm 4.0 and 5.0 both carried real breaking schema
      # changes - e.g. azurerm_storage_container now takes storage_account_id, not the older
      # storage_account_name - so trusting stale docs/blog posts here specifically was worth
      # avoiding). Installed version was 5.6.0; ~> 5.5 keeps this on the same major/minor family
      # without silently jumping to a future 6.x that could reintroduce the same kind of breaking
      # change.
      version = "~> 5.5"
    }
  }

  # Deliberately local state for this module only, same reasoning as the AWS/GCP bootstrap
  # modules: it creates the Storage Account the rest of terraform/azure/ uses as a *remote*
  # backend, so it can't depend on that backend without a circular bootstrap problem.
}

provider "azurerm" {
  features {}
  # subscription_id deliberately left unset - the provider auto-detects it from the currently
  # logged-in `az` CLI context (confirmed via provider schema: subscription_id is optional, not
  # required), the same "authenticate via the already-logged-in CLI, no dedicated service
  # principal for Terraform itself" pattern AWS/GCP both used (`aws sso`/`gcloud auth
  # application-default login`).
}
