# GCP equivalent of terraform/aws/ecr.tf. Real GKE worker nodes can't pull locally-built images
# the way `kind load docker-image` lets kind do on this laptop - they need a registry they can
# actually reach. Artifact Registry is GCP's current registry product (Container Registry, the
# older gcr.io-based product, is in deprecation) - the natural, private, in-project choice.

resource "google_artifact_registry_repository" "api" {
  repository_id = "${var.project_name}-api"
  format        = "DOCKER"
  location      = var.gcp_region

  cleanup_policies {
    id     = "keep-5-most-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 5
    }
  }

  cleanup_policy_dry_run = false
}

# Note on AWS's ecr.tf force_delete=true parallel: `google_artifact_registry_repository` has no
# equivalent attribute at all in this provider version (checked via `terraform providers schema`,
# not assumed) - Google's own docs' phrasing ("ensure any packages you want to keep are available
# elsewhere before you remove a repository") reads as "deleting the repo deletes its contents
# too," not "you must empty it first or delete will fail" the way AWS's ECR does. Not yet
# live-confirmed the way AWS's finding was (nothing applied yet on this cloud) - re-verify against
# a real `terraform destroy` on a repo actually holding images before trusting this for real.

resource "google_artifact_registry_repository" "frontend" {
  repository_id = "${var.project_name}-frontend"
  format        = "DOCKER"
  location      = var.gcp_region

  cleanup_policies {
    id     = "keep-5-most-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 5
    }
  }

  cleanup_policy_dry_run = false
}
