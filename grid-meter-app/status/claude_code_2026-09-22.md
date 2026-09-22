# grid-meter-app — Status: 2026-09-22 (Claude Code)

Continuation of 2026-09-21's GCP work: a fresh `terraform apply` against the (previously
fully-torn-down) project failed with a real IP-range collision, not a fluke — traced, fixed, and
the fix validated as repeatable across two independent full destroy+reapply cycles. GCP is now
considered done for this project's purposes.

## Done — found and fixed a real PSA-range/GKE-master-CIDR collision (attempt 1)

A fresh `terraform apply` failed: `Conflicting IP cidr range: Invalid IPCidrRange: 172.16.0.0/28
conflicts with reserved IP range '172.16.0.0/16'`. Root cause:
`google_compute_global_address.private_service_access` (network.tf) had no explicit `address`,
only `prefix_length = 16` — GCP auto-picks a /16 from its own internal pool each apply
(`10.81.0.0/16` on an earlier apply, `172.16.0.0/16` this time), and the second landed directly on
`master_ipv4_cidr_block` (`172.16.0.0/28`, gke.tf). The exact "undeclared default silently
colliding with something assumed fixed" shape this project's own CLAUDE.md already tracks many
instances of — just for an IP range instead of a timeout/durability setting.

Fixed by adding `psa_range_address` (`variables.tf`) and pinning it explicitly in `network.tf`.
User's stated preference, applied directly: stay in `10.x.x.x` (not `192.168.x.x`, which they
noted avoiding on instinct in prior GCP experience — turned out to be dodging the same category of
bug, confirmed later this session), and keep it low/small (`10.1.0.0`) so `10.2.x.x` stays free for
a possible future second-region VPC if cross-region replication is ever added.

Partial live state from the failed apply (tainted cluster, live Cloud SQL/Memorystore/VPC) was
resolved with a full `terraform destroy` + fresh `terraform apply`, not a risky in-place patch —
consistent with this session's established preference for clean full cycles over fragile partial
fixes when something goes wrong mid-apply.

## Done — the PSA fix alone wasn't enough: a second, different collision on the same CIDR (attempt 2)

The very next fresh apply failed again, same `master_ipv4_cidr_block`, different error: `New
subnetwork IP range (172.16.0.0/28) overlaps with an active peer network
(servicenetworking-googleapis-com)`. Researched rather than re-guessed: confirmed via GCP's own
troubleshooting docs that `172.16.0.0/23` is GKE's own long-standing default master CIDR, and
Google's Private Service Access peering commonly imports/exports routes touching that same
`172.16.0.0/12` block on the producer side — a known category of conflict independent of whatever
range this project's *own* PSA connection reserves. No amount of picking a different PSA subrange
would have fixed this; the master CIDR itself needed to move off `172.16.0.0/12` entirely.

Fixed: `master_ipv4_cidr_block` (`variables.tf`) moved to **`10.0.0.0/28`** — same low `10.x.x.x`
scheme as the PSA fix, disjoint from `psa_range_address` (`10.1.0.0/16`), `subnet_cidr`
(`10.10.0.0/20`), `pods_cidr` (`10.11.0.0/16`), `services_cidr` (`10.12.0.0/20`).

**This fix didn't need a full teardown** — only `google_container_cluster.main` referenced the bad
CIDR, and it was already tainted from the prior failure (due for replacement regardless). A plan
against the live partial state showed a minimal `3 to add, 0 to change, 1 to destroy` (the cluster
replaced, plus the two node pools that never got created) — applied clean, `check-resources-gcp.sh`
confirmed 17/17.

## Done — user explicitly asked to re-verify with a second independent cycle before trusting it

Per user request ("let's bring it down and back up again to be sure") — one clean cycle could be
coincidence, a second confirms it's genuinely fixed. Ran a full `terraform destroy` (22 resources,
clean) followed by a fresh `terraform apply` (22 resources, clean, zero errors) against a
completely fresh state. `terraform show` confirmed empty state after the destroy half;
`check-resources-gcp.sh` confirmed 17/17 healthy after the reapply half. **Both IP-range fixes are
now validated as repeatable across two independent full cycles, not just observed working once** —
a materially stronger confidence bar than 2026-09-21's teardown had, where the (ultimately wrong)
first attempt at the Cloud SQL depends_on fix looked like it worked on a retry purely by
coincidence and wasn't actually re-tested until this session.

## Done — found and fixed a real bug in `estimate-costs-gcp.sh` on its first live "resources present" run

Built 2026-09-21 but never run against real live-and-populated infrastructure until today. Ran
clean, but one line was wrong: "2 external forwarding rule(s)" — checked live via
`gcloud compute forwarding-rules list --format="table(name,loadBalancingScheme,...)"` and confirmed
both had an *empty* `loadBalancingScheme`, meaning they were Memorystore's own PSC auto-connection
forwarding rules, not the app's external Network LB (which doesn't even exist yet at this
Terraform-only stage — the k8s app layer wasn't deployed this pass). The unfiltered
`forwarding-rules list` call picked up both. Dollar total happened to be correct anyway (both PSC
rules and a would-be real LB rule fall under the same flat "up to 5 rules for $0.025/hr" pricing
tier), but the label was wrong and would have double-counted once a real LB rule also existed
alongside them. Fixed by filtering to `loadBalancingScheme=EXTERNAL`; re-ran live, now correctly
reports "no forwarding rules found - LoadBalancer Service not deployed".

## Done — answered a direct cost/time question about the bootstrap state bucket, checked live rather than estimated

User asked whether the untouched `bootstrap/` GCS state bucket (left alone after an unrelated
`terraform destroy` attempt there was blocked by its own `lifecycle.prevent_destroy`) is costing
real money, and how long recreating it would take if ever torn down. Checked live rather than
guessed: `gsutil du -sh -a` showed 3.24 MiB total across every versioned object (accumulated across
every apply/destroy cycle both this session and 2026-09-21) — at GCS Standard pricing
(~$0.020/GB-month, us-central1), that's ~$0.00006/month, and comfortably inside GCS's Always Free
5 GB-month allowance, so the real billed cost is genuinely $0.00. Recreation time: no exact figure
was ever logged for the original bootstrap apply, but a single GCS bucket resource is a near-instant
API call, nothing like the multi-minute GKE/Cloud SQL/Memorystore waits — answered honestly as "a
few seconds, not a meaningful prerequisite delay" rather than fabricating false precision. User
chose to leave the bucket as-is.

## Done — second real `deploy-gcp.sh` cycle: clean end-to-end, zero new bugs, closes the k8s-layer confidence gap

User asked to try once more with `deploy-gcp.sh` and `k8s/check-resources-gcp.sh` in the loop, to
close the gap flagged above (Terraform layer at three cycles, k8s app layer still at one). Full
sequence run for real: fresh `terraform apply` (22 resources, clean - a third independent
confirmation the CIDR fixes hold), `check-resources-gcp.sh` (17/17), `deploy-gcp.sh` (clean
end-to-end, **zero new bugs** - every fix from the first cycle held: XFS `pd-balanced-xfs` storage
class, `--platform linux/amd64` build flag, 1Gi `api` memory, the Artifact Registry image-path
output fix, the `artifactregistry.reader` IAM grant), `k8s/check-resources-gcp.sh` (15/15). User
then logged into the real app in a browser at the real LoadBalancer IP with the seeded `demo`
credentials, confirmed both the Meters and Readings pages load correctly (empty tables, as expected
for a freshly deployed environment with no data yet).

**`deploy-gcp.sh` now has two real clean cycles**, matching AWS's own two-cycle confidence bar for
the k8s app-deploy layer - the one piece of AWS's bar GCP hadn't matched as of this morning's status
write-up. GCP infra is left live and running after this cycle (not torn down) - real cost accruing
per `estimate-costs-gcp.sh`'s earlier ballpark (~$148-166/mo) until next torn down.

## Done — teardown confirmation surfaced a real, previously-undiscovered gap: `terraform destroy` racing a still-live app's Cloud SQL connections

User asked to tear down the live deployment to confirm before declaring victory, and skipped
`k8s/teardown-gcp.sh` by mistake going straight to `terraform destroy`. This surfaced a genuinely
new bug, unrelated to anything `teardown-gcp.sh` itself protects against (the LB forwarding rule and
Kafka's disks): `terraform destroy` failed with `pq: database "gridmeter" is being accessed by
other users`. Root cause, confirmed by reading the actual log ordering: `google_sql_database.main:
Destroying...` fired in the very first batch, in parallel with everything else, while the GKE
cluster - and the two live `api` pods holding HikariCP connection pools to Cloud SQL - was still
fully running. Postgres correctly refused `DROP DATABASE` with an active session attached.
`google_sql_database.main` has no `depends_on` the GKE cluster's own destroy in this config -
they're independent resource graphs in Terraform's eyes, even though the *app* running on the
cluster depends on the database.

Checked live state to confirm exactly what had and hadn't been destroyed rather than guessing:
`gcloud container clusters list` showed the cluster already gone (so the offending connections were
gone too - a retry should now succeed), `gcloud compute forwarding-rules list` showed zero (GKE's
own cluster-deletion apparently cleaned that up automatically as part of tearing down the cluster),
but `gcloud compute disks list` showed **3 real orphaned Kafka persistent disks** (12GB
`pd-balanced` each, one per zone) - with the cluster gone, kubectl had nothing left to reach them
through, so nothing would ever have cleaned them up automatically. Deleted directly via
`gcloud compute disks delete` (a plain gcloud delete, not `terraform apply`/`destroy`, so run
directly rather than deferred to the user).

**Fixed `k8s/teardown-gcp.sh`** to close the actual root cause for next time: added a new Step 1
that scales the `api` Deployment to 0 and waits for its pods to fully terminate - releasing their
Cloud SQL connections - before anything else runs, including before `terraform destroy` is ever
invoked. Existing LB/Kafka steps renumbered to Step 2/3. This is a different fix than what the
script's original two reasons addressed; documented as a third, distinct reason in the script's own
header comment.

**Retried `terraform destroy`** against the remaining 7 resources (Cloud SQL, VPC, PSA, etc.) -
completed cleanly this time, confirming the hypothesis (no live connections left once the cluster
was gone). `terraform show` reports empty state; `check-resources-gcp.sh` and
`estimate-costs-gcp.sh` both correctly report nothing found / \$0.00. **GCP is now genuinely fully
torn down**, not just believed to be.

## Done — started Azure: account setup, real prerequisite gaps found, full plan-only main config built and validated live

Same evening, moved on to Azure per the AWS-first sequencing. User's stated starting context:
significantly less familiar with Microsoft's ecosystem than AWS/GCP (hasn't bought Microsoft
products in about a decade) - carried into a new standing memory so future Azure/Microsoft work
explains more, not less, matching how GCP got extra explanation earlier this project for a similar
(smaller) familiarity gap.

**Real account setup, walked through step by step**: `az` CLI already installed but not logged in;
`az login` succeeded but `az account list` kept failing with "No subscriptions found" - diagnosed
live (token cache had updated, but the subscription/profile list hadn't) as a real, distinct
prerequisite gap from AWS/GCP: being logged into a Microsoft account and having an Azure
*subscription* are two separate things. Confirmed live via web search that Azure's free trial
needs a real (non-virtual) card plus phone verification, same shape as GCP's own trial gate. User
completed sign-up; `az login` then showed exactly one subscription, selected.

**Accessibility**: `az` CLI's own colored output was hard to read - found and set the real,
documented `az config set core.no_color=true` fix (verified via Microsoft's own docs before
suggesting it, not guessed), confirmed live (zero ANSI codes in output afterward). Same for
Terraform's own coloring later - `TF_CLI_ARGS="-no-color"` set permanently in `~/.zshrc`,
confirmed live. Both are separate programs from Claude Code's own terminal theme (already fixed
earlier this project via `/theme light-daltonized`) - neither fix carries over to the other
automatically, worth remembering as a standing fact for this user's environment.

**Bootstrap module** (state backend: Resource Group + Storage Account + Blob Container) scaffolded
with real provider-schema verification (installed `azurerm` into a scratch dir, inspected
`terraform providers schema -json` directly rather than trusting docs/blog posts - caught a real
breaking change, `azurerm_storage_container` needing `storage_account_id` not the older
`storage_account_name` some still-current sources show). First real `terraform apply` failed with
`MissingSubscriptionRegistration` - a brand-new Azure subscription starts with none of Azure's
resource-provider namespaces registered, a real prerequisite gap neither AWS nor GCP had in the
same shape. Registered all 9 namespaces this project's full stack will need (not just the one that
failed), confirmed each reached `Registered` live rather than trusting the register command's own
completion. **Bootstrap applied for real and confirmed live** (`terraform show` + direct `az`
verification) - Resource Group, Storage Account, Blob Container all exist in `eastus`.

**Main config built and validated against the real subscription, plan-only per confirmed scope**:
VNet/AKS/Postgres Flexible Server/Azure Cache for Redis/ACR, mirroring AWS's/GCP's directory
structure. Extensive live verification before writing anything (not just at error-time): AKS
doesn't support B-series VMs for system node pools (real platform constraint, picked
`Standard_D2as_v5` instead), Postgres Flexible Server *does* support B-series (a real contrast
worth keeping, not an inconsistency), PostgreSQL 18 confirmed GA on Azure, `storage_mb`'s real
minimum/default (32768), ACR's real repo-is-a-namespace model (checked before writing, specifically
to avoid repeating the GCP session's own live-caught mistake a second time).

**One real, consequential tradeoff surfaced and taken to the user rather than resolved silently**:
Azure's modern Redis product ("Azure Managed Redis," genuinely current Redis via a Microsoft/Redis
Ltd. partnership - confirmed Azure deliberately did NOT adopt Valkey the way AWS/GCP did)
authenticates via Entra ID tokens ONLY, no password/access-key at all - confirmed via its own
provider schema, then confirmed the app's actual `spring.data.redis.*` config couldn't use that
without real new application code. User chose to stay on the legacy, password-auth,
Redis-6.0-capped `azurerm_redis_cache` to keep the app identical across every cloud target,
accepting the version/product-longevity cost explicitly rather than have it decided for them.

**`terraform validate` itself caught two real bugs before any live API call**: `azurerm_key_vault`'s
RBAC attribute is `rbac_authorization_enabled` (not `enable_rbac_authorization`, which some current
docs/examples still show), and `azurerm_private_dns_zone_virtual_network_link` takes
`private_dns_zone_id` (not `private_dns_zone_name`) with no `resource_group_name` argument at all -
both guessed wrong on first draft despite the scratch-dir schema-verification habit (these two
weren't in the initial batch checked), both caught cleanly by `validate` rather than a live apply.
Also found: `azurerm_kubernetes_cluster` requires a `node_provisioning_profile` block as of
azurerm 5.x, a real breaking-change-shaped requirement not prominently documented as such.

**Final result: clean `terraform plan` against the real subscription - 15 to add, 0 to change, 0 to
destroy.** Nothing applied yet, matching the confirmed plan-only-first scope (same as how both
AWS's and GCP's own tracks started). `terraform/azure/README.md` written documenting the full
account; this is genuinely the most upfront-research-heavy of the three cloud passes so far, and
still found real bugs live-verification alone wouldn't have caught - consistent with this
project's now well-established pattern that verification reduces but never eliminates the gap
between "looks right" and "is right."

## Open

- **GCP is functionally complete and fully confidence-tested as of today** - both IP-range fixes
  validated across two independent cycles, `deploy-gcp.sh` has two clean cycles matching AWS's bar,
  and the teardown flow itself found and fixed one more real gap (live-app-connections racing
  `terraform destroy`) that no prior cycle had ever exercised, since no prior teardown had skipped
  `teardown-gcp.sh` before.
- **GCP infrastructure is now fully torn down and confirmed clean** - zero residue, zero cost,
  independently verified (not just trusted from "Apply/Destroy complete").
- The Terraform infra layer has **four** real tested cycles total; the k8s app-deploy layer has
  **two**, matching/exceeding AWS's confidence bar on both.
- No `check-costs-gcp.sh` still - unchanged prerequisite gap (Cloud Billing→BigQuery export,
  Console-only, not yet set up). `estimate-costs-gcp.sh` remains the practical stand-in.
- Bootstrap state bucket (`terraform/gcp/bootstrap/`) left untouched - confirmed negligible cost,
  no reason to disturb it.
- **Azure's bootstrap module is applied and live** (state backend only); the main config is
  scaffolded, validated, and plan-clean against the real subscription, but **nothing beyond
  bootstrap has been applied** - a deliberate stopping point for the night, not a blocker.

## Next

1. **Azure**: a real `terraform apply` (user-run) for the main config - the next natural step,
   picking up fresh with a known-clean plan already in hand.
2. **Azure**: `k8s/deploy-azure.sh`/`teardown-azure.sh` and Azure-specific k8s manifest variants,
   once the main config is actually applied - mirroring AWS's/GCP's own later app-deploy phase.
3. **Azure**: `check-resources-azure.sh` (both layers) once there's real infrastructure to check.
4. If GCP work resumes later: the Cloud Billing BigQuery export, so a real `check-costs-gcp.sh`
   becomes buildable.
5. Longer-carried items: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost fix,
   `docs/testing-expansion-scope.md` task #9+.
