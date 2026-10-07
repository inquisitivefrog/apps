# 2026-10-06 — AWS free-tier deployment + CI/CD pipeline

## Done

- **Full AWS free-tier deployment working end-to-end**, live-verified (login, meter/reading
  CRUD, Kafka→Postgres/Redis round-trip, real JMeter load test: 0% errors, p95 203ms):
  - Root-caused and fixed, in order: EKS node launch-template IMDS hop limit (1→2, needed once
    EBS CSI moved off IRSA to node-role credentials), missing `ec2:RunInstances`/ECR
    push-auth IAM actions, `t3.micro`'s EKS max-pods ceiling (moved coredns/metrics-server to
    Fargate), `t3.micro`'s 514Mi allocatable vs. Kafka's 768Mi request (→ `t3.small`), and a
    Fargate-startup-time mismatch in `api-aws.yaml`'s liveness probe (92.69s real startup vs.
    75s old kill window → raised to 120s).
  - Architecture is IRSA-free throughout (this account has a hard SCP block on
    `iam:CreateOpenIDConnectProvider`) — EBS CSI via node-role IAM, ElastiCache via password
    auth (`cloud-aws-password` Spring profile), api/frontend/traefik/coredns/metrics-server on
    Fargate, Kafka + daemonsets on a 4-node `t3.small` EC2 group.
- **AWS CI/CD pipeline built**: `.github/workflows/grid-meter-app-aws-startup.yml` (cron 11:00
  UTC / 4am PDT + manual) and `grid-meter-app-aws-teardown.yml` (cron 01:00 UTC / 6pm PDT +
  manual), both on `ubuntu-latest`, deliberately separate from the original local/kind CI.
  Full nightly destroy/rebuild (not partial scale-down) — chosen after pricing out the
  non-stoppable resources (EKS control plane $0.10/hr, NAT $0.045/hr, ElastiCache $0.0128/hr,
  Classic LB $0.025/hr = ~$131.62/mo at 24/7 vs. ~$74.03/mo at a 13.5hr/day full
  rebuild) via live AWS Pricing API queries, not assumed figures.
  - Startup: terraform init/fmt/validate/plan/apply → `check-resources-aws.sh` →
    `deploy-aws.sh` → `check-resources-aws.sh` → `kubectl get nodes/svc/pods` → a real login
    curl as the final health gate (failure → GitHub's default failure email, no extra
    infrastructure).
  - Teardown: `kubectl eks update-kubeconfig` → `teardown-aws.sh` → (informational-only)
    `check-resources-aws.sh` + `kubectl get` → `terraform plan -destroy`/`apply` → (informational-
    only) `check-resources-aws.sh`. Both `check-resources-aws.sh` steps are deliberately NOT
    gates post-teardown (`continue-on-error: true`) — they're positive-existence checks, so
    "all FAIL" is the *correct* post-teardown state, not a real failure signal.
  - Dedicated least-privilege `grid-meter-app-ci` IAM user + policy (separate from the human
    `grid-meter-freetier` user), keys pushed straight to GitHub Secrets via `gh secret set`
    (`AWS_CI_ACCESS_KEY_ID`/`AWS_CI_SECRET_ACCESS_KEY`) — never printed to chat or left on disk.
  - `teardown-aws.sh` fixed to actually fail (not just WARNING-and-continue) when a stuck
    LB/EBS volume is found after polling, and to skip its interactive confirmation when
    `CI=true` (set automatically by GitHub Actions).
  - `aws_eks_access_entry`/`aws_eks_access_policy_association` added for the CI user
    (`AmazonEKSClusterAdminPolicy`) — `bootstrap_cluster_creator_admin_permissions` alone isn't
    reliable across human-vs-CI identity, who last ran `apply`.
  - ECR repos relocated from `terraform/aws/` into the persistent `terraform/aws/bootstrap-
    freetier/` layer — so a full nightly destroy of the main stack doesn't also wipe pushed
    images. `deploy-aws.sh` now computes the ECR URL directly (account ID + region + fixed
    naming) instead of a cross-state `terraform output` read.
  - `terraform/aws/check-resources-aws.sh` had two permanently-stale IRSA-era checks
    (`grid-meter-app-ebs-csi-driver-role`, OIDC provider) removed/replaced — would have been a
    permanent false-positive failure in daily CI otherwise.

## Current live state (as of session end)

- **Two full from-scratch cycles confirmed clean tonight**: a complete `terraform apply` from
  empty state (49 added, 0 errors, `check-resources-aws.sh` 24/24 passed) immediately followed
  by a complete `terraform destroy` back to empty state (49 destroyed, 0 errors) - real proof
  both directions of the full stack lifecycle work cleanly, not just forward build. Never
  verified before this session (every prior build/teardown was incremental patches on top of
  partially-existing state).
- **`terraform/aws/` (main stack): fully destroyed, 0 resources.** `terraform state list` is
  empty, confirmed. Nothing billing in EKS/RDS/ElastiCache/NAT/LB right now.
- **App was never deployed this session's final cycle** - `k8s/deploy-aws.sh` was not run
  against the (now also destroyed) fresh cluster, so there's no in-cluster state, no pushed
  images, nothing for `k8s/teardown-aws.sh` to have needed to clean up before this destroy
  (confirmed live via `kubectl get svc/pvc -A` before destroying - zero LoadBalancer Services,
  zero PVCs - so this particular teardown skipped straight to `terraform destroy`, correctly).
- `terraform/aws/bootstrap-freetier/`: up (state bucket + the 4 ECR repos, still empty - no
  images ever pushed into them this session). **This layer is never destroyed** as part of
  normal teardown/rebuild - a close call this session nearly ran `terraform destroy` there
  twice; both times `aws_s3_bucket.tfstate`'s `lifecycle.prevent_destroy = true` caught it at
  plan time before anything was touched. If that resource is ever intentionally being
  decommissioned, that's the one guard to deliberately remove first - never routine.
- `~/.kube/config`'s current context points at a cluster that no longer exists (the one
  destroyed tonight) - `aws eks update-kubeconfig` will need to run again after the next
  `terraform apply` brings a new cluster up, same as every rebuild this session.

## Open / Next

1. **Rebuild from scratch** (now validated twice tonight as a clean, repeatable cycle):
   `terraform init/fmt/validate/plan/apply` in `terraform/aws/`, then
   `terraform/aws/check-resources-aws.sh`.
2. **Then actually deploy the app**: `k8s/deploy-aws.sh` → `k8s/check-resources-aws.sh` (first
   real run since the ECR-URL-computation change - low risk, but unverified until it runs).
3. Once confirmed healthy end-to-end (login, meter/reading CRUD), **manually trigger
   `grid-meter-app-aws-startup.yml` via `workflow_dispatch`** as the first real test of the
   CI/CD pipeline itself (it's never actually run yet) - expect to debug real issues on the
   first attempt, same as every other piece of infra this session.
4. After that passes, manually trigger `grid-meter-app-aws-teardown.yml` the same way before
   trusting the cron schedules unattended.
5. Still not started: frontend auto-login (agreed approach for the interview-facing fixed URL,
   scoped in conversation, zero code written yet).
6. Still not started: committing the `aws-freetier` branch's accumulated changes - nothing
   committed this session, all work is in the working tree.
