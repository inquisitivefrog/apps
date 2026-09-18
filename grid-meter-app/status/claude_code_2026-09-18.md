# grid-meter-app — Status: 2026-09-18 (Claude Code)

Direct continuation of `status/claude_code_2026-09-17.md` — the session ran past midnight, split
into its own dated file per this project's established per-day convention. Finished scaffolding
`terraform/aws/`'s VPC/EKS/RDS/ElastiCache config, worked through several real, verified findings
along the way, and — after confirming `terraform apply` on real infrastructure gets blocked by
Claude Code's own auto-mode safety classifier (the user runs applies themselves going forward,
confirmed decision) — the user ran the full apply. **Real AWS infrastructure now exists and is
live-verified healthy.** Real cost is now accruing (see `terraform/aws/README.md`'s cost estimate,
~$0.257/hr while this stays up).

## Done — finished terraform/aws/'s core config, each piece checked against the live account rather than guessed

Continuing from 09-17's bootstrap module, built the main config file by file, validating after
each:

- **`versions.tf`/`backend.tf`/`providers.tf`/`variables.tf`/`locals.tf`** — the shared chassis.
  Real bug found and fixed immediately: the `backend "s3" {}` block had no `profile` argument
  (backend blocks can't reference variables, so this has to be hardcoded), which meant `terraform
  init` fell back to the dead `default` AWS profile instead of `grid-meter` — fixed by adding
  `profile = "grid-meter"` explicitly.
- **Verified three AWS-managed-service version ceilings live, before writing any variable
  defaults, rather than guessing**: `aws rds describe-db-engine-versions` confirmed RDS supports
  Postgres `18.4` directly (exact match to this project's pin); `aws eks describe-cluster-versions`
  confirmed `1.36` is EKS's current default, in `STANDARD_SUPPORT`; `aws elasticache
  describe-cache-engine-versions` surfaced a real, consequential finding — **AWS's `redis` engine
  tops out at `7.1` (pre-2024-relicensing), with no Redis 8.x offered under that engine name at
  all.** AWS's actual current path for anyone wanting Redis-protocol compatibility post-relicensing
  is a separate `valkey` engine (the Linux Foundation's open fork). Flagged explicitly for
  sign-off rather than silently picked either way — **user chose Valkey** (9.1, the newest
  available), matching version currency better than the frozen `redis` 7.1 option and AWS's own
  current recommended direction.
- **`vpc.tf`** — 3 AZs (matching Kafka's existing `topologySpreadConstraints`), public+private
  subnets, single NAT gateway (cost-conscious, matches this project's established pattern of
  accepting non-HA edge components elsewhere), EKS subnet auto-discovery tags
  (`kubernetes.io/cluster/<name>`, `kubernetes.io/role/elb`/`internal-elb`).
- **`eks.tf`** — cluster IAM role, cluster resource, node IAM role, managed node group (2x
  `t3.medium`, fixed size, no autoscaling), standard addons (vpc-cni, kube-proxy, coredns —
  coredns deliberately `depends_on` the node group, since it needs a schedulable node). Verified
  before writing, not assumed: fetched HashiCorp's own `aws_eks_cluster` resource docs directly and
  confirmed `bootstrap_cluster_creator_admin_permissions` defaults to `true` inside
  `access_config` — meaning the IAM principal running `terraform apply` automatically gets
  cluster-admin `kubectl` access, no separate `aws_eks_access_entry` resource needed. Declared it
  explicitly anyway (`authentication_mode = "API"`, the value stated), matching this project's own
  standing "declare load-bearing settings, don't rely on an implicit default" rule for anything
  this consequential.
- **`rds.tf`** — security group scoped to the EKS cluster's own security group (not a CIDR block),
  `db.t4g.micro`, single-AZ, `manage_master_user_password = true` (AWS Secrets Manager-backed —
  no plaintext password anywhere in this repo or in Terraform state), `storage_encrypted = true`,
  `backup_retention_period = 1` (declared explicitly, shorter than the 7-day engine default —
  demo data has no real recovery value), `skip_final_snapshot = true` (so `terraform destroy`
  doesn't leave an orphaned, indefinitely-billed snapshot).
- **`elasticache.tf`** — **a real provider-level bug found via `terraform validate`, not assumed
  fixable from documentation alone**: `aws_elasticache_cluster` (the simpler single-node resource)
  still client-side-validates `engine` against only `["memcached", "redis"]` in the current
  provider version (6.65.0) — rejects `"valkey"` outright even though AWS's own API genuinely
  supports it (confirmed live via the same `describe-cache-engine-versions` call above). Worked
  around by using `aws_elasticache_replication_group` instead (`num_cache_clusters = 1`, still a
  single node — not adopting HA, just using the resource whose validator has actually been
  updated to accept Valkey).
- **`outputs.tf`** — cluster name/endpoint, `kubeconfig_update_command` (ready-to-pipe-to-bash),
  RDS endpoint + Secrets Manager ARN for the master password, ElastiCache endpoint/port.
- **`README.md`** — full usage flow, a real cost estimate built entirely from live AWS Pricing API
  queries this session (RDS `$0.016/hr`, EC2 `t3.medium` `$0.0416/hr` each, EKS control plane
  `$0.10/hr` flat, ElastiCache Valkey `$0.0128/hr`, NAT gateway `$0.045/hr` base — totaling
  ~$0.257/hr / ~$188/mo if left running), and the EKS default-StorageClass gap (flagged 2026-09-11)
  called out as a real prerequisite before `k8s/deploy.sh` will work against this cluster (EKS
  1.30+ doesn't auto-mark a default StorageClass, unlike GKE/AKS — Kafka's PVCs will sit `Pending`
  until one exists).
- Whole tree formats (`terraform fmt -recursive`) and validates cleanly; a full `terraform plan`
  came back **35 to add, 0 to change, 0 errors** before any real apply was attempted.

## Done — confirmed Claude Code's auto-mode classifier blocks `terraform apply` on real infrastructure

Attempted to run the bootstrap module's `apply` myself (with the user's conversational go-ahead)
— blocked outright by Claude Code's own safety classifier, not an AWS/Terraform issue. Asked the
user how to handle this for the rest of the build (write configs + `plan` myself, user runs every
real `apply`, vs. adding a standing Bash permission rule) — **user chose to run every apply
themselves**, no permission-rule change made. This held for both the bootstrap module (09-17) and
the main config (09-18) — I never ran an `apply` against real AWS this entire project; the user
did, every time, via the `!` prefix.

## Done — real apply, one real bug found and fixed mid-apply, full stack now live

- **Bootstrap module re-verified with zero drift** (`terraform plan`/`show` against the existing
  S3 bucket — `No changes. Your infrastructure matches the configuration.`) before touching the
  main config.
- **First apply attempt**: 31 of 35 resources succeeded cleanly (VPC, IGW, all 6 subnets, NAT
  gateway, both route tables + associations, both IAM roles + all 4 policy attachments, the EKS
  cluster itself — took 8m35s — the node group — 1m58s — and all 3 addons). **A real, simple bug
  in the last 4 resources**: both security group `description` fields used an apostrophe
  ("the EKS cluster's own security group") — AWS's `CreateSecurityGroup` API rejects that
  character outright (`InvalidParameterValue`, allowed set is
  `a-zA-Z0-9. _-:/()#,@[]+=&;{}!$*`, no apostrophe). Checked the rest of the config for the same
  pattern (`grep` for apostrophes inside `description` fields) — the only other hits were
  `variable {}` block descriptions, which are pure Terraform-CLI documentation strings never sent
  to any AWS API, so genuinely unaffected. Fixed both descriptions, re-validated, re-planned (down
  to the 4 blocked resources), re-applied — clean.
- **Full apply complete: 35 resources total across both runs, 0 errors.**
- **Live-verified as actually healthy, not just trusted from the "Apply complete" message** —
  matching this project's own standing discipline throughout its whole history:
  - `aws eks describe-cluster`: `ACTIVE`, version `1.36`.
  - `aws eks describe-nodegroup`: `ACTIVE`, 2x `t3.medium`.
  - `aws rds describe-db-instances`: `available`, engine `18.4`, `MultiAZ: false` as intended.
  - `aws elasticache describe-replication-groups`: `available`, engine `valkey`.
  - **The real functional test**: `aws eks update-kubeconfig` + `kubectl get nodes`/`get pods -A`
    against the live cluster — both nodes `Ready`, every system pod (`aws-node`/CNI x2, CoreDNS
    x2, kube-proxy x2) `Running`. `bootstrap_cluster_creator_admin_permissions` worked exactly as
    designed — `kubectl` reached the cluster immediately with no separate access-entry step.

## Done — reviewed two of the user's old AWS Terraform repos, tangential but worth recording

User asked how `sre/terraform/aws/single_instance`'s layout (`environments/{dev,prod}/` +
`modules/{vpc,eks,kubernetes,kms,identity,...}`) compares to modern practice, and whether
`grid-meter-app` should adopt it.

- **Confirmed the split-environment + modules pattern is real, current best practice** — but for
  a repo managing multiple long-lived real environments, which `grid-meter-app` genuinely isn't
  (single environment demo). Recommended staying flat here, matching this project's own existing
  "plain YAML over Helm" reasoning; the old repo's structure is the right call for *its* actual
  scope, not a strictly-better structure in the abstract.
- Flagged real findings from the directory tree alone: `python3`/`sessionmanager-bundle`/`logs`
  vendored at the repo root rather than documented as external prerequisites; `modules/kubernetes`
  + a separate `environments/dev/eks/kubectl` + `environments/dev/eks/yaml` all coexisting —
  three different mechanisms for getting things into the cluster, the structural fingerprint of
  the "learned through exposure in layers" history the user described.
- **User then shared the actual `.gitignore` from `sre/terraform`** — checked one real claim
  against HashiCorp's own docs before saying anything: confirmed `.terraform.lock.hcl` **should**
  be committed (HashiCorp's own explicit guidance), so that file's `.terraform.lock.hcl` line is a
  real, current-best-practice miss. Also flagged the bare `config`/`credentials` gitignore
  patterns (unscoped to `.aws/`, so they'd match any file with those exact names anywhere in the
  repo). `grid-meter-app`'s own `terraform/.gitignore` (written 09-17) already does this
  correctly.
- **Confirmed `grid-meter-app`'s state backend has zero dependency on the old
  `sre/terraform/aws/tfstate` setup** — a dedicated bucket
  (`grid-meter-app-tfstate-084375569056`) was created fresh 09-17, not shared or reused.
- No code changes resulted from this thread — informational only, at the user's own framing
  ("I don't intend to deploy the old code").

## Done — `terraform.tfvars` question, held off deliberately

Confirmed no `terraform.tfvars` is needed to run this config — every variable already has a
sensible default (region, profile, sizing, DB name/username, versions). `terraform/.gitignore`
already carves out an exception for a future `*.tfvars.example` if one's ever wanted (e.g. once
there's a real override to document, or when the GCP/Azure configs need their own region/sizing
conventions). **User chose to hold off** — no file created.

## Open

- **Task #8, still deliberately unbuilt**: wiring `k8s/deploy.sh`/`configmap.yaml` for the AWS
  target — real RDS/ElastiCache endpoints now exist (see outputs above) and could inform this
  design, but it hasn't been started. Needs: `SPRING_PROFILES_ACTIVE=cloud` (the Spring profile
  built 2026-09-11 for exactly this), the real endpoints substituted into a ConfigMap, and
  `postgres.yaml`/`redis.yaml`/`sentinel.yaml` skipped when deploying to this cluster (Kafka's
  manifests still apply as-is).
- **The EKS default-StorageClass gap is still unresolved** — `k8s/kafka.yaml`'s PVCs will sit
  `Pending` on this cluster until a default StorageClass is created and marked (see
  `terraform/aws/README.md`'s own callout). Not done this session.
- **Real cost is now accruing** (~$0.257/hr / ~$188/mo if left running) — nothing torn down as of
  this write. `terraform destroy` (from `terraform/aws/`, not `bootstrap/`) is the teardown path
  when this isn't actively being used, per `docs/cloud-deployment-scope.md`'s own stated practice.
- Nothing from today is committed yet — held per explicit user request ("after it works"), now
  met. `git status` will show: all of `terraform/aws/*.tf` (new), `terraform/aws/README.md` (new),
  `terraform/aws/.terraform.lock.hcl` (new, should be committed per the lock-file discussion
  above), and this status file (new). `terraform/aws/bootstrap/`'s own files were already
  committed 09-17.
- Carried over, untouched: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost measurement fix,
  `docs/testing-expansion-scope.md`'s build order (paused at task #9 since 2026-09-10).

## Next

1. Commit and push today's work (now that it's confirmed working, per the user's own stated
   checkpoint).
2. Decide whether to tackle task #8 (AWS-target k8s deploy overlay) next, or the
   default-StorageClass gap first (task #8 will hit that gap immediately once attempted, so
   likely worth doing together).
3. Once `k8s/deploy.sh` actually runs cleanly against this cluster: a real end-to-end functional
   check (login → create meter → ingest reading → confirm it lands in the real RDS instance and
   the real ElastiCache cache) — nothing has exercised the app itself against this infrastructure
   yet, only the infrastructure's own health.
4. Remember this stack is now costing real money while up — tear down via `terraform destroy` in
   `terraform/aws/` when not actively working on it.
