# IAM-based Redis (Valkey) auth via IRSA - backported 2026-09-23 after Azure Managed Redis's
# forced move to Entra-ID-only auth prompted an explicit decision (user sign-off) to align AWS
# and GCP onto the same tighter posture rather than leave them on password auth just because
# nothing forced it yet. Confirmed live (docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html):
# IAM auth works with the valkey engine already in use in elasticache.tf, not redis-only, and
# requires transit encryption - see transit_encryption_enabled below.
#
# This introduces IRSA (IAM Roles for Service Accounts) scoped to the *app's own* K8s
# ServiceAccount - previously the only IRSA role in this config was ebs-csi.tf's, for the
# EBS CSI driver addon, not the application itself. The app has never needed its own cloud
# identity before now (Postgres uses a Secrets-Manager-stored password, not IAM DB auth).
#
# Terraform-side only, deliberately: the actual token-generation client code (a Lettuce
# credential provider using AWS SDK's ElastiCache IAM auth token signer) and the matching
# k8s/api-aws.yaml ServiceAccount (name "grid-meter-app", namespace "default" - matching the
# subject condition below) are real application-code/manifest work, tracked as a required
# follow-up alongside Azure's own already-flagged Entra ID Lettuce provider gap - not attempted
# inline here. This Terraform is inert (no pod can assume the role yet) until that follow-up
# lands, same as Azure Managed Redis's Terraform was already fully correct before its own
# app-code gap is closed.

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "app_irsa_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    # Scoped to exactly the app's own service account, same pattern as ebs-csi.tf's driver role -
    # not a blanket trust of anything in the cluster.
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:default:grid-meter-app"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_irsa" {
  name               = "${var.project_name}-app-role"
  assume_role_policy = data.aws_iam_policy_document.app_irsa_assume_role.json
}

# ElastiCache requires a "default" user present in every user group (confirmed live via
# `aws elasticache create-user-group` validation) - explicitly disabled (access_string "off") so
# it exists to satisfy that requirement without itself being a usable, password-less backdoor
# alongside the IAM-only user below.
#
# Found via a real live apply failure (2026-09-23): "No-password-required is not allowed for a
# user with engine Valkey" - unlike Redis OSS, Valkey's authentication_mode doesn't support
# no-password-required at all; every user needs a real password or IAM auth, even a disabled one.
# A random, never-retrieved, never-used password satisfies that requirement without creating an
# actual usable credential - access_string "off" is what actually disables the user.
resource "random_password" "elasticache_default_disabled" {
  length  = 32
  special = false
}

resource "aws_elasticache_user" "default_disabled" {
  user_id       = "${var.project_name}-default-disabled"
  user_name     = "default"
  engine        = "valkey"
  access_string = "off ~* +@all"

  authentication_mode {
    type      = "password"
    passwords = [random_password.elasticache_default_disabled.result]
  }
}

resource "aws_elasticache_user" "app" {
  user_id       = "${var.project_name}-app"
  user_name     = "${var.project_name}-app"
  engine        = "valkey"
  access_string = "on ~* +@all" # full access - matches this project's existing no-auth-restriction posture; narrowing command/key scope is a separate hardening axis from the auth mechanism itself

  authentication_mode {
    type = "iam"
  }
}

resource "aws_elasticache_user_group" "app" {
  user_group_id = "${var.project_name}-users"
  engine        = "valkey"
  user_ids = [
    aws_elasticache_user.default_disabled.user_id,
    aws_elasticache_user.app.user_id,
  ]
}

data "aws_iam_policy_document" "elasticache_connect" {
  statement {
    effect  = "Allow"
    actions = ["elasticache:Connect"]
    resources = [
      aws_elasticache_replication_group.main.arn,
      "arn:aws:elasticache:${var.aws_region}:${data.aws_caller_identity.current.account_id}:user:${aws_elasticache_user.app.user_id}",
    ]
  }
}

resource "aws_iam_policy" "elasticache_connect" {
  name   = "${var.project_name}-elasticache-connect"
  policy = data.aws_iam_policy_document.elasticache_connect.json
}

resource "aws_iam_role_policy_attachment" "app_elasticache_connect" {
  role       = aws_iam_role.app_irsa.name
  policy_arn = aws_iam_policy.elasticache_connect.arn
}
