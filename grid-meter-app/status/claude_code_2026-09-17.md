# grid-meter-app — Status: 2026-09-17 (Claude Code)

First session after a several-day gap. Full context refresh, closed a documentation gap from the
last session, then began the cloud-deployment (multi-cloud Terraform) work that
`docs/cloud-deployment-scope.md` named as the next brief. Real AWS credential setup, a corrected
pricing claim, and the state-backend bootstrap module got built and planned — nothing has been
applied against AWS yet, at the user's explicit pause for the night.

## Done — full context refresh

- Read `CLAUDE.md` and every file in `docs/` and `status/` in full, per user request, to come up to
  speed on the project's current state after several days away. No summarization shortcuts taken —
  read all 19 `docs/` markdown files and all 26 `status/` files directly (skipped `.DS_Store`, two
  PDFs, and a PNG that duplicate markdown content already read).
- User then shared `git log -n 10`, confirming `HEAD`/`origin/main` at `dacb4be` — surfaced one
  commit (`dacb4be`, "Correct PVC reclaim-policy claim, distinguish the three lifecycle knobs")
  that postdated everything in `status/`, with no status-file record of it yet.

## Done — closed the status-file gap for 2026-09-11

Updated `status/claude_code_2026-09-11.md` (previously ended mid-day with "nothing is committed
yet") to add:
- Confirmation the circuit-breaker load-test work landed as one combined commit (`d227150`), not
  split into two as that file had recommended.
- A new "Done" section for the cloud-deployment gating read-through (`32dbef1`): Postgres confirmed
  clean, a new `cloud` Spring Redis profile added, Kafka `volumeClaimTemplates` +
  `topologySpreadConstraints` added and live-verified against `kind` — closing
  `cloud-deployment-scope.md`'s own stated blocker before Terraform work could start.
- A new "Done" section for the same-day PVC correction (`dacb4be`): Chat caught that the Kafka PVC
  work had only checked the StorageClass's `RECLAIM POLICY` column, never actually exercised
  `persistentVolumeClaimRetentionPolicy.whenDeleted` — re-verified live as three distinct knobs, and
  surfaced a real EKS 1.30+ gap (no auto-marked default StorageClass, unlike GKE/AKS) flagged as a
  prerequisite for the Terraform work about to start.
- Updated "Open"/"Next" to reflect the gating read-through is closed and Terraform is next per the
  doc's own words.

## Done — AWS credential setup, from scratch

User confirmed AWS access exists (root + one IAM user, `bluedragon`, MFA-protected for console
login) but couldn't recall where CLI credentials live or how SDKs pick them up.

- Found `~/.aws/config`/`credentials` already populated with several old-project profiles
  (`myprod`, `bluedragon`, `kerstarsoc`, `manager`, `minio`, a config-only `terraform-admin`), but
  the `default` and `bluedragon` profiles' stored keys both returned `InvalidClientTokenId` —
  confirmed dead via `aws sts get-caller-identity`, not assumed from age alone.
- User checked the IAM console directly: `bluedragon` had two access keys (one 141 days old, one
  643 days old and never used) — recommended deleting both rather than guessing which might still
  be live, and creating a fresh one (root credentials never used for API/Terraform access, per
  standard practice).
- Walked through creating a new access key via the console (confirmed the right wizard screen —
  "Command Line Interface (CLI)" use case) without ever having the user paste secret values into
  the chat — added as a new `[grid-meter]` profile in `~/.aws/credentials`/`config`, verified live:
  ```
  aws sts get-caller-identity --profile grid-meter
  → Account 084375569056, arn:aws:iam::084375569056:user/bluedragon
  ```
- **Confirmed no MFA gate on API calls** — a real read (`aws ec2 describe-regions --profile
  grid-meter`) succeeded cleanly with the static key alone, so Terraform/CLI/SDK access needs no
  session-token/MFA-code step.
- **Confirmed IAM permissions**: `bluedragon` has `AdministratorAccess` attached directly (plus
  `IAMFullAccess`, two EKS-related managed policies, and 3 inline policies) — fully sufficient for
  everything this project's Terraform work will need. One inline policy
  (`TerraformStateAccess`) scopes to `bluedragon-ecommerce-terraform-state`/`terraform-state-lock` —
  a different, prior project's state backend, explicitly not reused here.

## Done — corrected a wrong pricing claim, verified against AWS's own Pricing API

User pushed back on a claim that us-east-1 is cheaper than us-west-2 ("i thought oregon was the
cheap alternative to virginia"). Investigated rather than re-assert from memory:

- A first web search's synthesized summary claimed a 15-20% us-west premium over us-east-1 — but
  its own cited source was talking about **us-west-1 (N. California)**, a materially different and
  genuinely pricier region than **us-west-2 (Oregon)**, conflated in the aggregator's summary.
- AWS's own marketing pricing pages are JS-rendered and don't return real numbers via `WebFetch`.
  Queried AWS's own Pricing API directly instead (via the working `grid-meter` CLI profile):
  `db.t4g.micro` RDS PostgreSQL, `t3.medium` EC2 Linux, and the EKS control-plane per-cluster fee
  are all **identical** between us-east-1 and us-west-2 ($0.016/hr, $0.0416/hr, $0.10/hr
  respectively — confirmed via `aws pricing get-products`, not a secondary source).
- Corrected the framing back to the user directly rather than let the earlier wrong claim stand.
  Region choice settled on **us-west-2**, for separation from the old ecommerce project's state
  bucket (which lives in us-east-1), not for any cost reason.

## Done — Terraform scope decision, discussed against the user's own prior experience

User has a prior AWS Terraform repo (`sre/terraform/aws/...`) with `modules/kubernetes`,
`modules/helm`, and a `stage2-k8s` ArgoCD setup — used as a concrete reference point for the
scope question (does Terraform deploy the app's k8s manifests, or just provision the cluster).

- Explained the current (2024–2026) mainstream split: Terraform owns "day 0" cloud infrastructure
  (VPC, RDS, ElastiCache, EKS control plane + node groups); a separate mechanism (plain
  `kubectl`/Helm, or GitOps via ArgoCD/Flux for a real deploy cadence) owns what runs *inside* the
  cluster. Terraform's own `kubernetes`/`helm` providers are still commonly used for
  cluster-bootstrap add-ons, but fell out of favor for app-workload deployment specifically due to
  state-drift and rollout-ergonomics issues.
- User's own old repo confirmed this exact split in practice (`stage2-k8s`'s ArgoCD is the GitOps
  handoff point after Terraform-provisioned infra).
- User raised a real, well-grounded pushback: CERT-driven OS patching needs rapid node
  rebuild/redeploy, seemingly at odds with "infra changes slowly." Resolved: this still belongs on
  Terraform's side of the line — EKS managed node groups handle a patched-AMI rollout as a normal
  (if urgency-triggered rather than calendar-triggered) `terraform apply`, cordoning/draining/
  replacing nodes automatically. Bottlerocket (AWS's immutable, replace-don't-patch container OS)
  flagged as a good fit given the user's own stated preference for whole-image rebuilds over
  in-place patching.
- **Decided**: Terraform provisions infrastructure only (VPC, RDS, ElastiCache, EKS cluster +
  managed node group); `k8s/deploy.sh` (`kubectl apply`, already proven against `kind`) continues
  to deploy the app itself, just pointed at a real EKS cluster's kubeconfig. **No ArgoCD this
  pass** — real, separate scope with no current need, matching this project's existing
  minimal-scope ethos elsewhere (Helm reserved only for `kube-prometheus-stack`, etc.).

## Done — sizing decision

**Smallest viable**, matching `docs/cloud-deployment-scope.md`'s own stated `terraform destroy`-
between-uses practice: `db.t4g.micro` RDS (single-AZ), `cache.t4g.micro` ElastiCache (single node),
2x `t3.medium` EKS managed-node-group workers.

## Done — scaffolded terraform/{aws,gcp,azure}/, built and planned the AWS state-backend bootstrap

- Created `terraform/.gitignore` (state files, real `.tfvars`, `.terraformrc` — `.terraform.lock.hcl`
  deliberately **not** ignored, since it should be committed).
- Created `terraform/aws/bootstrap/`, `terraform/gcp/`, `terraform/azure/` per
  `cloud-deployment-scope.md`'s own planned directory structure. GCP/Azure left empty — this pass
  is AWS-first per that doc's own sequencing.
- Verified before pinning, not assumed: Terraform 1.13.2 actually installed (`terraform version`),
  current stable `hashicorp/aws` provider is 6.65.0 (checked against the real Terraform Registry
  API).
- **A real design simplification found and verified mid-build**: checked HashiCorp's own S3 backend
  docs directly and confirmed Terraform 1.11+ supports native S3 state locking
  (`use_lockfile = true`, via S3 conditional writes) — the older S3+DynamoDB locking pattern is now
  explicitly deprecated. Since this dev machine runs 1.13.2, built the bootstrap module with **S3
  only, no DynamoDB table** — simpler than originally scoped (task #1's own title still says
  "S3 + DynamoDB," now stale; the DynamoDB half was dropped once this was confirmed).
- `terraform/aws/bootstrap/` now has `versions.tf` (`required_version >= 1.11.0`, `aws ~> 6.65`),
  `variables.tf` (region/profile/project_name, all defaulted sensibly), `main.tf` (one S3 bucket:
  versioned, AES256-encrypted, all public access blocked, `prevent_destroy` set), `outputs.tf`
  (bucket name/region plus a ready-to-paste `backend "s3" {}` snippet for the main config), and a
  `README.md` explaining the local-state-for-bootstrapping-remote-state reasoning and the
  DynamoDB-not-needed decision.
- **`terraform init`**: real provider install succeeded (`hashicorp/aws v6.65.0`, signed and
  verified).
- **`terraform plan`**: clean, 4 resources to add (`aws_s3_bucket`, `_versioning`,
  `_server_side_encryption_configuration`, `_public_access_block`), correctly named
  `grid-meter-app-tfstate-084375569056` in `us-west-2`.
- **`terraform apply` was explicitly not run** — paused for the user's go-ahead per this project's
  standing care-with-real-actions convention (this is the project's first-ever real cloud resource).
  User then asked to stop for the night; confirmed explicitly that nothing has been allocated and
  no cost has been incurred (every AWS-touching command run so far — `sts get-caller-identity`,
  `pricing get-products`, `ec2 describe-regions`, `terraform init`/`plan` — is read-only).

## Task list (tracked via TaskCreate/TaskUpdate, not yet all scoped in file form)

1. **[in progress]** Bootstrap Terraform state backend — built and planned, not yet applied.
2. Scaffold `terraform/aws/` core config (`versions.tf`/`providers.tf`/`backend.tf`/`variables.tf`)
3. VPC + networking (3 AZs — needed for Kafka's existing `topologySpreadConstraints` to have real
   zones to spread across — public+private subnets, single NAT gateway for cost)
4. EKS cluster + managed node group (2x `t3.medium`)
5. RDS PostgreSQL (`db.t4g.micro`, single-AZ, replaces self-hosted Patroni for the cloud target)
6. ElastiCache Redis (`cache.t4g.micro`, single node, replaces self-hosted Sentinel for the cloud
   target — app's `cloud` Spring profile for this already exists, built 2026-09-11)
7. Outputs + `README.md` (cluster/RDS/ElastiCache endpoints, kubeconfig-update command, real cost
   estimate, and the EKS default-StorageClass gap from `dacb4be` as a documented prerequisite)
8. AWS-specific k8s deploy overlay — flagged as likely its own follow-up, not blindly built now:
   `k8s/deploy.sh`'s `configmap.yaml` currently assumes in-cluster Patroni/Sentinel and has no
   AWS-target variant (real RDS/ElastiCache endpoints, `SPRING_PROFILES_ACTIVE=cloud`, skip
   applying `postgres.yaml`/`redis.yaml`/`sentinel.yaml` on AWS). Needs real Terraform outputs to
   exist before this can be designed concretely.

## Open

- **`terraform apply` on the bootstrap module is the very next action**, pending explicit
  go-ahead — creates one real S3 bucket (free-tier-eligible, negligible cost either way).
- Nothing from today is committed. `git status` shows: `status/claude_code_2026-09-11.md` modified,
  `terraform/` untracked (new), plus the pre-existing untracked `README.Claude_Chat.md` (not
  touched, not mine).
- Tasks #2–8 above, all pending.
- Carried over, untouched: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost measurement fix (named
  in `docs/testing-strategy.md`), `docs/testing-expansion-scope.md`'s build order (paused at task
  #9 — soak validation — since 2026-09-10).

## Next

1. Get explicit go-ahead, then `terraform apply` the bootstrap module.
2. Wire the main `terraform/aws/` config's `backend.tf` to the new bucket (via
   `terraform output backend_config_snippet`), then proceed through tasks #2–7 in order (core
   config → VPC → EKS → RDS → ElastiCache → outputs/README).
3. Decide on task #8 (the AWS-target k8s deploy overlay) once real endpoints exist to design
   against.
4. Decide whether/when to commit today's work — recommend after the bootstrap module is actually
   applied and confirmed working, not before, per this project's "verify before commit" standard.
