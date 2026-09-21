# terraform/gcp

Provisions the GCP infrastructure `grid-meter-app` would run on in the cloud: a custom-mode VPC,
a GKE cluster + managed node pool, a managed Cloud SQL PostgreSQL instance, and a managed
Memorystore for Valkey instance. **Infrastructure only** — deploying the app onto the cluster
(a future `k8s/deploy-gcp.sh`, Artifact Registry image build/push, GCP-specific k8s manifest
variants) is out of scope for this pass, mirroring how `terraform/aws/`'s k8s overlay was a
separate follow-up after its own infra-only pass.

See `docs/cloud-deployment-scope.md` for the full per-layer reasoning (why Postgres/Redis are
managed here but Kafka is self-hosted in-cluster identically across every target — `kind`, AWS,
and this).

## Status: applied — real GCP infrastructure is live

**Real apply happened 2026-09-21** (user-run, same pattern as AWS — Claude Code's own auto-mode
classifier blocks `terraform apply` against real infrastructure, and every real apply on this
project has been run by the user via the `!` prefix, never by Claude Code itself). `bootstrap/`
applied first (the GCS state bucket), `backend.tf` wired up from its output, then the main config
applied in two passes: 19 resources, 2 failures on the first pass (see "Real findings" below for
both — Cloud SQL's edition default and Memorystore's missing service connection policy), fixed
and the remaining 5 applied clean on the second pass. Full stack now live: VPC, GKE cluster + node
pool, Cloud SQL, Memorystore, Artifact Registry, Secret Manager.

**A third real bug was caught only after this — by running `check-resources-gcp.sh` against the live
apply, not by `terraform plan`**: `gke_node_count`'s default of 3 was meant as "3 total, 1 per
zone" but GKE's own `node_count` semantics are per-zone for a multi-zone node pool, so it actually
created **9 real e2-medium instances, not 3** — roughly 3x the intended compute cost, running from
first apply until caught. See "Real findings" below for the fix and the corrected value (1, not
3). **Fixed and applied the same session** — `check-resources-gcp.sh` re-run afterward confirmed
exactly 3 real instances live, one per zone, 17/17 checks passing. This is the sharpest instance
yet of this project's own standing "verify the live system" discipline actually catching something
real: neither `terraform plan` nor `terraform validate` at any point surfaced this, since the
resource's field is genuinely correct HCL, just misunderstood sizing math on my part - a real,
live resource *count* was the only place this was ever going to be visible, and only a second live
check (not just trusting the fix's "Apply complete") confirmed it actually landed.

## Prerequisites

1. `gcloud auth login` (authenticates the CLI) **and** `gcloud auth application-default login`
   (separately authenticates Terraform's Google provider via Application Default Credentials) —
   both are required; the first alone is not enough for `terraform plan`/`apply` to work.
2. A GCP project with billing linked (this pass uses `project-4c5a8821-da4c-4c68-97f`, this
   account's auto-created "My First Project", kept rather than creating a fresh dedicated one).
3. APIs enabled on that project (done live this session, all free/no-cost operations):
   `compute`, `container`, `sqladmin`, `redis`, `memorystore`, `servicenetworking`, `iam`,
   `cloudresourcemanager`, `secretmanager`, `artifactregistry`.
4. Terraform >= 1.11.0 (this dev machine runs 1.13.2).
5. `kubectl` installed, for interacting with the cluster once it exists.

## What this creates (once applied)

| Resource | Sizing | Replaces (locally) | AWS equivalent |
|---|---|---|---|
| VPC (custom mode), 1 subnet + secondary ranges, Cloud Router/NAT | — | — | VPC, 3 AZs, 1 NAT gateway |
| GKE cluster (zonal control plane) + managed node pool | 3x `e2-medium`, one per zone across 3 zones (fixed size, no autoscaling) | The `kind` cluster | EKS, 3x `t3.medium` |
| Cloud SQL PostgreSQL | `db-f1-micro`, zonal (not regional HA), 20GB PD-SSD | Self-hosted Patroni + Consul | RDS `db.t4g.micro` |
| Memorystore for Valkey | `SHARED_CORE_NANO`, `CLUSTER_DISABLED` (single shard) | Self-hosted Redis + Sentinel | ElastiCache `cache.t4g.micro` |
| Secret Manager secret | Cloud SQL's generated password | — | RDS's `manage_master_user_password` (Secrets Manager) |
| Artifact Registry (api + frontend repos) | 5-image `KEEP` cleanup policy each | `kind load docker-image` | ECR |
| GCE Persistent Disk CSI driver addon (declared explicitly in `gke.tf`) | — | `local-path-provisioner` | EBS CSI driver addon |
| — (Metrics Server ships pre-installed on GKE Standard) | — | — | `metrics-server` EKS addon |

**k8s deploy overlay now built too** (`k8s/deploy-gcp.sh`/`teardown-gcp.sh`,
`k8s/storageclass-gcp.yaml`, `k8s/traefik-gcp.yaml`, `k8s/api-gcp.yaml`), mirroring AWS's later
"task #8" phase — see "Deploy overlay: built but genuinely untested" below for the important
caveat this carries that AWS's equivalent script no longer does.

Kafka is **not** created here — it stays self-hosted in-cluster (see `k8s/kafka.yaml`), same
decision and reasoning as the AWS track.

**Observability is not part of this deployment**, same deliberate split as AWS: `kind` remains the
load-test/dashboard demo track; this demonstrates Terraform/cloud-native provisioning capability
only.

## Real findings from this pass, live-checked rather than assumed

- **GKE**: `REGULAR` release channel's current default is `1.35.8-gke.1036000` (checked via
  `gcloud container get-server-config --region us-central1`, 2026-09-21).
- **Cloud SQL**: `POSTGRES_18` is directly supported (checked via `gcloud sql instances create
  --help`'s `--database-version` enum) — matches this project's pinned version exactly, the same
  clean result AWS's RDS check found.
- **Memorystore — a real, direct parallel to the AWS ElastiCache finding**: GCP's legacy
  "Memorystore for Redis" product (`google_redis_instance`) tops out at Redis **7.2**, with no
  8.x/9.x offered at all (checked via `gcloud redis instances create --help`'s `--redis-version`
  enum). The current path past that is a separate, newer product — **Memorystore for Valkey**
  (`google_memorystore_instance`, `gcloud memorystore` command group), supporting Valkey 7.2/8.0/
  9.0/9.1 (9.1 still Preview). Chosen: **9.0**, the current GA default — same "newest available,
  not experimental" reasoning as AWS's Valkey 9.1 pick, adjusted for what's actually GA here.
  Proceeded directly with Valkey by analogy to that AWS decision rather than re-asking for
  sign-off on what's structurally the same choice a second time.
- **Cloud SQL has no RDS-style `manage_master_user_password`** — GCP's idiomatic substitute
  (`random_password` + Secret Manager, wired up in `cloudsql.tf`) is more manual than AWS's
  single-flag convenience, worth knowing going in rather than discovering mid-build.
- **Memorystore for Valkey's networking model is Private Service Connect** (an auto-created PSC
  endpoint per instance), genuinely different from Cloud SQL's classic VPC-peering "Private
  Service Access" — two different GCP private-connectivity generations coexisting in this same
  config, not an inconsistency to resolve.
- **Region**: `us-central1` confirmed (via web search against current GCP pricing sources,
  2026-09-21) as GCP's baseline/cheapest pricing tier — the same reasoning behind AWS's
  `us-west-2` choice.
- **This account has no billing account or GCP project with billing linked as of session start**
  — both required manual setup (payment method via the Console, `gcloud auth
  application-default login`) before any of this could be planned, let alone applied. See
  `status/claude_code_2026-09-21.md` for the full walkthrough.

### Real findings from the actual apply, not from plan/validate

Three real bugs, none visible from `terraform plan`/`validate` — only from a genuine `apply`
against this project:

- **Cloud SQL `edition` is `optional, computed`, and this account's implicit default resolved to
  `ENTERPRISE_PLUS`, which rejects `db-f1-micro` outright** — `Error 400: Invalid Tier
  (db-f1-micro) for (ENTERPRISE_PLUS) Edition`. Another live instance of this project's own
  standing "declare load-bearing defaults explicitly" lesson (CLAUDE.md) - fixed by declaring
  `edition = "ENTERPRISE"` in `cloudsql.tf`, the classic edition that actually supports
  shared-core tiers.
- **Memorystore for Valkey's PSC auto-connection needs an explicit
  `google_network_connectivity_service_connection_policy` to exist first** —
  `desired_auto_created_endpoints` alone isn't enough; without a policy for this
  region/network/`service_class = "gcp-memorystore"` combination, creation fails with "No service
  connection policy is associated with project...". Added to `network.tf`, with
  `google_memorystore_instance.main` now `depends_on` it.
- **The sharpest one: `gke_node_count`'s original default (3) actually created 9 real nodes, not
  3** — GKE's `node_count` on a multi-zone node pool is per-zone, not total
  (`total = node_count × len(node_locations)`), confirmed against GKE's own documented behavior
  only after `check-resources-gcp.sh` (run against the real live apply) showed 9 GCE instances where 3
  were expected. `terraform plan`/`validate` never had a chance to catch this - the HCL was
  syntactically and semantically valid the whole time, just multiplying out to a number I hadn't
  intended. Fixed: `gke_node_count` default changed from 3 to 1 (`variables.tf`), so 1 × 3 zones =
  3 total, matching the intended AWS-parity sizing. Ran actively over-provisioned (and
  over-billing, roughly 3x the intended `e2-medium` compute cost) from the first successful apply
  until this was caught and corrected the same session.
- **A fourth, smaller bug caught the same way**: `check-resources-gcp.sh`'s GCE-instance check
  originally filtered on a regex against the full cluster/node-pool name
  (`name~^gke-${CLUSTER_NAME}-`) - GCE truncates instance names at 63 characters, so real instance
  names came out as `gke-grid-meter-app-g-grid-meter-app-n-<hash>-<suffix>` (both
  `grid-meter-app-gke` and `grid-meter-app-nodes` silently truncated), never matching the regex at
  all. Fixed by filtering on GKE's own `goog-k8s-cluster-name` label instead - stable, not
  truncated, and present on every GKE-managed instance.

## Deploy overlay: built but genuinely untested

`k8s/deploy-gcp.sh`/`teardown-gcp.sh`, `k8s/storageclass-gcp.yaml`, `k8s/traefik-gcp.yaml`,
`k8s/api-gcp.yaml` are all written and syntax-checked (`bash -n`, plus live `gcloud`
command/flag smoke tests against this real project where practical), but **none of it has run
against a real cluster** — `terraform/gcp/` is still plan-only, so there's nothing to deploy onto
yet. This is a materially different confidence level than AWS's equivalent scripts, which were
live-debugged through 6 real bugs (fsGroup, image-arch mismatch, a stuck StatefulSet rollout, an
OOM-sized memory limit, ext4's `lost+found` breaking Kafka, node overcommitment) before they
worked cleanly — see `status/claude_code_2026-09-18.md`.

**Known, directly-transferable AWS findings were applied proactively rather than left to be
rediscovered**: `k8s/storageclass-gcp.yaml` uses XFS (not the GCE PD CSI driver's ext4 default) to
sidestep the exact same Kafka `lost+found` bug AWS hit; `k8s/deploy-gcp.sh` builds images with
`--platform linux/amd64` for the same Apple-Silicon-build-host-vs-x86_64-node-pool mismatch AWS
hit; `k8s/api-gcp.yaml` starts at `memory: 1Gi`, not kind's `512Mi`, for the same JVM-startup-
footprint OOM AWS hit. One genuine GCP-specific step with no AWS equivalent: `deploy-gcp.sh`
explicitly un-defaults GKE's own built-in `standard-rwo` StorageClass before applying the XFS one,
since (unlike EKS, which ships with no default at all) GKE auto-marks one at cluster creation, and
two StorageClasses can't both carry `is-default-class` without an ambiguous result.

**What's still genuinely unverified**: which exact GCP load-balancer resource type a plain
`type: LoadBalancer` Traefik Service resolves to (`teardown-gcp.sh` queries forwarding rules by IP
specifically to sidestep needing to guess — AWS's own identical assumption, "it'll be an NLB",
turned out wrong when finally checked live); whether Artifact Registry's `terraform destroy`
behavior on a non-empty repo needs a `force_delete`-equivalent flag the way ECR does (checked the
provider schema — no such attribute exists — but not live-confirmed the way AWS's finding was);
and the entire live functional path (does the app actually serve traffic end-to-end through Cloud
SQL/Memorystore/Kafka) that AWS's task #15 validated directly against real endpoints. Treat a
first real run of `deploy-gcp.sh` the way AWS's first real `deploy-aws.sh` run was treated: expect
to live-debug, not expect it to work first try.

## Inspection script

`check-resources-gcp.sh` — the GCP counterpart to `terraform/aws/check-resources-aws.sh`: confirms every
Terraform-provisioned resource actually exists and is healthy via real `gcloud` calls, not
`terraform apply`'s own "Apply complete" message. Now covers the full stack this pass creates,
including Artifact Registry — the only section still missing relative to AWS's script is Workload
Identity/IAM, since this build doesn't need pod-level GCP IAM bindings yet.

**Already live-tested once, before any real resource existed** — run against this real, currently-
empty project on 2026-09-21 specifically to catch command/flag bugs early, not resource-health
bugs (nothing exists yet to be healthy). Found and fixed two real issues this way: `gcloud compute
networks subnetworks describe` isn't a valid command (`subnets`, not `subnetworks`) — a plain usage
error the smoke test surfaced immediately; and `gcloud compute instances list` with zero filter
matches exits **0** with an empty-match warning on stderr rather than failing — a bare exit-code
check would have read that as a false PASS with no real value behind it. Fixed by requiring both a
zero exit code AND non-empty stdout, with stdout/stderr captured separately so a
successful-but-empty result can't read as a real value either way — the same false-PASS shape
AWS's own `k8s/check-resources-aws.sh` found the hard way (2026-09-18), caught here before a live
resource ever existed to hide behind.

## No `check-costs-gcp.sh` yet — GCP has no direct CLI equivalent

AWS's `check-costs-aws.sh` works because `aws ce get-cost-and-usage` is an always-on, queryable-anytime
API. GCP has no equivalent built into `gcloud` — the standard mechanism (a Cloud Billing export to
a BigQuery dataset) has to be configured once, in advance, as a billing-account-level setting
(Console-only; no `gcloud` command creates the export itself), before there's any exported data to
query at all. Not built this pass since nothing has been applied yet and there's no cost to
confirm-zero on; worth setting up before the first real `apply`/`destroy` cycle on this cloud, not
after, so the export has data by the time a delayed cost check would actually be run (mirrors
`check-costs-aws.sh`'s own documented 24-48h Cost-Explorer-lag limitation, just with an extra
one-time setup step GCP requires that AWS didn't).

## Usage

```bash
cd terraform/gcp
terraform init
terraform fmt
terraform validate
terraform plan -out tfplan
terraform apply tfplan   # run by the user, never Claude Code - see "Status" above
```

## Remaining before the k8s deploy overlay can actually be exercised

1. Set up a Cloud Billing export to BigQuery (Console-only, one-time, per billing account) - see
   "No `check-costs-gcp.sh` yet" above. Not done yet; do this before the next `terraform destroy` if a
   delayed cost cross-check is wanted.
2. Run `k8s/deploy-gcp.sh` against this now-live cluster and expect to live-debug it - see "Deploy
   overlay: built but genuinely untested" above.
3. Confirm current free-trial credit balance periodically while this stays up - GKE nodes, Cloud
   SQL, and Memorystore are all real, billed infrastructure now (no meaningful Always-Free
   coverage at this sizing, same as AWS's ElastiCache/RDS/EKS-node costs).
