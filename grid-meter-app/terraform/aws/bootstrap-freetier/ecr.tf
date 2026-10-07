# Moved here from ../ecr.tf (2026-10-06) as part of building the AWS CI/CD pipeline: the CD
# workflow runs a full `terraform destroy` on ../ (the main stack) every night to avoid paying
# for the resources that have no stop/start option (EKS control plane, NAT Gateway, ElastiCache,
# Load Balancer - see docs/cloud-deployment-scope.md or the 2026-10-06 status note for the real
# per-hour pricing that drove this). If ECR stayed in that same state, every pushed image would
# be destroyed nightly too, collapsing "CI builds an artifact, CD deploys it" into "rebuild the
# artifact every single morning" - not the separation a real CI/CD split is supposed to have.
# ECR has no hourly charge (pennies/month in storage for a couple of small images), so there's no
# cost reason it needs to die nightly - it belongs in this rarely-touched bootstrap layer instead,
# alongside the state backend bucket, both created once and left alone.
#
# The two repos previously provisioned under the main stack's state are NOT migrated here via
# `terraform state mv` - deliberately. This project's own standing rule is that this demo's data
# (and, by the same reasoning, its trivially-rebuildable container images) carries no durability
# requirement; the old repos are simply destroyed on the next full `terraform destroy` of ../ and
# these fresh ones take over from an empty state. CI rebuilds and pushes a real image into them
# before the first startup workflow run needs one.

resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

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
