# Real EKS worker nodes can't pull locally-built images the way `kind load docker-image` lets
# kind do on this laptop - they need a registry they can actually reach. ECR is the natural,
# private, in-account choice; no real alternative worth considering here.

resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-api"
  image_tag_mutability = "MUTABLE"

  # Without this, `terraform destroy` fails outright the moment this repo holds any image -
  # AWS's DeleteRepository API refuses a non-empty repo unless told to force it. This repo WILL
  # hold images by the time destroy runs (every deploy-aws.sh push adds one), so this isn't a
  # hypothetical - confirmed live 2026-09-18 that both repos already held 6 images each without
  # this set, which would have failed a real teardown mid-destroy.
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Keep only the most recent 5 images per repo - this project rebuilds/repushes frequently during
# iteration (mirroring the local kind workflow's fixed-tag rebuild pattern), and an unbounded
# image count is pure storage cost with no real value once superseded.
resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the 5 most recent images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the 5 most recent images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}
