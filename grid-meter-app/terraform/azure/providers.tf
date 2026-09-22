provider "azurerm" {
  # subscription_id deliberately left unset, same reasoning as bootstrap/versions.tf - the
  # provider auto-detects it from the currently logged-in `az` CLI context, the same
  # "authenticate via the already-logged-in CLI, no dedicated service principal for Terraform
  # itself" pattern AWS/GCP both used.
  features {}

  # default_tags - the google/aws provider equivalent (default_tags/default_labels) applies tags
  # to every resource automatically. azurerm has no provider-level default_tags block as of 5.x -
  # confirmed via the real provider schema (no such top-level attribute) - so each resource that
  # supports `tags` gets local.common_tags applied explicitly instead (see locals.tf). A real,
  # documented difference from AWS/GCP's provider-level convenience, not an oversight.
}
