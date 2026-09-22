variable "azure_region" {
  description = "Azure region for the state Resource Group/Storage Account, and (by default) the main config too. \"eastus\" confirmed live (2026-09-22, web search against current Azure regional pricing comparisons) as Azure's baseline/cheapest US region - the direct Azure equivalent of AWS's us-west-2 and GCP's us-central1 reasoning, both chosen for the same reason."
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Short project identifier, used to build resource names. Azure Storage Account names specifically must be 3-24 characters, lowercase letters and digits ONLY (no hyphens) and globally unique across all of Azure, not just this subscription - a materially stricter constraint than AWS's S3 bucket names or GCP's GCS bucket names, both of which allow hyphens. See main.tf's storage_account_name local for how this project's hyphenated \"grid-meter-app\" name gets adapted to fit."
  type        = string
  default     = "grid-meter-app"
}
