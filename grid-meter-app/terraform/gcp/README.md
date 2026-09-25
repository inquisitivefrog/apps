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

## Status: Redis credential-provider implemented, live-verified, fully torn down (2026-09-24)

The Lettuce credential-provider gap flagged since the 2026-09-23 IAM-auth backport is now closed:
new `config.gcp` package (username the literal `"default"`, password a GCP OAuth2 access token
from `IamCredentialsClient.generateAccessToken()` self-impersonating the app's own service
account, matching Google's own official Lettuce IAM-auth reference sample), wired into
`k8s/api-gcp.yaml`/`deploy-gcp.sh`, and **live-verified against real Memorystore** two ways: a real
`Redis write attempt SUCCEEDED` log line, and a manual `kubectl exec` walkthrough doing the token
exchange by hand. See "Redis credential-provider (2026-09-24)" below for the real bugs found along
the way (a `protobuf-java` version conflict that broke the entire Spring context, a live TLS-trust
gap against Memorystore's private CA, a self-caused deploy outage, a node-pool capacity ceiling,
and a stale check-script validation gap).

Also **observability (`kube-prometheus-stack`/Loki/Tempo/Alloy) was deployed and confirmed live
against this real GKE cluster** during this pass, not just `kind` - see "Observability" below;
the "Observability is not part of this deployment" framing below this line is now stale for GCP.

Full cycle re-verified end to end and then torn down: `terraform apply` → `deploy-gcp.sh` →
`deploy-observability.sh` → live Redis-auth confirmation (both ways above) → `teardown-gcp.sh` →
`terraform destroy` (26 resources, zero errors) → 9 independent GCP API residue checks, all empty.
**GCP is currently fully torn down, zero resources, zero cost accruing** - this is not a live/
running deployment right now. Committed as `f79e276`.

Everything below this point (through "Remaining") describes the original 2026-09-21/2026-09-22
build-and-validate arc that got GCP to Terraform/app-deploy parity with AWS, preserved as history -
the "Status" above is the current, final word on what state this environment is actually in.

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

**Observability (2026-09-24 update): deployed and confirmed live against this real GKE cluster
too**, not `kind`-only as originally scoped - `k8s/deploy-observability.sh` ran clean
(`kube-prometheus-stack` via Helm + Loki/Tempo/Alloy), with one real, worth-noting finding: GKE's
own default node monitoring (Google Managed Prometheus, `gmp-system` namespace) coexists harmlessly
with the separately-installed `kube-prometheus-stack` - two independent Prometheus stacks running
side by side, not a conflict, and GCP's own system-level metrics are never chargeable (only
high-cardinality custom app metrics routed through Cloud Monitoring would be). `kind` remains the
primary load-test/dashboard demo track.

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

**`estimate-costs-gcp.sh` (2026-09-21) fills a different, complementary gap in the meantime** -
not a substitute for the real `check-costs-gcp.sh` above, which will give actual billed dollars
once the BigQuery export exists. Instead of querying billing data, it inventories whatever GCP
resources are actually live right now (same live-query discipline as `check-resources-gcp.sh`) and
multiplies by published GCP list pricing to produce an immediate ballpark estimate - useful exactly
where the real cost check's 24-48h Cost Explorer-equivalent lag isn't: "does anything expensive
look like it's running right now" during a work session, or "does teardown really mean \$0" the
instant teardown finishes, not two days later. Explicitly does not include usage-based charges
(network egress, Cloud NAT data processing, LB data processing) - those can't be estimated from
static resource presence - and its rate card is sourced from live web search against a mix of
official and third-party pricing pages (GCP exposes no direct API this script could query for its
own current rates without a disproportionate per-SKU Billing Catalog lookup), so treat it as
right-order-of-magnitude, not billing-grade. Live-tested against the real, currently-torn-down
project: correctly reports "nothing live to estimate, \$0.00/day" rather than erroring. The
"resources present" arithmetic branch is unit-tested by hand (see
`status/claude_code_2026-09-21.md`) but not yet live-exercised against a real running stack - that
happens naturally the next time this project's GCP infra is stood up.

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
that database's own destroy had already logged success. First fix attempt: an explicit
`depends_on = [google_sql_database.main]` on `google_sql_user.main` - the same "declare the real
ordering, don't assume the API serializes it for you" shape as this project's other
undeclared-dependency findings, just surfacing on teardown instead of apply.

That first fix's retry "succeeded," but not because the fix was correct - only because
`google_sql_database.main` had already been fully destroyed by the time of the retry (it was
already gone from state after the original race, its `DROP DATABASE` having eventually finished
committing on its own), so the `depends_on` edge had nothing left to actually order against. **A
second, later full apply+destroy cycle the same day exercised the fix against a freshly-created
database+user pair for the first time and reproduced the identical original error verbatim** -
proof the fix's dependency direction was backwards the whole time. Terraform's destroy order is
the *reverse* of its create order for a `depends_on` edge: if A `depends_on` B, B is created first
(as intended - user created after database, matching the logs), but **A is destroyed first, B
second** - not "B finishes destroying, then A," which the original fix assumed. So
`user depends_on database` forced the *user* to be destroyed before the database on every fresh
run, guaranteeing the same "objects still depend on it" error every time database and user are
genuinely destroyed together. **Corrected fix**: inverted which resource carries the edge -
`google_sql_database.main` now `depends_on = [google_sql_user.main]` (`cloudsql.tf`) - so destroy
order becomes database-first, user-second: `DROP DATABASE` (and everything it owns) genuinely
completes before `DROP ROLE` is attempted. Confirmed this doesn't disturb create order in any way
that matters - a Cloud SQL user only needs the instance to exist, not the database.

The (backwards) ordering fix's retry appeared to work (`google_sql_user.main` destroyed cleanly,
19 of 22 total) purely due to the state-already-missing-the-database coincidence above, but
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

## 2026-09-22: two more real IP-range collisions found and fixed, validated across two clean cycles

A fresh `terraform apply` the next day (unrelated to anything above - a brand-new apply against the
now-empty project) failed immediately: `google_compute_global_address.private_service_access`
(network.tf) had no explicit `address`, only `prefix_length = 16`, so GCP auto-picked a /16 from its
own internal pool - `10.81.0.0/16` on one apply, `172.16.0.0/16` on this one, landing squarely on
top of `master_ipv4_cidr_block` (`172.16.0.0/28`, gke.tf) and failing cluster creation outright.
Fixed by pinning the PSA range explicitly - `psa_range_address` (`variables.tf`), defaulted to
**`10.1.0.0`** per a stated preference to stay entirely within `10.x.x.x` and keep `10.2.x.x` free
for a possible future second-region VPC.

**That fix alone wasn't enough** - a retry hit a second, different error against the *same*
`172.16.0.0/28` master CIDR: "overlaps with an active peer network (servicenetworking-googleapis-com)".
Researched rather than guessed: `172.16.0.0/23` is GKE's own long-standing default master CIDR, and
Google's Private Service Access peering commonly imports/exports routes touching that same
`172.16.0.0/12` block on the producer side regardless of what range this project's own PSA
connection reserves - a real, documented category of conflict. Fixed by moving
`master_ipv4_cidr_block` (`variables.tf`) off `172.16.0.0/12` entirely, onto **`10.0.0.0/28`** - the
same low `10.x.x.x` scheme as the PSA fix, chosen deliberately over `192.168.0.0/16` too (a second,
independently-known collision-prone range for the same underlying reason).

**Both fixes validated across two independent full destroy+reapply cycles**, not just one - the
first `terraform apply tfplan` after the master-CIDR fix only needed to replace the tainted cluster
(3 to add, 1 to destroy; Cloud SQL/Memorystore/VPC/PSA untouched, since only the cluster referenced
the bad CIDR), confirmed clean via `check-resources-gcp.sh` (17/17). A full `terraform destroy` +
fresh `terraform apply` cycle immediately after came back clean too (22 destroyed, then 22 created,
0 errors) - genuine repeat-run confirmation, not a one-off. `terraform show` confirmed empty state
after the destroy half of that cycle.

**Also found and fixed a real bug in `estimate-costs-gcp.sh` during its first live "resources
present" run**: its forwarding-rules count was unfiltered, picking up Memorystore's own PSC
auto-connection forwarding rules (confirmed via `loadBalancingScheme` - empty on those, `EXTERNAL`
on the real Network LB rule) and mislabeling them as "external forwarding rule(s)". The dollar
total happened to land right that run (both fall under the same flat "up to 5 rules" pricing tier),
but the label was wrong and would have double-counted once a real LB rule also existed. Filtered to
`loadBalancingScheme=EXTERNAL`; re-confirmed live afterward (correctly reports "no forwarding rules
found" when the k8s app layer isn't deployed).

**Left the bootstrap state bucket alone deliberately** after an unrelated `terraform destroy` in
`bootstrap/` was attempted and blocked by its own `lifecycle.prevent_destroy` - checked live: 3.24
MiB total across all versioned history, effectively $0.00/month (well inside GCS's Always Free
tier), so leaving it in place indefinitely carries no real cost either way.

**Then ran a second real `deploy-gcp.sh` cycle on purpose**, specifically to close the one
remaining gap relative to AWS's confidence bar (the k8s app-deploy layer had only one prior cycle,
from 2026-09-21). Full sequence: fresh `terraform apply` (a third independent confirmation the
CIDR fixes hold), `check-resources-gcp.sh` (17/17), `deploy-gcp.sh` (clean end-to-end, **zero new
bugs** - every fix from the first cycle held), `k8s/check-resources-gcp.sh` (15/15), then a real
browser login against the live LoadBalancer IP with the seeded `demo` credentials, confirming both
the Meters and Readings pages load correctly. `deploy-gcp.sh` now has two clean cycles, matching
AWS's bar on both layers simultaneously for the first time this project has achieved that for GCP.

**Then tore it down to confirm - and found one more real, previously-undiscovered gap in the
process.** `k8s/teardown-gcp.sh` was skipped by mistake, going straight to `terraform destroy`,
which failed: `pq: database "gridmeter" is being accessed by other users`. Root cause, confirmed
by reading the actual destroy-log ordering: `google_sql_database.main`'s destroy fired in the very
first batch, in parallel with everything else, while the GKE cluster - and the live `api` pods
holding HikariCP connection pools to Cloud SQL - was still fully running. Postgres correctly
refused `DROP DATABASE` with an active session attached; `google_sql_database.main` has no
`depends_on` the cluster's own destroy (independent resource graphs in Terraform's eyes, even
though the *app* running on the cluster depends on the database). Checked live state rather than
guessed: the cluster was already gone by then (so a retry should succeed - it did), the LB
forwarding rule was already gone too (GKE's own cluster-deletion cleaned it up automatically), but
**3 real orphaned Kafka persistent disks remained** (kubectl had nothing left to reach once the
cluster was gone) - deleted directly via `gcloud compute disks delete`. **Fixed
`k8s/teardown-gcp.sh`** with a new first step that scales `api` to 0 and waits for its pods to
terminate before anything else runs, closing this gap for good - a third, distinct reason now
documented in the script's own header alongside the original LB/Kafka-disk reasons. Retried
`terraform destroy` against the remaining resources - clean. `terraform show` confirmed empty
state; `check-resources-gcp.sh`/`estimate-costs-gcp.sh` both correctly report nothing
found/\$0.00. **GCP is now genuinely fully torn down**, not just believed to be - four real
Terraform-layer cycles and two k8s-layer cycles total, matching/exceeding AWS's bar on both. What's
still open:

1. Set up a Cloud Billing export to BigQuery (Console-only, one-time, per billing account) - see
   "No `check-costs-gcp.sh` yet" above - before the *next* real apply, so a delayed cost
   cross-check has data to query once built. **Still not done as of 2026-09-24** -
   `estimate-costs-gcp.sh`'s list-price estimate remains the only cost signal for this cloud.

## 2026-09-23/2026-09-24: Redis IAM-auth backport (Terraform), then the real Lettuce credential-provider (app code), live-verified

**2026-09-23, Terraform-only**: once Azure's Redis product was force-migrated onto Entra-ID-only
auth, the user asked to backport the same tighter, IAM/token-based posture to AWS's ElastiCache and
GCP's Memorystore rather than wait to be forced there too. Found live before writing anything:
neither AWS nor GCP had *any* pod-level cloud identity at all (only node-level/addon-level identity
existed) - this wasn't a flag flip, it needed new Workload Identity Federation infrastructure.
Added: Workload Identity Federation enabled on the GKE cluster, a dedicated
`google_service_account.app` bound to `system:serviceaccount:default:grid-meter-app` with
`roles/memorystore.dbConnectionUser`, and `authorization_mode = "IAM_AUTH"`/
`transit_encryption_mode = "SERVER_AUTHENTICATION"` on the Memorystore instance itself. Left
genuinely inert at the end of that day - no app code, no K8s ServiceAccount object yet.

**2026-09-24: the actual app code, implemented and live-verified end to end.** New `config.gcp`
package, mirroring AWS's `config.aws` structure exactly:
- `GcpMemorystoreCredentialsProvider` - a cached/expiring Lettuce `RedisCredentialsProvider`,
  username the literal `"default"`, password a GCP OAuth2 access token from
  `IamCredentialsClient.generateAccessToken()`, **self-impersonating the app's own service
  account** (matching Google's own official Lettuce IAM-auth reference sample and a real
  third-party production implementation, not guessed) - required a new
  `roles/iam.serviceAccountTokenCreator`-on-itself Terraform grant beyond the existing Workload
  Identity binding.
- `GcpRedisConfig` - `@Profile("cloud-gcp")`-gated bean wiring, plus a second, dedicated
  `LettuceClientOptionsBuilderCustomizer` bean wiring a custom SSL trust manager for Memorystore's
  private per-instance CA certificate (`server_ca_mode = GOOGLE_MANAGED_PER_INSTANCE_CA`) - found
  live-necessary after a real `SSLHandshakeException` ("PKIX path building failed"); `useSsl()`
  alone only sets a simple on/off flag, not a trust manager. A new Terraform output
  (`memorystore_server_ca_certificates`, a joined PEM bundle from the instance's nested
  `managed_server_ca` attribute) feeds a ConfigMap the pod mounts the CA file from.

Real bugs found and fixed along the way, none guessable in advance:
- **`com.google.cloud:libraries-bom` pinned `protobuf-java` below what OpenTelemetry's own
  generated proto classes needed**, breaking the *entire* Spring context (not just GCP beans) at
  OTLP-exporter init time (`ProtobufRuntimeVersionException`) - fixed by explicitly pinning
  `protobuf-java` in `dependencyManagement` to override the BOM (Maven's nearest-declaration
  precedence).
- **A self-caused live outage**: applied `api-gcp.yaml` directly via `kubectl apply -f` without
  running it through `deploy-gcp.sh`'s `sed` placeholder substitution, applying literal
  `PLACEHOLDER_*` strings as real values - combined with a rollout-strategy change already in
  flight, this took `api` fully offline. Fixed immediately by re-running with real values from
  `terraform output -raw`.
- **A live node-pool memory capacity ceiling** (`0/4 nodes are available: 4 Insufficient memory`) -
  this pool (4x `e2-medium`) was already at 97-98% memory requests running the app plus the full
  observability slice, with no headroom for `RollingUpdate`'s surge pod. Fixed by switching `api`'s
  rollout strategy to `Recreate` (accepted brief-downtime tradeoff for a demo project).
- **`check-resources-gcp.sh`'s GCE-worker-instance check never actually validated a count** despite
  its own label claiming "(expect 3, RUNNING)" - its `check()` function had no expected-value
  parameter at all, unlike AWS's/Azure's identical scripts. Replaced with a real count comparison
  (now correctly expecting 4: the main pool's 3 nodes + the extra pool's 1).
- **A `GCE_STOCKOUT` spanning two of three node-pool zones simultaneously** - resolved by dropping
  `gke_node_locations` to `us-central1-a` only and raising `gke_node_count` to 3 to preserve the
  original 3-node-total intent (`variables.tf`).

Full suite re-run clean after every dependency change (102/102, zero regressions). Live-verified
two independent ways: a real `Redis write attempt SUCCEEDED` log line from a running pod against
real Memorystore, and a manual `kubectl exec` walkthrough (with the user) doing the token-and-
connect flow by hand. Committed as `f79e276`, then torn down again (`terraform destroy`: 26
resources, zero errors; 9/9 independent GCP API residue checks empty). **This closes the last
remaining gap from the "Remaining" section above** - GCP now matches AWS's/Azure's full
implement-verify-teardown confidence bar, not just Terraform/app-deploy parity.
