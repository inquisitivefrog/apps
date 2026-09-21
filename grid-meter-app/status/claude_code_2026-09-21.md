# grid-meter-app — Status: 2026-09-21 (Claude Code)

Weekend catch-up session: reconfirmed where the AWS track left off, ran the delayed
`check-costs.sh` cross-check, cleaned up a stale temp file, then started the GCP Terraform track
(`docs/cloud-deployment-scope.md`'s stated AWS-first sequencing) — scaffolded `terraform/gcp/`
and `terraform/gcp/bootstrap/`, deliberately plan-only, no real GCP resources created.

## Done — resumed context, confirmed nothing was actually left uncommitted

09-18's status file said "nothing from today's work is committed yet," but `git log` showed it
had in fact been committed (`5a88d51`) after that file was written — the note was stale, not a
real gap. No action needed.

## Done — `check-costs.sh` delayed cross-check: confirmed clean

Ran `terraform/aws/check-costs.sh` (built 09-18 specifically for this delayed-confirmation
purpose). Cost Explorer data now has the 2-3 day lag it needed: 09-18 and 09-19 show real charges
matching that day's two full test cycles (EKS/RDS/ElastiCache/EC2/ELB), but **09-20 is back down
to baseline-only** (~$0.0002/day, ECR storage only) — independent confirmation the teardown
genuinely left nothing billing, closing out 09-18's Next-item #2.

## Done — deleted `README.Claude_Chat.md`

A temporary brief the user drafted in Claude Chat for the original "scaffold AWS, plan-only"
pass. Reviewed it against what actually happened: all 6 of its tasks are done and superseded by
much later work (real apply, full k8s overlay, two tested spin-up/teardown cycles) — one real
divergence worth recording, that pass's ElastiCache assumption ("Redis free-tier") was corrected
mid-build to Valkey once the Redis-engine version ceiling was found live. User confirmed deletion
after the review; file removed (was untracked, nothing to commit).

## Done — GCP account setup, from zero

This Google account had never touched GCP for real:
- No `gcloud` credentials, no Application Default Credentials, no billing account, no project
  with billing linked. All required manual steps the user did themselves (browser-based OAuth
  logins, adding a payment method / starting the free trial in the Console) — confirmed
  factually first (via a live web search against Google's own billing docs) that a payment
  method is unavoidable even for Always-Free-tier usage, not optional.
- Landed on `project-4c5a8821-da4c-4c68-97f` ("My First Project", auto-created by the trial
  signup flow) — user chose to keep it rather than create a fresh dedicated project.
- Enabled required APIs live (all free/no-cost operations): `compute`, `container`, `sqladmin`,
  `redis`, `memorystore`, `servicenetworking`, `iam`, `cloudresourcemanager`, `secretmanager`.

**User context worth carrying forward**: prior GCP experience (~1 year stale) was mostly
`kubectl`-driven against a real multi-datacenter deployment (private DC + GCP, deliberately
porting/patching tools to work across both rather than adopting GCP-specific services, to avoid
both extra tooling and extra GCP cost) — day-to-day access was Console-first with minimal direct
`gcloud`/`gsutil`/`bq` use, and observability leaned on Splunk/DataDog rather than GCP-native
tools. Broadly matches what `docs/cloud-deployment-scope.md` already had recorded for GCP
familiarity, with the added specifics of *why* (the private-DC-parity strategy) and *which*
tools were actually hands-on (`kubectl` heavy, CLI-admin-tools light). Explains why this session
walked through each `gcloud`/Terraform-GCP-provider step explicitly rather than assuming muscle
memory.

## Done — scoped this GCP pass explicitly before building

Two decisions confirmed with the user before any scaffolding: **plan-only this pass** (matching
how the AWS track itself started 09-17, before a separate later apply decision) — no
`terraform apply` run against anything, including `bootstrap/`; and **use the existing auto-created
project** rather than a fresh dedicated one.

## Done — scaffolded `terraform/gcp/bootstrap/` (GCS state backend), planned clean

Mirrors `terraform/aws/bootstrap/` exactly: one `google_storage_bucket` (versioned,
`uniform_bucket_level_access` + `public_access_prevention = "enforced"`, `prevent_destroy`).
`terraform init`/`fmt`/`validate`/`plan` all clean — **1 to add, 0 to change, 0 to destroy**. No
apply run. Two GCS-specific facts worth recording since they're genuine differences from the AWS
side, not omissions: GCS-backend state locking is always-on (no `use_lockfile`-style flag to
declare, unlike S3), and every GCS bucket is encrypted at rest by default with no separate
resource needed (unlike S3's explicit `aws_s3_bucket_server_side_encryption_configuration`).

## Done — scaffolded `terraform/gcp/` main config, planned clean

`versions.tf`/`providers.tf` (with `default_labels`, the google-provider equivalent of AWS's
`default_tags`) / `variables.tf` / `locals.tf` / `network.tf` / `gke.tf` / `cloudsql.tf` /
`memorystore.tf` / `outputs.tf` / `README.md`. `terraform init`/`fmt`/`validate`/`plan` all
clean — **17 to add, 0 to change, 0 to destroy**, matching the AWS main config's own clean-plan
bar. No apply run.

Real findings, checked live rather than assumed (same discipline as the AWS pass'
RDS/EKS/ElastiCache version checks):

- **GKE**: `REGULAR` release channel's current default is `1.35.8-gke.1036000`
  (`gcloud container get-server-config --region us-central1`). Declared the channel explicitly
  rather than the bare-version pinning EKS uses — GKE's own idiomatic mechanism, not a workaround.
- **Cloud SQL**: `POSTGRES_18` directly supported (`gcloud sql instances create --help`'s
  `--database-version` enum) — clean match to this project's pin, same result AWS's RDS check
  found.
- **Memorystore — a real, direct parallel to the AWS ElastiCache finding**: GCP's legacy
  "Memorystore for Redis" (`google_redis_instance`) tops out at Redis **7.2**, no 8.x/9.x at all
  (`gcloud redis instances create --help`). The current path past that is a separate, newer
  product, **Memorystore for Valkey** (`google_memorystore_instance`), supporting Valkey
  7.2/8.0/9.0/9.1 (9.1 still Preview) — chosen **9.0**, the current GA default. Proceeded with
  Valkey directly by analogy to the AWS decision already made once, rather than re-asking the
  user to confirm the same structural choice a second time.
- **Cloud SQL has no RDS-style `manage_master_user_password`** — wired up the idiomatic GCP
  substitute instead (`random_password` + Secret Manager secret + version), more manual than
  AWS's one-flag convenience.
- **Memorystore for Valkey's networking is Private Service Connect** (auto-created PSC endpoint),
  genuinely distinct from Cloud SQL's classic VPC-peering "Private Service Access" — two
  different GCP private-connectivity generations in one config, not an inconsistency.
- **Region**: `us-central1` confirmed live (web search against current GCP pricing sources) as
  GCP's baseline/cheapest tier, same reasoning as AWS's `us-west-2`.
- **Sizing decisions carried forward from AWS's own hard-won lessons rather than re-discovered**:
  node count started at 3 (not 2-then-3) directly citing AWS's live-debugging finding that 2
  nodes structurally can't give Kafka's 3 brokers one-per-zone regardless of sizing; node service
  account built as a dedicated least-privilege SA + `roles/container.nodeServiceAccount` (not
  broad `cloud-platform` OAuth scope), mirroring AWS's dedicated node IAM role reasoning, and
  confirmed live via web search against GCP's own node-service-account security guidance that
  this is currently Google's own recommended pattern.
- **One deprecation caught via `terraform validate`**: `google_memorystore_instance`'s
  `discovery_endpoints` attribute is deprecated in favor of `endpoints` — fixed before it ever
  reached a plan.

## Done — built and live-tested `terraform/gcp/check-resources.sh`

User asked for GCP equivalents of AWS's scripts. Two are genuinely portable now; two aren't (see
below). Built `check-resources.sh` (the counterpart to `terraform/aws/check-resources.sh`), scoped
to this pass's base infra only (VPC/GKE/Cloud SQL/Memorystore) — no Artifact Registry/Workload
Identity section, since that layer isn't built yet, matching how AWS's own script only grew those
sections once its later phase existed.

**Live-tested against this real, currently-empty project before any real resource existed** —
deliberately, to catch command/flag bugs early rather than only discovering them against a real
apply later. Found and fixed two real bugs this way:
1. `gcloud compute networks subnetworks describe` isn't a valid command (`subnets`, not
   `subnetworks`) — a plain usage error, caught immediately.
2. **A real false-PASS bug, the same shape AWS's `k8s/check-resources-aws.sh` found the hard way
   (2026-09-18), caught here before any live resource existed to hide behind**: `gcloud compute
   instances list` with zero filter matches exits **0** with only an empty-match warning on
   stderr — a bare exit-code check would have read that as a false PASS with no real value behind
   it. Fixed by requiring both a zero exit code AND non-empty stdout, with stdout/stderr captured
   separately (via a temp file, not `2>&1`) so a successful-but-empty result can't read as a real
   value either way.

Re-ran after both fixes: all 15 checks correctly report FAIL against the real empty project (no
crashes, no false positives) — the meaningful bar for a script with nothing real to check yet.

## Done — `check-costs.sh`: not built, explained why rather than faked

AWS's version works because `aws ce get-cost-and-usage` is an always-on, queryable-anytime API.
Checked live: GCP has no direct `gcloud` equivalent — the standard mechanism (Cloud Billing export
to BigQuery) is a one-time, Console-only, billing-account-level setup step that has to happen
*before* there's any exported data to query, unlike AWS's Cost Explorer which works retroactively.
Not built this pass since nothing's been applied yet and there's nothing to confirm-zero on;
documented in `terraform/gcp/README.md` as a prerequisite to set up before the first real
apply/destroy cycle on this cloud, not after.

## Done — built the GCP k8s deploy overlay (mirrors AWS's later "task #8" phase)

User asked for the remaining AWS-parallel pieces: `k8s/deploy-gcp.sh`/`teardown-gcp.sh`,
`k8s/api-gcp.yaml`/`storageclass-gcp.yaml`/`traefik-gcp.yaml`, plus the Terraform-side pieces
those scripts need (Artifact Registry, the GKE PD CSI driver addon). Built all of it in one pass:

- **`terraform/gcp/artifact-registry.tf`** — two repos (api/frontend), 5-image `KEEP` cleanup
  policy each, mirroring `ecr.tf`. One real finding: `google_artifact_registry_repository` has no
  `force_delete`-equivalent attribute at all (checked via `terraform providers schema`, not
  assumed) — Google's own docs phrasing suggests deleting a repo deletes its contents too, unlike
  ECR which refuses a non-empty repo outright, but this isn't live-confirmed. First draft of this
  file included a confusing dead `count = 0` placeholder resource reasoning through the same
  question inline — caught in self-review and replaced with a plain comment before it was ever
  committed.
- **`gke.tf`**: added `addons_config.gce_persistent_disk_csi_driver_config.enabled = true`,
  declared explicitly per this project's standing "declare load-bearing defaults" rule even though
  checked live (web search) that it's already GKE's own implicit default for this cluster's
  version — the direct equivalent of AWS's `aws_eks_addon "ebs_csi_driver"`.
- **`outputs.tf`**: added Artifact Registry repo URLs, and Memorystore host/port extracted from
  `google_memorystore_instance.main.endpoints`' actual nested structure (confirmed via
  `terraform providers schema`, not the deprecated `discovery_endpoints`/`psc_auto_connections`
  attributes) so `deploy-gcp.sh` doesn't have to parse that nesting itself.
- **`k8s/storageclass-gcp.yaml`**: XFS (not the CSI driver's ext4 default), proactively — the same
  Kafka `lost+found` bug AWS found live 2026-09-18 applies identically here, so this isn't a new
  finding, it's a transferred one. Marked default; **a real GCP-specific wrinkle with no AWS
  equivalent**: GKE, unlike EKS, ships its own default StorageClass (`standard-rwo`) at cluster
  creation, so `deploy-gcp.sh` has to explicitly un-default it first, or two StorageClasses would
  both carry `is-default-class`.
- **`k8s/traefik-gcp.yaml`**: LoadBalancer Service variant, structurally identical to
  `traefik-aws.yaml` minus kind's hostPort/nodeSelector plumbing.
- **`k8s/api-gcp.yaml`**: `memory: 1Gi` from the start (not kind's `512Mi`) — AWS's identical
  OOM finding transferred proactively, same reasoning as the XFS choice.
- **`k8s/deploy-gcp.sh`** / **`k8s/teardown-gcp.sh`**: full mirrors of the AWS scripts' structure
  and reasoning (Cloud SQL private IP + Memorystore endpoint wired directly, no proxy sidecar;
  `--platform linux/amd64` build flag for the same Apple-Silicon-vs-x86_64-nodes mismatch AWS hit;
  poll-don't-sleep waits for the real LB/disks to disappear before green-lighting
  `terraform destroy`). One real bug caught before it shipped: the disk-cleanup polling loop
  originally used `gcloud compute disks describe --zone "$ZONE"` with the cluster's single
  control-plane zone — wrong, since Kafka's 3 nodes spread across all 3 zones in
  `gke_node_locations`, so a disk could legitimately live in a zone that `--zone` flag would never
  find it in. Fixed by switching to zone-less `gcloud compute disks list --filter`.

**Everything syntax-checked and live-smoke-tested where practical** (`bash -n` on both scripts;
individual `gcloud`/`terraform` command patterns run against this real, still-empty project to
catch flag/command errors) — **but none of it has run against an actual cluster**, since
`terraform/gcp/` is still plan-only. This is a materially different confidence level than AWS's
now-battle-tested scripts, and said so explicitly in the README rather than implied equivalence.
Known transferable AWS bugs (XFS, `--platform`, 1Gi memory) were applied proactively rather than
left to be rediscovered; what's still genuinely unverified is documented in
`terraform/gcp/README.md`'s new "Deploy overlay: built but genuinely untested" section.

## Open

- **Both `terraform/gcp/bootstrap/` and `terraform/gcp/` are plan-only** — no real GCP resources
  exist yet from this work, and no cost is accruing on the GCP side. `.terraform/`,
  `.terraform.lock.hcl`, and no `terraform.tfstate` beyond what `terraform init`/`plan` created
  locally.
- **No `backend.tf` for the main config yet** — deliberately deferred until `bootstrap/` is
  actually applied (a real, later, separate user decision), matching the AWS track's own
  chronology exactly.
- **k8s deploy overlay is built but genuinely untested against a real cluster** — see the "Done"
  section above and `terraform/gcp/README.md`'s "Deploy overlay: built but genuinely untested".
  Nothing here has AWS's live-debugged confidence level yet.
- **No `check-costs.sh` for GCP** — needs a one-time Cloud Billing-export-to-BigQuery setup first
  (Console-only); not a script gap, a genuine GCP-vs-AWS mechanism difference. See
  `terraform/gcp/README.md`'s "No `check-costs.sh` yet" section.
- Carried over, untouched: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost measurement fix,
  `docs/testing-expansion-scope.md`'s build order (paused at task #9 since 2026-09-10), Azure
  Terraform config (still fully unstarted).

## Next

1. User decision: apply `terraform/gcp/bootstrap/` for real (free, GCS-only), wire up
   `backend.tf`, then decide whether/when to apply the main config for real — same two-stage
   pattern AWS went through, whenever ready to spend real trial credit on it. Set up the Cloud
   Billing BigQuery export before that first real apply, not after.
2. Once applied: run `deploy-gcp.sh` and expect to live-debug it, same as AWS's first real
   `deploy-aws.sh` run — then `check-resources.sh`, a live functional pass through the app's real
   endpoints (mirroring AWS's task #15), and `teardown-gcp.sh` to confirm the two-script cycle
   actually works end-to-end.
3. Azure Terraform config, last in the AWS-first sequencing.
4. Longer-carried items: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost fix,
   `docs/testing-expansion-scope.md` task #9+.
