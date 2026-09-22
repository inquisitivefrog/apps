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

## Next

1. Azure Terraform config — next in the AWS-first sequencing, deferred since the end of 2026-09-21
   for this GCP fix work.
2. If GCP work resumes later: the Cloud Billing BigQuery export, so a real `check-costs-gcp.sh`
   becomes buildable.
3. Longer-carried items: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost fix,
   `docs/testing-expansion-scope.md` task #9+.
