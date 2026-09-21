provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone

  # Provider-level default_labels, supported since google provider v5.0 -
  # the direct equivalent of the AWS provider's default_tags block. Applied
  # automatically to every resource type that supports GCP labels; a few
  # resource types have had historical gaps where default_labels didn't
  # propagate (tracked upstream), worth rechecking if a resource here shows
  # up unlabeled in the Console.
  default_labels = {
    project    = "grid-meter-app"
    managed-by = "terraform"
  }
}
