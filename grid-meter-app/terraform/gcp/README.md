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

## Status: fully torn down (2026-09-21) — applied, live-debugged, functionally validated, then destroyed clean

**Real infrastructure was applied, deployed to, functionally tested end-to-end, and torn down
again, all in this one session (2026-09-21)** — the full arc AWS's track took multiple sessions to
reach. Currently: `terraform show` reports empty state, and every resource type this pass created
was independently confirmed gone via live `gcloud` calls (not just trusted from "Destroy
complete") — VPC, GKE cluster, Cloud SQL, Memorystore, Artifact Registry, disks, forwarding rules,
the dedicated node service account. Zero residue, zero cost accruing. See "Deploy overlay" and
"Remaining" below for the full account of what was found along the way, including two genuinely
new teardown-time bugs (a Cloud SQL destroy-ordering race and a known upstream Terraform-provider
bug), both fixed and now baked into this config for the next real cycle.

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
6. **`gke-gcloud-auth-plugin`** (`gcloud components install gke-gcloud-auth-plugin`) — found
   missing live (2026-09-21) the first time `kubectl` was pointed at the real cluster: Google
   deprecated the older exec-auth path GKE's kubeconfig used to rely on directly, so without this
   plugin every `kubectl` command against a GKE cluster fails outright
   (`exec: executable gke-gcloud-auth-plugin not found`) - `deploy-gcp.sh`/`teardown-gcp.sh` would
   have failed on their very first `kubectl` call without it. Also needs
   `export USE_GKE_GCLOUD_AUTH_PLUGIN=True` in the shell (or set permanently via `gcloud config
   set` per Google's own docs), and the plugin's install location
   (`/opt/homebrew/share/google-cloud-sdk/bin` on this Mac) needs to be on `$PATH` - neither is
   automatic after `gcloud components install`.

## What this creates (once applied)

| Resource | Sizing | Replaces (locally) | AWS equivalent |
|---|---|---|---|
| VPC (custom mode), 1 subnet + secondary ranges, Cloud Router/NAT | — | — | VPC, 3 AZs, 1 NAT gateway |
| GKE cluster (zonal control plane) + 2 managed node pools | 4x `e2-medium` total - `main` pool 1/zone across 3 zones + a 4th `extra` pool node in `gcp_zone` only (fixed size, no autoscaling) | The `kind` cluster | EKS, 3x `t3.medium` |
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

## Deploy overlay: now live-debugged and functionally validated (2026-09-21)

`k8s/deploy-gcp.sh` has run for real against the live cluster, was live-debugged through 4 real
bugs (below) until it worked cleanly, and the full app was then functionally validated end-to-end
against real endpoints - the GCP counterpart of AWS's task #8-#15 arc, now at the same confidence
level.

**Known, directly-transferable AWS findings were applied proactively and held up as designed**:
`k8s/storageclass-gcp.yaml`'s XFS StorageClass, `deploy-gcp.sh`'s `--platform linux/amd64` build
flag, and `k8s/api-gcp.yaml`'s `memory: 1Gi` all worked correctly on the first real run - none of
AWS's original 6 bugs recurred here.

**Four new, genuinely GCP-specific bugs found live, all fixed the same session**:

1. **Artifact Registry repository paths are missing an image-name segment** - a real, structural
   difference from ECR (where the repository IS the image), not a bug in this project's config.
   Docker's own error was opaque (`unknown: unexpected status from HEAD request ...: 400 Bad
   Request`); the real cause only surfaced via a direct `curl GET` against the registry API:
   `NAME_INVALID: Missing image name. Pulls should be of the form docker pull
   HOST-NAME/PROJECT-ID/REPOSITORY/IMAGE`. Fixed by appending `/api` and `/frontend` to
   `outputs.tf`'s `artifact_registry_*_repository` values - Terraform output changes only, zero
   infrastructure impact, confirmed via `terraform plan`'s own "without changing any real
   infrastructure" message.
2. **Buildx's default provenance/SBOM attestations get rejected by Artifact Registry** - a
   separate 400 on the attestation manifest's own digest, after every real image layer had already
   pushed successfully. A known, documented Buildx-vs-GAR compatibility gap (confirmed via web
   search, not specific to this project). Fixed with `--provenance=false --sbom=false`, and
   switched from `docker build` + `docker push` to `docker buildx build --push` (pushes directly
   to the registry, bypassing this Mac's containerd image store's local OCI round-trip - a second,
   independent contributor to registry-push friction on this specific setup).
3. **The GKE node service account's `roles/container.nodeServiceAccount` role does not include
   Artifact Registry pull permission** - every `api`/`frontend` pod failed `ErrImagePull` with a
   `403 Forbidden` fetching the pull OAuth token (confirmed via `kubectl describe pod`'s events).
   The direct GCP equivalent of AWS's `AmazonEC2ContainerRegistryReadOnly` node-role policy
   attachment, omitted here originally since GCP's `container.nodeServiceAccount` role bundles
   logging/monitoring in a way AWS's node role needed 3 separate policy attachments for - registry
   pull turned out to need its own separate grant regardless. Fixed with a new
   `roles/artifactregistry.reader` `google_project_iam_member`.
4. **Real node overcommitment, same shape as AWS's finding**: with all 3 original `e2-medium`
   nodes at 74-94% memory *requests* already, `kafka-2` couldn't schedule at all
   ("0/3 nodes are available: 3 Insufficient memory"). Presented as a real sizing/cost decision
   rather than resolved silently, matching this project's own standing practice - **user chose a
   4th `e2-medium` node over a larger machine type**. Implemented as a second, single-zone node
   pool (`google_container_node_pool.extra`, scoped to `gcp_zone` only) rather than bumping the
   main pool's `node_count`, since that field is per-zone (see `gke_node_count`'s own comment on
   the earlier live bug this already corrected once) - a uniform bump would have added 3 nodes
   (6 total), not the 1 actually needed.

**Full functional pipeline confirmed working end-to-end against real GCP infrastructure**,
mirroring AWS's task #15 exactly: `POST /api/v1/auth/login` (real JWT), `POST /api/v1/meters`
(real Cloud SQL write), `POST /api/v1/readings` with an `Idempotency-Key` (published through the
real 3-broker in-cluster Kafka), `GET /api/v1/readings?meterId=...` (came back on the **first
poll attempt**, confirming the full async Kafka → consumer → Postgres pipeline), and a throwaway
`redis-cli` debug pod confirming both `reading:latest:<meterId>` and `idempotency:<key>` landed in
Memorystore/Valkey - closing the loop on `architecture.md`'s "consumer writes to Postgres *and*
Redis" data flow. Attempted cleanup: `DELETE /api/v1/meters/<id>` correctly returned `409
Conflict` (same immutable-readings FK constraint AWS's precedent found) - left the one test
meter/reading in place rather than force it out via a direct SQL `DELETE`.

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

## Remaining

`k8s/deploy-gcp.sh` and `k8s/teardown-gcp.sh` have both run for real (2026-09-21) - see "Deploy
overlay: now live-debugged and functionally validated" above. `terraform destroy` has also been
attempted for real: 18 of 22 resources destroyed cleanly, then a real failure -
**`google_sql_user.main` and `google_sql_database.main` are sibling resources with no ordering
between them, so Terraform destroyed both in parallel; the `DROP ROLE` call's server-side
validation ran before the `DROP DATABASE` call had actually finished committing on Cloud SQL's
backend, so it still saw "5 objects in database gridmeter" depending on the role**, even though
that database's own destroy had already logged success. Fixed with an explicit
`depends_on = [google_sql_database.main]` on `google_sql_user.main` - the same "declare the real
ordering, don't assume the API serializes it for you" shape as this project's other
undeclared-dependency findings, just surfacing on teardown instead of apply.

The ordering fix worked on retry (`google_sql_user.main` destroyed cleanly, 19 of 22 total), but
surfaced a **second, unrelated real failure**: `google_service_networking_connection` refused to
delete with the same "Producer services...still using this connection" error, even with every
Cloud SQL/Memorystore instance confirmed genuinely gone (`gcloud sql/memorystore instances list`).
This turned out to be a known, longstanding, still-open upstream bug in the Terraform Google
provider (`hashicorp/terraform-provider-google#19908`, `#16275`, `#3979`) - Google's Service
Networking API tracks producer usage in internal bookkeeping separate from the VPC-side peering
object, and that bookkeeping's release can reportedly take days, not minutes. Confirmed live that
Terraform's delete call path is genuinely different from (and less reliable than) the
Console/`gcloud`'s: `gcloud compute networks peerings delete` on the underlying peering succeeded
immediately, but a subsequent `terraform apply` retry on the connection resource still failed
identically. Fixed with the documented community workaround -
`deletion_policy = "ABANDON"` on `google_service_networking_connection` (`network.tf`) - since the
object carries no ongoing cost and the real peering it represented is already confirmed deleted.

**The re-run succeeded**: the final 2 resources (VPC, PSA global address) destroyed cleanly, and
`terraform show` confirmed empty state. Independently verified live with `gcloud` across every
resource type this pass created (VPC, GKE cluster, Cloud SQL, Memorystore, Artifact Registry,
disks, forwarding rules, the dedicated node service account) - all genuinely gone. **Zero residue,
zero cost accruing.**

What's still open:

1. Set up a Cloud Billing export to BigQuery (Console-only, one-time, per billing account) - see
   "No `check-costs-gcp.sh` yet" above - before the *next* real apply, so a delayed cost
   cross-check has data to query once built.
2. A second full `deploy-gcp.sh` app-layer cycle - the Terraform infra layer has now had two real
   tested cycles (an incidental full re-apply plus this destroy pass), matching AWS's own
   two-cycle confidence bar for that layer; the k8s app-deploy layer has had one.
