terraform {
  # Same floor as terraform/aws/ and terraform/gcp/ - this dev machine's installed terraform is
  # well above the >= 1.11.0 this project has standardized on.
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Same version confirmed live against the real installed provider (2026-09-22) that
      # terraform/azure/bootstrap/versions.tf pinned - kept identical across both modules
      # deliberately, same reasoning as AWS/GCP's bootstrap-vs-main version consistency.
      version = "~> 5.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6" # same version floor as terraform/gcp/versions.tf, for random_password (postgresql.tf)
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12" # for time_sleep (postgresql.tf) - a documented exception to this project's "poll, don't sleep" rule, see that resource's own comment for why
    }
  }
}
