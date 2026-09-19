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

## Done — task #8: AWS-specific k8s deploy overlay, then live-debugged until it genuinely worked

With base infra live, built the second half of the day's work: ECR repos (`ecr.tf`, lifecycle
policies keeping the 5 most recent images), the EBS CSI driver as its own EKS addon with real
IRSA (`ebs-csi.tf` — `aws_iam_openid_connect_provider` with a live-computed OIDC thumbprint via
`data "tls_certificate"`, not hardcoded), a `gp3` StorageClass (`k8s/storageclass-aws.yaml`,
closing the gap flagged above), an AWS Traefik variant (`k8s/traefik-aws.yaml` — real NLB via a
`LoadBalancer` Service, `hostPort`/`nodeSelector: ingress-ready` stripped), an AWS `api` variant
(`k8s/api-aws.yaml` — `SPRING_DATA_REDIS_HOST`/`PORT` replacing kind's Sentinel env vars), and
`k8s/deploy-aws.sh` (reads every endpoint from live `terraform output`, never a hardcoded value).

**Then spent most of the day's remaining time live-debugging it against the real cluster until
the app actually worked** — matching this project's own standing "verify the live system" ethos.
Six distinct real bugs found and fixed, each with direct evidence, not guessed at:

1. **Kafka `AccessDeniedException` on `/var/lib/kafka/data`** — a non-root container against a
   freshly-provisioned, root-owned EBS volume. Fixed with `securityContext.fsGroup: 1000`, added
   to the *shared* `k8s/kafka.yaml` (benefits `kind` too — was a latent gap invisible there only
   because `local-path-provisioner` is more permissive).
2. **`api`/`frontend` `ImagePullBackOff`/`InvalidImageName`** — two causes layered together: (a)
   the original apply-placeholder-then-`kubectl set image` design caused wasteful ReplicaSet
   churn, fixed by `sed`-substituting the real ECR image before the first apply; (b) a genuine
   arch mismatch (`no match for platform in manifest`) — this Mac is Apple Silicon, the node
   group is `t3.medium` (x86_64) — fixed with `--platform linux/amd64` on both `docker build`
   calls.
3. **Kafka's StatefulSet spec updated but pods didn't roll** — confirmed via `kubectl get
   statefulset -o jsonpath` (spec was correct) vs. unchanged pod creation timestamps; forced with
   a manual `kubectl delete pod kafka-0 kafka-1 kafka-2`.
4. **`api` OOMKilled (exit 137) at 512Mi**, dying before Spring Boot logged past the active
   profile. `-Xmx384m` only bounds heap; JPA/Security/Kafka client/full Micrometer+OTel tracing
   all initializing at once needed real headroom beyond that. Live-diagnosed by patching the
   limit to 1Gi and watching it progress much further — confirmed the real cause before making it
   permanent in `api-aws.yaml`.
5. **Kafka crashed again with a *different* exception after the fsGroup fix**:
   `KafkaException: Found directory .../lost+found`. Root cause: ext4 auto-creates `lost+found`
   as part of the filesystem itself, and Kafka's `LogManager` fatally errors on any directory
   under its log dir that isn't topic-partition-named. Fixed by switching the StorageClass to XFS
   (verified against the EBS CSI driver's own docs for the right parameter key,
   `csi.storage.k8s.io/fstype`) — required deleting+recreating the StorageClass (`parameters` is
   immutable) and deleting Kafka's StatefulSet + its 3 ext4 PVCs so fresh XFS volumes would
   provision.
6. **Real node overcommitment**: once `api`'s memory limit was corrected to a realistic 1Gi,
   `kubectl describe nodes` showed one of the 2 `t3.medium` nodes at 94% memory requests / 139%
   limits — genuinely too tight, and structurally unable to give Kafka's 3 brokers one-node-per-
   broker spread across the existing 3 AZs regardless of sizing. Presented as a real cost
   decision rather than resolved silently — **user chose to bump to 3x `t3.medium`**
   (`variables.tf`'s `eks_node_count` 2→3, applied by the user).
7. **Self-inflicted**: an earlier ad hoc `kubectl delete replicaset --cascade=orphan` diagnostic
   command left 2 `api` pods running unowned by any ReplicaSet, producing a visibly uneven pod
   distribution the user caught directly (`kubectl get pods -o wide`). Investigated, found it was
   my own earlier command, fixed by deleting the 2 orphaned pods and the leftover 0-replica
   ReplicaSet.

## Done — task #15: live functional validation against the real, fully-fixed cluster

With the cluster confirmed clean (7 pods, Kafka one-per-node across all 3 AZs, `api` split across
2 nodes), ran the actual application-level check directly against the real AWS LoadBalancer
(`http://a46ce64f2129449d3bab4ca5803a8b7b-2033904046.us-west-2.elb.amazonaws.com`), per
`architecture.md`'s documented data flow — not just trusting a clean `kubectl get pods`:

1. `POST /api/v1/auth/login` (seeded `demo`/`GridMeter!Demo2026`) — real JWT issued.
2. `POST /api/v1/meters` — succeeded, confirming the real RDS write path.
3. `POST /api/v1/readings` (with an `Idempotency-Key` header) — succeeded, publishing through the
   real 3-broker Kafka cluster.
4. `GET /api/v1/readings?meterId=...` — the reading came back on the **very first poll attempt**,
   confirming the full async Kafka → consumer → Postgres pipeline genuinely works.
5. Checked the ElastiCache/Valkey side too (not just RDS) via a throwaway `redis-cli` debug pod
   against the real ElastiCache endpoint — confirmed `reading:latest:<meterId>` and an
   `idempotency:<key>` key both landed, closing the loop on `architecture.md`'s stated "consumer
   writes to Postgres *and* Redis" data flow.

**Full functional pipeline confirmed working end-to-end against real AWS infrastructure — the
actual goal of this entire multi-hour debugging arc.** Attempted cleanup of the test meter/reading
afterward: `DELETE /api/v1/meters/<id>` correctly returned `409 Conflict` ("cannot be deleted
because other records still reference it") — expected, not a bug, since readings are immutable by
design and there's deliberately no delete path around that FK. Left the one test meter/reading in
place rather than force it out via a direct SQL `DELETE` that would go around the app's own
data-integrity contract.

## Done — scope decision: AWS is Terraform-proof, `kind` stays the load+observability demo

User asked whether the point of this project (containers/app-server/messaging/datastore, load
testing, observability, Grafana/Loki demo) was actually being met by the AWS track. Checked
directly rather than assumed: this EKS cluster has zero observability namespace/pods
(`kube-prometheus-stack`/Loki/Tempo/Alloy was only ever built and validated against `kind`), and
`load-tests/*.jmx` has never targeted the real AWS LoadBalancer. **User decision: `kind` remains
the full demo (load + dashboards); AWS stays scoped to proving real Terraform/cloud-native
deployment capability only.** Documented explicitly in `terraform/aws/README.md`'s new
"Observability is not part of this deployment" section, and in the new deployment-topology
diagram (see below) as a deliberate callout, not a silent gap.

Also built `docs/deployment-topology.pdf` — a laptop-vs-AWS diagram (HTML/CSS rendered to a real
PDF via headless Chrome, matching the existing PDF precedent in `docs/`), colorblind-safe (border
style + icons, not color alone, per standing user accessibility note) — showing exactly which
resources run where and calling out what's deliberately not on the AWS side.

## Done — QA regression pass: real spin-up/teardown runbook written, tested, two real bugs found and fixed

User put on a "QA hat" and required an actual retest cycle after `k8s/teardown-aws.sh` was first
built, rather than trusting it untested — this found real, consequential bugs a first pass would
have missed:

- **Wrote the actual interview-day runbook** in `terraform/aws/README.md` ("Spin-up and teardown"
  section) plus a new `k8s/teardown-aws.sh` script — the missing half of `deploy-aws.sh`.
  Confirmed live (2026-09-18) that a real, load-balanced Service on this cluster resolves to a
  **Classic ELB, not an NLB** as originally assumed and never actually verified (no
  `aws-load-balancer-type` annotation, no AWS Load Balancer Controller addon installed) —
  corrected everywhere: `teardown-aws.sh`, `traefik-aws.yaml`, `deploy-aws.sh`, and the README's
  cost table (Classic ELB is $0.025/hr + $0.008/GB, not NLB's $0.0225/hr + LCU pricing).
- **Bug #1, found via first real test run**: `teardown-aws.sh` deleted Kafka's PVCs while its pods
  were still running and holding them mounted — all 3 got stuck `Terminating` forever (a PVC
  can't finish deleting, and its EBS volume can't be released, while a pod still claims it). Fixed
  by deleting the StatefulSet first, waiting for pods to actually terminate, then deleting PVCs.
- **Bug #2, found via a full from-scratch retest of the entire cycle**: the ECR `force_delete =
  true` fix (added earlier the same day) was only ever *planned*, never actually applied, before a
  real `terraform destroy` was run — it failed exactly as predicted (`RepositoryNotEmptyException`
  on both repos), while everything independent of ECR (RDS, ElastiCache, NAT gateway, all 5 EKS
  addons, the node group, the cluster, the VPC) destroyed successfully in parallel regardless,
  since Terraform destroys unrelated dependency chains concurrently. Real, live-confirmed
  consequence of "planned but not applied" being meaningfully different from "fixed."
- **Cleaned up the resulting partial-destroy state**: emptied both ECR repos directly (images are
  disposable build artifacts, not data — including a manifest-list-vs-child-image ordering wrinkle
  that needed a short wait for ECR's own eventual consistency to resolve), confirmed via direct
  AWS API calls that everything else had genuinely already destroyed, then let `terraform destroy`
  finish the remaining 2 resources cleanly.
- **Full clean retest, start to finish, zero manual intervention required**: fresh `terraform
  apply` (44 added, 0 errors, `force_delete=true` now baked in from creation) → `deploy-aws.sh`
  (clean first-try success — no OOM, no ext4/lost+found, no image-arch mismatch, no fsGroup
  error, every earlier-session fix confirmed durable) → `teardown-aws.sh` (clean, both bugs above
  confirmed fixed, no manual fix needed this time) → `terraform destroy` (44 destroyed, 0 errors,
  single pass) → **full 12-point residue checklist, all empty, independently verified via direct
  AWS API calls, not trusted from "Destroy complete" alone.**
- **Cost cross-check attempted, found unreliable same-day**: tried using AWS Cost Explorer as a
  second, independent confirmation that nothing was left billing. Real finding: Cost Explorer data
  lags — querying it immediately after today's teardown showed a stale picture (missing known real
  EKS/RDS/ElastiCache/NAT charges from the very hours just spent testing), not zero. Built
  `terraform/aws/check-costs.sh` to make this reusable, with the lag limitation documented
  explicitly rather than let it produce a false "looks clean" reading if run too soon after a
  teardown.

**Net result**: the interview-day spin-up/teardown runbook is now genuinely tested, not just
written — both real defects that a first pass would have missed (and that would have meant either
orphaned, still-billing AWS resources or a hung `terraform destroy`) are fixed and confirmed via
an actual clean second run, matching this project's own standing "QA is primarily retesting"
practice.

## Done — inspection scripts: confirm resources actually exist, not just that a tool said so

User asked for the inverse of the residue checklist — confirm expected resources are actually
*present* and healthy right after `apply`/`deploy-aws.sh`, not just trust "Apply complete" /
"successfully rolled out". Built two, one per layer:

- **`terraform/aws/check-resources.sh`** — queries every Terraform-provisioned resource directly
  (VPC/networking, EKS cluster/node group/all 5 addons, RDS, ElastiCache, ECR, IAM roles/OIDC) via
  the real AWS API, PASS/FAIL per item plus a summary. Worked cleanly on first use: 24/24 passed
  against a fresh `apply`.
- **`k8s/check-resources-aws.sh`** — the Kubernetes-layer counterpart (Traefik, Kafka
  StatefulSet/PVCs, api/frontend Deployments, config/secrets/IngressRoute/StorageClass). Found and
  fixed two real bugs in its own first test run, immediately, against a cluster with a known
  partially-torn-down state (Kafka and the LB already deleted from the prior teardown step):
  1. A false `PASS` on a genuinely missing Service — the check function only tested for
     non-empty output, and `kubectl`'s own `Error from server (NotFound): ...` text is itself
     non-empty, so a missing resource was silently reported as present. Fixed by checking the
     command's actual exit code, not just its output.
  2. A PVC-count check using an `||` fallback double-counted: both `grep -c` branches print their
     own "0" before the `||` logic evaluates, concatenating into "00" instead of "0". Fixed by
     dropping the fallback for a single, direct count.
  Re-tested against the same known state after both fixes — every result matched ground truth
  exactly (genuinely-gone resources correctly `FAIL`, genuinely-present ones correctly `PASS`).

**Then ran a full second end-to-end cycle using both new scripts as real gates**, not just as an
afterthought: `terraform apply` (44 added) → `check-resources.sh` (24/24 passed) →
`deploy-aws.sh` (clean) → `teardown-aws.sh` (clean, zero manual intervention — both bugs from the
first QA pass held fixed) → `terraform destroy` (44 destroyed, 0 errors) → 12-point residue
checklist (all empty). **Two consecutive clean full cycles now, with the second one exercising the
new inspection scripts as well** — the strongest confidence level this runbook has had yet.

## Open

- **AWS stack is fully torn down as of this write** — confirmed via the 12-point residue
  checklist (run twice, both times all empty). No real cost is currently accruing on the AWS side.
- **Nothing from today's work is committed yet** — the full k8s-overlay build (tasks #8–#15), the
  QA-cycle bug fixes (`teardown-aws.sh`, `ecr.tf`'s `force_delete`, the NLB→Classic-ELB
  corrections across 4 files), the two new inspection scripts (`terraform/aws/check-resources.sh`,
  `k8s/check-resources-aws.sh`), `check-costs.sh`, and `docs/deployment-topology.pdf` are all
  new/modified and uncommitted. Ready to commit on request — the "confirmed working" bar is now
  met more thoroughly than usual (two full tested spin-up/teardown cycles, not just one clean
  run).
- One test meter/reading from yesterday's functional check remains in what was, at the time, a
  different RDS instance — moot now, since that whole AWS instance was destroyed as part of
  today's QA cycle. Nothing to clean up.
- Carried over, untouched: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost measurement fix,
  `docs/testing-expansion-scope.md`'s build order (paused at task #9 since 2026-09-10), GCP/Azure
  Terraform configs (AWS-first sequencing per `docs/cloud-deployment-scope.md`).

## Next

1. Commit and push today's full day of work, on request.
2. Before the next real interview-day spin-up: `./terraform/aws/check-costs.sh` a day or two out
   from today to get a delayed but genuine confirmation that costs actually dropped to zero,
   complementing (not replacing) today's live resource-based confirmation.
3. GCP/Azure Terraform configs, per `docs/cloud-deployment-scope.md`'s stated AWS-first
   sequencing — AWS is now the fully proven, genuinely tested reference implementation to follow.
4. Longer-carried items: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost fix,
   `docs/testing-expansion-scope.md` task #9+.
