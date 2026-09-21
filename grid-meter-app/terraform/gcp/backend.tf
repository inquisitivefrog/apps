# Generated from terraform/gcp/bootstrap's own `terraform output backend_config_snippet` after
# that module was applied (2026-09-21) - bucket already exists, not created by this config. See
# bootstrap/README.md for why this project's GCP state lives in GCS rather than locally.
terraform {
  backend "gcs" {
    bucket = "grid-meter-app-tfstate-project-4c5a8821-da4c-4c68-97f"
    prefix = "grid-meter-app/terraform.tfstate"
  }
}
