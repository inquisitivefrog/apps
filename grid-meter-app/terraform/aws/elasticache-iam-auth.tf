# Redis (Valkey) auth for this account. Originally IAM-based via IRSA - backported 2026-09-23
# after Azure Managed Redis's forced move to Entra-ID-only auth prompted an explicit decision
# (user sign-off) to align AWS and GCP onto the same tighter posture. That IAM-auth path was
# real, working code (a Lettuce credential provider using AWS SDK's ElastiCache IAM auth token
# signer, live-verified 2026-09-24 against this same account before it became the dedicated
# free-tier account).
#
# Reverted to password-based auth 2026-10-06, specifically for this account only, after
# confirming live that it has a hard AWS Organizations SCP explicit-denying
# iam:CreateOpenIDConnectProvider - no OIDC provider means no IRSA is possible here at all, for
# anything. This isn't a narrow EBS-CSI-only problem (see ebs-csi.tf, which could fall back to
# node-role-based permissions instead): AWS's own EKS Fargate docs state plainly that a Fargate
# pod cannot assume any IAM role without IRSA ("the containers running in the Fargate Pod can't
# assume the IAM permissions associated with a Pod execution role... you must use IAM roles for
# service accounts") - and `api` runs on Fargate on this account (see fargate.tf), not the EC2
# node group, so there's no shared node role to fall back to the way EBS CSI could. Password
# auth is the only mechanism left that works under this constraint. A real, acknowledged
# regression from the multi-cloud IAM-auth alignment goal above, scoped to this one account -
# AWS/GCP's other, non-restricted accounts are unaffected and keep IAM auth.

data "aws_caller_identity" "current" {}

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

# Generated once, stable across deploys (unlike the JWT secret, which deploy-aws.sh freely
# regenerates every run) - this is a persisted ElastiCache user identity, not an ephemeral
# per-deploy value. Retrieved by deploy-aws.sh via `terraform output -raw elasticache_app_password`
# (see outputs.tf) and injected into the k8s secret, same delivery pattern as RDS's password
# except RDS's comes from AWS-managed Secrets Manager and this one is Terraform-managed directly -
# ElastiCache has no equivalent managed-password/Secrets-Manager integration for its users.
resource "random_password" "elasticache_app" {
  length  = 32
  special = false
}

resource "aws_elasticache_user" "app" {
  user_id       = "${var.project_name}-app"
  user_name     = "${var.project_name}-app"
  engine        = "valkey"
  access_string = "on ~* +@all" # full access - matches this project's existing no-auth-restriction posture; narrowing command/key scope is a separate hardening axis from the auth mechanism itself

  authentication_mode {
    type      = "password"
    passwords = [random_password.elasticache_app.result]
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
