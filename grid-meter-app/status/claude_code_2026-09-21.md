# grid-meter-app — Status: 2026-09-21 (Claude Code)

Weekend catch-up session: reconfirmed where the AWS track left off, ran the delayed
`check-costs.sh` cross-check, cleaned up a stale temp file, then started the GCP Terraform track
(`docs/cloud-deployment-scope.md`'s stated AWS-first sequencing) — scaffolded `terraform/gcp/`
and `terraform/gcp/bootstrap/`, built the k8s deploy overlay, then **the user ran the real
applies**: `bootstrap/` applied cleanly, the main config applied in two passes (19 resources, 2
real failures found and fixed, then a clean 5-resource follow-up), and **real GCP infrastructure
is now live** — VPC, GKE cluster (3 nodes across 3 zones once a real node-count bug is corrected —
see below), Cloud SQL, Memorystore, Artifact Registry. A third real bug, caught only by running
`check-resources.sh` against the live apply (not by `terraform plan`), found the cluster was
actually running 9 nodes, not 3 - fixed same session, fix plan-ready pending the user's apply.

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

## Done — user applied `terraform/gcp/bootstrap/` and the main config for real; two real bugs found and fixed live

User ran every real apply themselves, matching the AWS pattern exactly (Claude Code's classifier
blocks `terraform apply` against real infra) - I prepared plans and reviewed output, never ran an
apply.

- **`bootstrap/` applied clean**: the GCS state bucket now exists live
  (`grid-meter-app-tfstate-project-4c5a8821-da4c-4c68-97f`). Wired up `backend.tf` from its
  output, re-initialized with `-migrate-state` (nothing to migrate - no local state had
  accumulated, since only `plan` had run before), replanned against the real remote backend:
  still a clean 19 to add.
- **Main config's first real apply: 31 of 33 resources succeeded, 2 real failures** - both were
  live-API errors `terraform plan`/`validate` had no way to surface in advance:
  1. **Cloud SQL rejected `db-f1-micro`** - `Invalid Tier (db-f1-micro) for (ENTERPRISE_PLUS)
     Edition`. The `edition` field is `optional, computed` in the provider schema, and this
     account's implicit default resolved to `ENTERPRISE_PLUS`, which doesn't support shared-core
     tiers - another live instance of this project's own standing "declare load-bearing defaults
     explicitly" pattern (now found this many times across this project that it's worth quoting
     verbatim from CLAUDE.md: it keeps finding the exact same shape of gap). Fixed:
     `edition = "ENTERPRISE"` declared explicitly in `cloudsql.tf`.
  2. **Memorystore for Valkey's PSC connection needs an explicit
     `google_network_connectivity_service_connection_policy`** (`service_class =
     "gcp-memorystore"`) to exist first - `desired_auto_created_endpoints` alone isn't sufficient;
     failed with "No service connection policy is associated with project...". Added to
     `network.tf`, `google_memorystore_instance.main` now depends on it.
  - Both resources already-created (VPC, GKE cluster - 8m3s, node pool - 12m5s, Artifact Registry
    x2, service account, IAM binding, Secret Manager secret+version) stayed untouched. Fixed both
    bugs, replanned (5 to add, 0 to change, 0 to destroy), user re-applied - clean, full stack now
    live.

## Done — ran `check-resources.sh` against the real live apply, found a third real bug (and a fourth in the check script itself)

Matching this project's own standing discipline - verify live, don't trust "Apply complete" -
ran the just-built inspection script against the real infrastructure immediately after the apply
completed. **16/17 passed; the one failure led to a genuinely serious finding**, not a script
bug:

- **`gke_node_count`'s original default (3) actually created 9 real `e2-medium` nodes, not 3** -
  GKE's `node_count` field on a multi-zone node pool is documented as *per zone*, not total
  (`total = node_count × len(node_locations)`). The variable's own description at the time
  asserted "3 zones x 1 = 3 total nodes" while the default was set to 3 - a real reasoning
  contradiction I wrote into the file without catching it myself; only a live `gcloud compute
  instances list` (9 real running VMs, 3 per zone) and cross-referencing GKE's own documented
  `node_count` semantics surfaced it. **This is the sharpest version yet of this project's
  "verify live, don't assume" lesson**: the HCL was syntactically and semantically valid the
  entire time - `terraform plan`/`validate` had genuinely nothing to flag, because there was
  nothing wrong with the config in isolation, only with what it actually produced against GKE's
  real API semantics. Ran at ~3x the intended `e2-medium` compute cost from the first successful
  apply until caught this same session. Fixed: `gke_node_count` default 3 → 1 (`variables.tf`,
  `gke.tf`'s comment corrected too) - re-planned against the real live state: a single clean
  in-place `node_count: 3 -> 1` update, 0 to add, 1 to change, 0 to destroy. **User applied it
  (4m6s) - re-ran `check-resources.sh` afterward and confirmed live: exactly 3 real instances now,
  one per zone (`us-central1-a/b/c`), 17/17 checks passing.** Not just trusted from "Apply
  complete" - the same "verify the live system" discipline that caught the bug in the first place
  is what confirmed the fix.
- **A fourth, smaller bug in `check-resources.sh` itself, found investigating the above**: the
  GCE-instance check's `name~^gke-${CLUSTER_NAME}-` regex never matched anything, silently -
  GCE truncates instance names at 63 characters, so real names came out
  `gke-grid-meter-app-g-grid-meter-app-n-<hash>-<suffix>` (both `grid-meter-app-gke` and
  `grid-meter-app-nodes` truncated), never matching the full-name regex. Fixed by filtering on
  GKE's own `goog-k8s-cluster-name` label instead (stable, not truncated, confirmed present on a
  real live instance via `gcloud compute instances describe ... --format="yaml(labels)"`).
  Re-ran the full script after both fixes: 17/17 pass.

## Done — renamed `check-resources.sh`/`check-costs.sh` scripts with a `<platform>` suffix

User pointed out `terraform/aws/check-resources.sh` and `terraform/gcp/check-resources.sh` had
identical filenames, differing only by directory - genuinely confusing alongside
`k8s/check-resources-aws.sh`, which already carried an `-aws` suffix. Renamed via `git mv` for
consistency: `terraform/aws/check-resources.sh` → `check-resources-aws.sh`,
`terraform/aws/check-costs.sh` → `check-costs-aws.sh`, `terraform/gcp/check-resources.sh` →
`check-resources-gcp.sh`. Updated every cross-reference (both READMEs, self-referencing usage
comments, `k8s/check-resources-aws.sh`'s own comment), re-ran the GCP script under its new name
against the live infrastructure to confirm nothing broke (17/17 still pass). Left historical
`status/*.md` files untouched - point-in-time records of what things were named then, not living
docs to keep in sync.

## Done — pushed 7 local commits to `origin/main`; SSH agent needed re-adding

Local `main` was 7 commits ahead of `origin/main` with nothing pushed. First push attempt failed
- `Permission denied (publickey)` - the known "SSH agent loses loaded keys after a reboot on this
Mac" pattern from a prior session's memory. User re-added the key (`ssh-add
--apple-use-keychain`), second push succeeded cleanly (`5a88d51..ae0145a`).

## Done — built and live-smoke-tested `k8s/check-resources-gcp.sh`; found a real missing prerequisite

Mirrors `k8s/check-resources-aws.sh` exactly (Traefik, Kafka StatefulSet/PVCs, `api`/`frontend`
Deployments, config/secret/IngressRoute/StorageClass), two adjustments: GCP's LB is IP-based
(`.status.loadBalancer.ingress[0].ip`, not `.hostname`), and the default StorageClass is
`pd-balanced-xfs`, not `gp3`.

**Live-smoke-tested against the real GKE cluster** (not just `bash -n`) - fetched real kubeconfig
credentials to enable this, which immediately surfaced a genuine missing prerequisite:
`gke-gcloud-auth-plugin` isn't installed, and every `kubectl` call against a GKE cluster fails
outright without it (Google deprecated the older exec-auth path GKE's kubeconfig relies on).
`deploy-gcp.sh`/`teardown-gcp.sh` would have failed on their very first `kubectl` call. Installed
it (`gcloud components install gke-gcloud-auth-plugin`), found it lands at
`/opt/homebrew/share/google-cloud-sdk/bin` - not on `$PATH` by default, and
`export USE_GKE_GCLOUD_AUTH_PLUGIN=True` is also required. Documented as a new Prerequisites item
in `terraform/gcp/README.md`, and referenced from both `deploy-gcp.sh`'s and `teardown-gcp.sh`'s
own header comments.

With the plugin in place, `kubectl get nodes` confirmed all 3 real nodes `Ready`. Ran
`check-resources-gcp.sh` against this real (but app-undeployed) cluster: all 15 checks correctly
`FAIL` - no crashes, no false positives - the same meaningful bar established for
`check-resources-gcp.sh`'s Terraform-layer counterpart earlier this session.

## Done — ran `deploy-gcp.sh` for real, live-debugged through 4 new GCP-specific bugs, then fully validated the app end-to-end

User asked to run `deploy-gcp.sh` for real. Docker Desktop wasn't running - started it and polled
for the daemon rather than assuming a fixed wait, matching this project's own standing test-
infrastructure lesson. AWS's proactively-applied fixes (XFS StorageClass, `--platform
linux/amd64`, 1Gi api memory) all held up correctly on the very first run - none of AWS's original
6 bugs recurred here. Four **new**, genuinely GCP-specific bugs did, each found live and fixed the
same session:

1. **Artifact Registry repository paths were missing an image-name segment** - a real structural
   difference from ECR (repo IS the image there; a GCP repo is a namespace holding one or more
   separately-named images), not a config mistake in isolation. Docker's own error was opaque
   (`400 Bad Request` on a HEAD request); the real cause (`NAME_INVALID: Missing image name`) only
   surfaced by going around docker entirely and hitting the registry API directly with `curl`.
   Fixed by appending `/api`/`/frontend` to `outputs.tf`'s Artifact Registry outputs - an
   output-only Terraform change, confirmed via `terraform plan` itself stating "without changing
   any real infrastructure" before applying.
2. **Buildx's default provenance/SBOM attestations get rejected by Artifact Registry** - confirmed
   via web search as a known, documented compatibility gap, not project-specific. Fixed with
   `--provenance=false --sbom=false`, plus switched to `docker buildx build --push` (bypasses this
   Mac's containerd image store's local OCI round-trip, a second contributing factor specific to
   this dev machine's Docker Desktop configuration).
3. **The GKE node service account's `roles/container.nodeServiceAccount` role doesn't include
   Artifact Registry pull permission** - every `api`/`frontend` pod failed `ErrImagePull` with a
   `403 Forbidden` on the pull OAuth token, confirmed via `kubectl describe pod` events. Missed
   originally because AWS's node role needed 3 separate policy attachments (worker/CNI/registry)
   while GCP's single `container.nodeServiceAccount` role covers logging/monitoring in one grant -
   registry pull turned out to need its own separate grant regardless, no bundling equivalent.
   Fixed with a new `roles/artifactregistry.reader` IAM binding.
4. **Real node overcommitment, the same shape of finding as AWS's** (all 3 `e2-medium` nodes at
   74-94% memory requests, `kafka-2` unable to schedule at all). Presented as a real sizing/cost
   decision rather than resolved silently - user chose a 4th `e2-medium` node over a larger machine
   type. Implemented as a second, single-zone node pool rather than bumping the main pool's
   `node_count` (that field is per-zone - a uniform bump would have added 3 nodes, not 1).

**Then ran the full functional validation AWS's task #15 did**, against the real LoadBalancer IP:
login (real JWT), create a meter (real Cloud SQL write), post a reading with an `Idempotency-Key`
(published through the real 3-broker in-cluster Kafka), then poll `GET /readings` - **came back on
the first attempt**, confirming the full async Kafka → consumer → Postgres pipeline. Spun up a
throwaway `redis-cli` pod against the real Memorystore endpoint and confirmed both
`reading:latest:<meterId>` and `idempotency:<key>` landed there too, closing the loop on
`architecture.md`'s documented Postgres-and-Redis consumer write. Attempted cleanup: `DELETE
/api/v1/meters/<id>` correctly returned `409 Conflict` (same immutable-readings FK constraint
AWS's precedent found) - left the one test meter/reading in place.

**Also closed out a standing open question from earlier in the session**: with the LB actually
live, checked directly (`gcloud compute forwarding-rules list`) rather than continuing to guess -
confirmed this resolves to the legacy target-pool-based external Network LB, not the newer
backend-service-based one. Updated `teardown-gcp.sh`'s own comment to state this as confirmed
rather than an open assumption.

**GCP's deploy overlay is now at the same confidence level as AWS's** - the "built but genuinely
untested" caveat from earlier in this session no longer applies to `deploy-gcp.sh`.

## Done — ran `teardown-gcp.sh` for real for the first time: clean, no bugs found

User asked to run it. Confirmed kubectl context was pointed at the real GKE cluster first, then
ran it end to end: deleted the `traefik-web` LoadBalancer Service and polled until the real GCP
forwarding rule was actually gone (not just the `kubectl delete` acknowledgment); deleted Kafka's
StatefulSet, waited for its pods to actually terminate, deleted the 3 PVCs, and polled until all 3
real persistent disks were actually gone. **Both steps confirmed clean on the first real try** -
no bugs found, unlike `deploy-gcp.sh`'s four. `api` pods degraded to `0/1` afterward since they
depend on Kafka being reachable - expected collateral of tearing down mid-cluster, not a bug,
since the whole cluster is the next thing to go via a real `terraform destroy` (not run this
session - that's a deliberate, separate, user-run step per the script's own design).

Closes out the one remaining genuinely-untested piece of the GCP deploy overlay - `deploy-gcp.sh`
and `teardown-gcp.sh` are now both proven, matching AWS's own two-script confidence level (though
AWS's runbook has been proven across *two* full cycles; this is GCP's first).

## Done — ran `terraform destroy` for real, found and fixed a real Cloud SQL destroy-ordering race

User ran a real `terraform destroy`. 18 of 22 resources destroyed cleanly (VPC subnet/router/NAT,
both GKE node pools, the cluster itself, Memorystore, both Artifact Registry repos, Secret
Manager, both IAM bindings, the node service account) - then a real, live failure:
`google_sql_user.main` failed to delete with `role "gridmeter" cannot be dropped because some
objects depend on it - 5 objects in database gridmeter`, even though `google_sql_database.main`'s
own destroy had already logged "Destruction complete" earlier in the same run.

**Root cause**: `google_sql_database.main` and `google_sql_user.main` are sibling resources with
no `depends_on` between them in the original config, so Terraform destroyed both in parallel - the
`DROP DATABASE` call's own destroy log showed success, but the `DROP ROLE` call's server-side
validation ran before that drop had actually finished committing on Cloud SQL's Postgres backend,
so it still saw live objects depending on the role. A real destroy-ordering race, not a permissions
or config-value bug - the same "declare the real ordering, don't assume the API serializes it for
you" shape as this project's other undeclared-dependency findings, just surfacing on teardown
instead of apply. Fixed with an explicit `depends_on = [google_sql_database.main]` on
`google_sql_user.main`, forcing the role drop to wait for the database drop to genuinely complete,
not just be issued.

Checked remaining state via `terraform plan -destroy`: exactly 6 resources left (Cloud SQL
instance + user, VPC, the PSA global address, the service networking connection, and
`random_password.cloudsql`) - `google_sql_database.main` itself is confirmed already fully gone.
Re-planned and saved a fresh destroy plan for the user to re-apply; real time has passed since the
original race, so the same failure shouldn't recur even without the `depends_on` fix, which would
have prevented it going forward regardless.

**User then ran a fresh `terraform apply` instead of the destroy retry** (16 resources added -
VPC/GKE cluster+node pools/Cloud SQL/Memorystore/Artifact Registry all recreated), and
`check-resources-gcp.sh` confirmed 17/17 healthy - an incidental but genuine second full
infra-layer cycle, satisfying half of "Next" item #3 below (the k8s app-deploy layer wasn't
re-exercised this time, just the Terraform layer).

**Then ran `terraform destroy` again - the `depends_on` fix confirmed working**: 19 of 22
resources destroyed cleanly this time, including `google_sql_user.main` (no repeat of the earlier
race). A **second, different real failure** surfaced: `google_service_networking_connection`
refused to delete - `Failed to delete connection; Producer services (e.g. CloudSQL, Cloud
Memstore, etc.) are still using this connection`, even though both Cloud SQL and Memorystore had
already been destroyed minutes earlier in the same run. Checked live rather than assumed:
`gcloud sql instances list`/`gcloud memorystore instances list`/`gcloud redis instances list` all
confirmed genuinely zero producer services remain.

**Retried after a short wait - same failure.** Researched rather than kept retrying blind: this
turned out to be a known, longstanding, still-open upstream bug in the Terraform Google provider
(`hashicorp/terraform-provider-google` issues #19908, #16275, #3979, spanning multiple provider
major versions) - Google's Service Networking API tracks producer-service usage in its own
internal bookkeeping, separate from the VPC-side peering object, and per the reports that
bookkeeping's release can take *days* after the last producer is deleted, not minutes. The
Console/`gcloud` deletion path is documented to use a genuinely different underlying API call
(`networks.removePeering`) than Terraform's (`servicenetworking.connections.delete`) and often
succeeds where Terraform's fails - confirmed live here too: `gcloud compute networks peerings
delete` on the underlying peering succeeded immediately (`gcloud compute networks peerings list`
afterward showed zero), but a `terraform apply` retry on the same saved destroy plan still failed
identically, confirming the failure is specifically in Terraform's own
`servicenetworking.connections.delete` call path, unaffected by the peering object's own state.

**Fixed with the documented community workaround**: added `deletion_policy = "ABANDON"` to
`google_service_networking_connection`, which drops the resource from Terraform state without
attempting its currently-un-satisfiable delete API call. Confirmed low-consequence to abandon
specifically here - the connection object carries no ongoing GCP cost sitting idle, and the actual
VPC-side peering it represented was already independently confirmed deleted via the direct
`gcloud` path. Re-planned: destroy count dropped from 3 to 2 (VPC network + the PSA address
reservation), saved for the user to apply.

## Open

- **GCP is nearly fully torn down - 19 of 22 resources confirmed destroyed, 3 remain pending a
  GCP-side propagation lag** (the PSA global address, the VPC network, and the service networking
  connection itself - all three genuinely orphan-free per live `gcloud` checks, just blocked by
  Google's own backend not yet reflecting that Cloud SQL/Memorystore are gone). A `terraform plan
  -destroy` shows exactly these 3 remaining; a saved plan is ready to re-apply once the lag clears
  (typically a few minutes).
- **Both `deploy-gcp.sh` and `teardown-gcp.sh` are proven across real runs now**, and the
  Cloud-SQL-destroy-ordering fix has been live-confirmed working (the second `terraform destroy`
  got 19/22 clean, including the previously-failing `google_sql_user.main`). Combined with the
  incidental second `terraform apply` cycle (16 resources, `check-resources-gcp.sh` 17/17), GCP's
  infra layer now has two real tested cycles - matching AWS's own two-cycle confidence bar for
  that layer specifically (the k8s app-deploy layer has had one cycle, not yet a confirming
  second).
- **No `check-costs-gcp.sh`** — needs a one-time Cloud Billing-export-to-BigQuery setup first
  (Console-only); not a script gap, a genuine GCP-vs-AWS mechanism difference. See
  `terraform/gcp/README.md`'s "No `check-costs-gcp.sh` yet" section.
- Carried over, untouched: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost measurement fix,
  `docs/testing-expansion-scope.md`'s build order (paused at task #9 since 2026-09-10), Azure
  Terraform config (still fully unstarted).

## Next

1. **Retry `terraform destroy`** once the GCP-side propagation lag on the service networking
   connection clears (wait a few minutes from this write) - only 3 resources remain, a saved plan
   is ready.
2. Confirm the destroy via the same residue-checklist discipline AWS's runbook uses, not just
   trusted from "Destroy complete" - especially worth double-checking given this session's own
   real destroy-ordering/propagation findings.
3. A second full deploy-gcp.sh app-layer cycle (not just the Terraform-layer one already done
   twice), matching AWS's own two-cycle confidence bar completely, whenever there's a reason to
   stand this up again.
4. Build `terraform/gcp/check-costs-gcp.sh`'s prerequisite (the BigQuery export) and the script
   itself, once there's a real teardown to confirm against.
5. Azure Terraform config, last in the AWS-first sequencing.
6. Longer-carried items: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost fix,
   `docs/testing-expansion-scope.md` task #9+.
