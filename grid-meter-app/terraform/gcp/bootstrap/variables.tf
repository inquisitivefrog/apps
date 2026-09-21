variable "gcp_project_id" {
  description = "GCP project to deploy into. This account's billing-linked project as of 2026-09-21 (created via the free-trial signup flow, kept rather than replacing it with a fresh dedicated project - see status/claude_code_2026-09-21.md for that decision)."
  type        = string
  default     = "project-4c5a8821-da4c-4c68-97f"
}

variable "gcp_region" {
  description = "GCP region for the state bucket itself. Should match the main config's region for locality. us-central1 confirmed live (2026-09-21, via web search against current GCP pricing pages) as GCP's baseline/cheapest pricing tier, the same reasoning AWS's us-west-2 choice used."
  type        = string
  default     = "us-central1"
}

variable "project_name" {
  description = "Short project identifier, used to build the globally-unique GCS bucket name (bucket names are global across all of Google Cloud Storage, not just this project)."
  type        = string
  default     = "grid-meter-app"
}
