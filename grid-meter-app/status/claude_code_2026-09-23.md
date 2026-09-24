# grid-meter-app — Status: 2026-09-23 (Claude Code)

Continuation of 2026-09-22's Azure work: took the main config from plan-only to a real, live,
fully-applied deployment across two separate sessions today, finding and fixing a real platform
error at nearly every step. Along the way, Azure's forced Redis product change prompted an explicit
user decision to backport the same tighter (IAM/token-based) Redis auth posture to AWS and GCP too,
Terraform-only. All three clouds then went through a full deploy → confirm → teardown → confirm →
destroy → residue-check cycle (committed as `e243776`). Later the same day: AWS's Lettuce
credential-provider app code was scoped and implemented (uncommitted - its live connection is
still unverified), and the night closed with a real stale-kubeconfig bug found and fixed during
shutdown before AWS was torn down again.

## Done — first live apply attempt (eastus): three real platform errors found and fixed

`terraform apply` against the confirmed-clean 15-resource plan failed partway through with three
separate live errors, none guessable in advance:

- **AKS `AvailabilityZoneNotSupported`** - checked live via `az vm list-skus` across
  eastus/eastus2/centralus for the same VM size: all three show identical
  `NotAvailableForSubscription` restrictions on every zone, confirming a subscription-tier-wide
  (free-trial) restriction, not region- or size-specific. Fixed: `aks_availability_zones` defaults
  to `[]`, and `aks.tf` only sets the node pool's `zones` argument (as `null`, not `[]` - a
  deliberate distinction, since an empty set isn't necessarily equivalent to the argument being
  absent at the API level) when non-empty.
- **`Microsoft.KeyVault` never registered** - a real oversight in the prior session's own
  provider-registration pass. Fixed live, added to the README's prerequisite list.
- **Postgres Flexible Server provisioning entirely blocked in `eastus`** for this subscription
  (`az postgres flexible-server list-skus --location eastus`: `"Provisioning is restricted in this
  region"`). Checked live across 5 regions: eastus/eastus2/westus2/southcentralus all identically
  blocked, centralus/westus3 both open. Moved `azure_region` to `centralus`.

**Found a real Terraform plan-diffing gap before any second apply**: a region-change "replace" plan
didn't list `azurerm_subnet.aks`/`.postgres`/`azurerm_private_dns_zone.postgres` for any action,
despite their parent Resource Group being destroyed+recreated - resources referenced by a static
name string aren't detected as needing replacement when the parent is replaced, even though Azure's
real cascade-delete would destroy them. Resolved with a full `terraform destroy` (confirmed via
`plan -destroy` correctly listing all 9 resources) + fresh `apply` from empty state, not a risky
in-place replace.

## Done — second live apply attempt (centralus): four more real platform errors

- **`Standard_D2as_v5` not in this subscription's centralus-allowed VM-size list** - the error
  response itself enumerated the allowed sizes; switched to `Standard_D2as_v7`.
- **Key Vault RBAC mode grants nothing implicitly** - `rbac_authorization_enabled = true` means the
  creating principal has zero secret access by default; writing the Postgres password secret failed
  `403 Forbidden` until an explicit `azurerm_role_assignment` ("Key Vault Secrets Officer") was
  added, plus a `time_sleep` (30s) for RBAC's real propagation delay - a deliberate, explained
  exception to this project's "poll, don't sleep" rule, since no live propagation-status API exists.
- **Postgres needed `public_network_access_enabled = false` declared explicitly** - its own default
  silently conflicts with `delegated_subnet_id`/`private_dns_zone_id`
  (`ConflictingPublicNetworkAccessAndVirtualNetworkConfiguration`).
- **The legacy Azure Cache for Redis product is now actively blocked from new creation** -
  `"Azure Cache for Redis is retiring, create Azure Managed Redis instance instead."` This
  invalidated the prior session's explicit "stay on legacy Redis" decision. Re-escalated to the
  user via `AskUserQuestion` (a third option, self-hosting Redis in AKS, was offered alongside
  Azure Managed Redis) rather than resolved silently. **User chose Azure Managed Redis.**

## Done — rewrote `rediscache.tf` for Azure Managed Redis, updated `variables.tf`/`outputs.tf`

Replaced the legacy `azurerm_redis_cache` resource with `azurerm_managed_redis`
(`sku_name = "Balanced_B0"`), removed the now-nonexistent `redis_family`/`redis_capacity`
variables, and dropped `outputs.tf`'s `redis_ssl_port` output (Managed Redis exposes only a
hostname - no port/access-key attributes exist on the resource at all, confirmed via the real
provider schema; it authenticates via Entra ID tokens exclusively).

## Done — third live apply: Managed Redis's own required block, an AKS quota wall, two computed-attribute quirks

- **`azurerm_managed_redis` requires a `default_database` block** ("must be provided when creating
  a new resource") despite every attribute inside it being individually optional - not caught by
  `validate` (an absent optional-nested block is normally fine; this resource is the exception).
  Confirmed via the real provider schema, then added the block with
  `access_keys_authentication_enabled = false` set explicitly - the whole point of this product is
  Entra ID auth, so leaving that undeclared would have silently left legacy access-key auth
  available too.
- **AKS failed with `InsufficientVCPUQuota`**: `az vm list-usage` confirmed a hard 4-vCPU regional
  cap (identical in centralus and westus3 - subscription-wide, same shape as the zone restriction),
  and 3 nodes × `Standard_D2as_v7`'s 2 vCPU = 6 exceeded it. Presented to the user via
  `AskUserQuestion` rather than silently resized; **user chose dropping `aks_node_count` to 2**
  (4 vCPU, fits exactly) over requesting a quota increase. Kafka's 3 broker pods lose strict
  one-per-node placement as a real, accepted tradeoff.
- **Postgres's `zone` attribute can't be cleared in-place** - leaving it undeclared (after dropping
  explicit zone-pinning) made every plan try to "correct" the live Azure-auto-assigned value back to
  unset, which the API flatly rejects outside an HA zone-swap operation. Fixed with
  `lifecycle { ignore_changes = [zone] }`.
- **AKS's `default_node_pool.upgrade_settings` is optional+computed the same way** - declared
  explicitly matching the platform's own live-confirmed default (`max_surge = "10%"`,
  `drain_timeout_in_minutes = 0`, `node_soak_duration_in_minutes = 0`) rather than `ignore_changes`,
  since (unlike `zone`) it doesn't reject in-place changes outright - just kept showing a spurious
  diff every plan.

**Final result**: `terraform plan` reports **No changes. Your infrastructure matches the
configuration.** against live state - independently re-verified, not just trusted from "Apply
complete." Azure is now fully applied: VNet, AKS (2 nodes), Postgres Flexible Server, Azure Managed
Redis, ACR, and the new Entra ID workload-identity resources below.

## Done — backported IAM/token-based Redis auth to AWS and GCP, Terraform-only (user-directed)

User's own framing: given Redis auth is trending toward tighter (token/IAM-based) security
industry-wide, and Azure was just forced onto exactly that, backport the same posture to AWS/GCP
now rather than wait to be forced there too - explicitly accepting this means touching AWS/GCP
Terraform (and eventually app code/tests) that had nothing wrong with it today.

Scoped with the user via `AskUserQuestion` before touching anything, since live research turned up
a materially bigger lift than the request initially sounded like: **neither AWS nor GCP had any
pod-level cloud identity at all** (only node-level/addon-level identity existed on either), so this
isn't a flag flip - it's new IRSA/Workload Identity infrastructure on both clouds. User chose
**"Terraform only, all 3 clouds now"** - infra wiring today, the three Lettuce credential-provider
implementations (and their tests) tracked as an explicit, separate follow-up phase, not attempted
inline.

Verified live/via provider schema before writing anything (not guessed):
- ElastiCache IAM auth works with the `valkey` engine already in use (>= Redis-7-equivalent), not
  redis-only.
- GCP's actual resource in use, `google_memorystore_instance` (Valkey), supports
  `authorization_mode = "IAM_AUTH"` directly - a different, separate resource
  (`google_redis_cluster`) was checked first and would have implied a product swap; the real
  in-use resource needed no such thing.
- The correct GCP predefined role is `roles/memorystore.dbConnectionUser` (not a generic
  viewer/editor role).
- Azure Managed Redis's Entra ID data-plane access uses a dedicated
  `azurerm_managed_redis_access_policy_assignment` resource (confirmed present in the installed
  provider version), a genuinely different access-control layer from Key Vault's Azure-RBAC model
  used elsewhere in this same config - not an inconsistency.

**AWS** (`terraform/aws/elasticache-iam-auth.tf`, new): IRSA role scoped to
`system:serviceaccount:default:grid-meter-app` (reusing the existing EKS OIDC provider from
`ebs-csi.tf`), a disabled `default` ElastiCache user (required by AWS to exist in every user
group), an IAM-auth `app` user, a user group, `transit_encryption_enabled = true` +
`user_group_ids` added to the existing replication group. `terraform plan` against the (currently
torn-down) AWS stack confirmed all new resources appear correctly in a 50-resource plan.

**GCP** (`gke.tf`, `memorystore.tf`): Workload Identity Federation enabled on the cluster (not
previously on at all), a dedicated `google_service_account.app` bound to the same service-account
subject with `roles/memorystore.dbConnectionUser`, and
`authorization_mode = "IAM_AUTH"`/`transit_encryption_mode = "SERVER_AUTHENTICATION"` added to the
existing Memorystore instance. `terraform validate`/`fmt` clean; stack currently torn down, so no
live plan possible until next brought up.

**Azure** (`redis-iam-auth.tf`, new; `aks.tf`): `workload_identity_enabled`/`oidc_issuer_enabled`
added to the AKS cluster, a dedicated `azurerm_user_assigned_identity` + federated credential
trusting the same service-account subject, and the access-policy-assignment resource above granting
it Managed Redis access. Confirmed live via a real `terraform apply` - all three new resources
created cleanly.

All three clouds' new Terraform is real but currently **inert**: the K8s ServiceAccount object
itself doesn't exist in any `k8s/api-*.yaml` yet (`k8s/api-azure.yaml` doesn't exist at all;
`api-aws.yaml`/`api-gcp.yaml` currently run pods as the implicit `default` SA, no
`serviceAccountName` field), and none of the three Lettuce credential-provider implementations
exist. Documented explicitly in each new file's header comment and in `terraform/azure/README.md`'s
"What's next" so this is traceable later, not a silent gap.

## Done — updated `terraform/azure/README.md`

Rewrote the status section (plan-only → applied/live), added a full "Real findings" section
covering all three live-apply attempts today (grouped by which apply surfaced them), a "Redis: two
real reversals, not indecision" section walking through both the 2026-09-22 and 2026-09-23
decisions and why they're not contradictory, and an "IAM-auth backport" section covering today's
cross-cloud Redis-auth work. Directory structure and "What's next" updated to match current reality
(`redis-iam-auth.tf` added, `rediscache.tf`'s description updated, next steps reordered to put the
now-required Lettuce credential-provider work first).

## Done — AWS: a real live apply failure on the IAM-auth backport, fixed, then a full clean apply (50 resources)

User re-ran `terraform apply` against AWS for real. Failed on the very first ElastiCache resource:
`InvalidParameterCombination: No-password-required is not allowed for a user with engine Valkey` -
unlike Redis OSS, Valkey's `authentication_mode` doesn't support `no-password-required` at all,
confirmed live via web search against AWS's own docs (this project's earlier assumption, carried
over from the generic RBAC pattern, was wrong specifically for Valkey). Fixed by generating a real,
never-retrieved, never-used password via a new `random_password` resource and switching the
disabled default user to `authentication_mode { type = "password", passwords = [...] }` -
`access_string = "off ~* +@all"` is what actually disables the user; the password just satisfies
Valkey's hard requirement that every user have real password or IAM auth, even a disabled one.
Added the `random` provider (`~> 3.6`, not previously needed anywhere in `terraform/aws/`) to
`versions.tf`.

Re-planned against the live partial state (6 to add, 0 to change, 0 to destroy) before handing back
to the user - confirmed clean. **User re-ran `terraform apply` and it completed successfully: 6
added, 0 changed, 0 destroyed - AWS is now fully applied, 50 resources total**, including the
complete IAM-auth backport (IRSA role, both ElastiCache users, the user group, the connect policy).

## Done — Azure app-deploy layer: Bash scripts and k8s manifests written while AWS/GCP redeployed

User asked to keep working on Azure while AWS/GCP were being redeployed/tested, specifically
flagging that Bash script work was needed. Built the same app-deploy layer AWS/GCP already have,
mirroring their existing scripts' structure exactly rather than inventing a new shape:
`k8s/deploy-azure.sh`, `k8s/teardown-azure.sh`, `k8s/check-resources-azure.sh` (kubectl-layer),
`terraform/azure/check-resources-azure.sh` (Terraform-layer), plus `k8s/storageclass-azure.yaml`,
`k8s/traefik-azure.yaml`, `k8s/api-azure.yaml` (the last of these didn't exist in any form before
today).

Two real Azure-specific facts found via live web search before writing anything (not guessed,
matching this project's standing discipline): **AKS auto-creates a default StorageClass**
(`managed-csi`, Standard SSD LRS) the same way GKE does, unlike EKS - `deploy-azure.sh` un-defaults
it first, mirroring `deploy-gcp.sh`'s identical step; and **the Azure Disk CSI driver's
XFS-override parameter is `fsType` (plain camelCase)**, not the `csi.storage.k8s.io/fstype`
generic CSI key AWS's/GCP's drivers share - confirmed via the driver's own upstream docs
specifically to avoid silently carrying over a parameter name that happens to be wrong for this
one driver (the underlying reason for needing XFS at all - ext4's `lost+found` breaking Kafka's
LogManager on startup - is unchanged from AWS's/GCP's own earlier finding).

Also found: `deploy-azure.sh`/`teardown-azure.sh` need AKS's node resource group
(`MC_<rg>_<name>_<region>`, where a `type: LoadBalancer` Service's real Load Balancer/Public IP and
Kafka's real Managed Disks actually land) and Managed Redis's port, neither previously exposed as a
Terraform output. Added `node_resource_group` and `redis_port` (from `default_database[0].port`,
newly available since that block was added earlier today) to `outputs.tf` - confirmed via a real
`terraform plan` as output-only (`redis_port = 10000`, a real, worth-noting finding of its own:
Redis Enterprise's default port, not 6379) - **not yet applied to live state**, needed before
either script will actually work.

**`terraform/azure/check-resources-azure.sh` was run live** against the real, currently-applied
Azure infrastructure - the only piece of today's app-deploy-layer work actually exercised against
live state. First run surfaced one real, fixed bug: `az redisenterprise` is a
dynamically-installed CLI extension whose first invocation prints install warnings on stderr,
which the script's own `check()` function (deliberately) merges into captured output - fixed by
pre-installing the extension quietly up front, not by suppressing stderr generally (which would
have hidden real failures too). **Second run: 22/22 checks passed clean.** Every other new script
(`deploy-azure.sh`, `teardown-azure.sh`, `k8s/check-resources-azure.sh`) is only syntax-checked
(`bash -n`) so far, not live-tested - explicitly flagged as such, matching this project's own
repeated finding that every cloud's first real deploy attempt has found at least one real,
cloud-specific bug no amount of upfront research caught.

Updated `terraform/azure/README.md` with a new "App-deploy layer" section covering all of the
above, and reordered "What's next" to put applying the two new outputs and running a real
`deploy-azure.sh` first, ahead of the Lettuce credential-provider work.

## Done — AWS `deploy-aws.sh`: a real live crash-loop, root-caused, fixed, confirmed clean end-to-end

User ran `k8s/deploy-aws.sh` for real against the freshly-applied AWS infrastructure. `api` pods
crash-looped continuously (exit 137, killed by liveness probe) - root-caused as two compounding
issues, both confirmed live before fixing either:

**Issue 1 - probe margins too tight for real cloud conditions**: `kubectl describe pod` showed
both `connection refused` (probe fired before Tomcat bound - real measured Spring Boot startup was
~25s, exceeding readiness's `initialDelaySeconds: 20`) and, more importantly, `context deadline
exceeded` failures persisting up to 89 seconds into the container's life, long after the app's own
logs confirmed Tomcat was up. Fixed by raising `initialDelaySeconds` (readiness 20→30, liveness
30→45) and adding an explicit `timeoutSeconds: 5` (default is 1s) to all four `api*.yaml` variants
(`api.yaml`, `api-aws.yaml`, `api-gcp.yaml`, `api-azure.yaml`) for consistency - applied to GCP's
and the not-yet-tested Azure's manifests proactively, not just AWS's, since the underlying
mechanism (a real network-bound `/actuator/health` call) applies everywhere.

**Issue 2 - the real blocker, found after the probe fix still didn't resolve it**: even with a 5s
timeout, probes kept failing. Root-caused via a direct connectivity test (`kubectl run` a
`redis-cli PING` against the real ElastiCache endpoint from inside the cluster) rather than
guessed: the command hung indefinitely, never returning even past its own internal timeout wrapper
- confirming the actual mechanism, not just a symptom. Chain of causation: this session's own
`elasticache-iam-auth.tf` set `transit_encryption_enabled = true` (a hard AWS requirement for IAM
auth) and disabled ElastiCache's default user entirely, but the app's `spring.data.redis.*` client
config has no TLS flag at all - it speaks plaintext RESP to what's now a TLS-only endpoint, which
doesn't fail fast, it hangs. Because `spring-boot-starter-actuator` +
`spring-boot-starter-data-redis` are both on the classpath with no override, Spring Boot
auto-registers a Redis health check as part of the aggregate `/actuator/health` - so the hang took
down the *entire* health endpoint, not just Redis-dependent behavior, crash-looping the whole app.
A materially worse consequence than this session's earlier "Redis auth doesn't work yet" framing
had anticipated.

Presented as a real tradeoff via `AskUserQuestion` rather than resolved silently (disable the
Redis health check vs. revert the TLS requirement, undoing today's security work) - **user chose
disabling the health check**. Fixed: `management.health.redis.enabled: false` added to
`application.yml`'s "cloud" profile only (not local/test), with an extensive comment explaining
the full chain and citing this app's own already-documented cache-miss-fallback-to-Postgres design
(`docs/architecture.md`) as the reason this is a legitimate degraded state, not one that should
ever crash-loop the app. Rebuilt and pushed the `api` image, `kubectl rollout restart`ed -
**confirmed live: both `api` pods `1/1 Running`, 0 restarts**, `frontend` rolled out clean, the
real AWS LoadBalancer is up
(`a897d45647d3349f5a0a0211d1c17eba-2021832921.us-west-2.elb.amazonaws.com`). **AWS's app-deploy
layer is now fully live and healthy end-to-end** - the first of the three clouds to reach this bar
since today's IAM-auth backport began.

This same Redis-health-hang mechanism will hit GCP's and Azure's own first real deploys too (their
Memorystore/Managed Redis IAM-auth Terraform has the equivalent TLS-required, no-anonymous-access
posture) - the `management.health.redis.enabled: false` fix already applies cloud-wide (one
`application.yml` block, not per-cloud), so neither should need to rediscover this independently.

## Done — AWS wrap-up: full re-verification + a real HTTP smoke test, `terraform/aws/README.md` updated

User asked to close out AWS properly before moving on, since today's IAM-auth backport changed a
config that had already been confirmed clean in an earlier session. Re-ran both layers' resource
checks live rather than trusting the deploy script's own success output: `k8s/check-resources-aws.sh`
- **15/15 passed** (Traefik, Kafka's 3 replicas, `api`/`frontend` both fully ready, config/secrets/
routing, the `gp3` StorageClass) - on top of the Terraform layer's already-confirmed 24/24. Went a
step further than either script checks: a direct HTTP smoke test against the real LoadBalancer URL
(frontend `200`, and a real login against the seeded `demo`/`GridMeter!Demo2026` credentials
returning a real signed JWT) - confirms the app is genuinely serving real traffic through Postgres
and the JWT auth path, not just reporting `Running`/`Ready` at the kubectl level.

Rewrote `terraform/aws/README.md` to match: a new "Status" section at the top (fully applied and
live, both layers confirmed, not the original 2026-09-18 build), the ElastiCache row in "What this
creates" flagged IAM-auth-only, a full new "IAM-auth backport" section documenting both real bugs
found and fixed today (the Valkey `no-password-required` restriction, the Redis-TLS-health-hang
crash-loop) with the same detail level as `terraform/azure/README.md`'s equivalent sections, and
corrected "Explicitly out of scope" (removed the now-stale "GCP and Azure don't exist yet" line,
added the real remaining gaps - the Lettuce credential-provider code and the missing K8s
ServiceAccount object the new IRSA role is scoped to but can't be assumed by any pod yet).

## Done — user pushed back on "wrapped up": teardown-aws.sh had never actually been tested, and running it found a real bug

User's own QA framing: a wrap-up that only exercises the happy path (deploy) isn't actually
verified - teardown has to be run for real too. Ran `k8s/teardown-aws.sh` (kubectl/AWS-CLI only,
the auto-mode classifier correctly blocked my own first attempt to run it directly since it's a
real destructive action against live infrastructure - the user ran it themselves, matching this
project's established pattern for `terraform apply`/`destroy`).

**The script's own two documented jobs both worked correctly and were confirmed via real polling,
not assumed**: the LoadBalancer was deleted and confirmed gone, Kafka's StatefulSet/PVCs were
deleted and the real EBS volumes confirmed gone. `k8s/check-resources-aws.sh` run afterward showed
5 failures - but four of those are *expected* (checking for the LoadBalancer/Kafka the teardown
had just correctly removed), not bugs.

**The 5th failure was real and unexpected**: `api Deployment ready: expected '2/2', got '/2'` -
both `api` pods were in `CrashLoopBackOff`, 5+ restarts each. Root-caused via `kubectl describe`
and `kubectl logs`, not guessed: `org.apache.kafka.common.config.ConfigException: No resolvable
bootstrap urls given in bootstrap.servers`, thrown while Spring's
`internalKafkaListenerEndpointRegistry` lifecycle bean tries to start - `@KafkaListener` container
creation is eager, not lazy, and `kafka-headless`'s per-pod DNS records
(`kafka-0.kafka-headless` etc.) stop resolving the instant the StatefulSet's pods are gone. This
fails the entire `ApplicationContext` refresh, not just a health check - `api` couldn't even start,
let alone serve traffic, and kept crash-looping indefinitely. A materially different, more severe
mechanism than the earlier Redis finding (that was a health-check hang after a successful startup;
this is a hard startup failure), but the same *shape* of root cause as GCP's own
`teardown-gcp.sh` Step 1 fix from an earlier session (an `api` Deployment left running against
infrastructure actively being torn out from under it) - `teardown-aws.sh` had simply never gotten
the equivalent fix.

**Fixed `teardown-aws.sh`**: added a new Step 1 (`kubectl scale deployment api --replicas=0`,
wait for pods to fully terminate) before anything else runs, renumbered the existing
LoadBalancer/Kafka steps to 2/3, and documented the mechanism in the script's own header comment
alongside its two original reasons - matching how `teardown-gcp.sh` documented its own equivalent
fix as a distinct, numbered reason rather than folding it into an existing one. Manually brought
the live cluster back in line with what the corrected script would have produced (`kubectl scale
deployment api --replicas=0`, confirmed pods terminated cleanly) rather than leaving the crash loop
running.

## Done — the fix confirmed for real: full redeploy → confirm → teardown → confirm cycle, clean

User's own framing after the last item: clearing the user misconception first (only `kind` runs
locally on Docker Desktop; AWS/GCP/Azure each run a real, separate managed cluster in that cloud's
own datacenters, with Docker Desktop used only as the image-build machine - and the real reason not
to run all three `deploy-*.sh` scripts concurrently is that none of them pin an explicit `kubectl
--context`, so parallel runs could clobber the shared `~/.kube/config` current-context mid-run, not
because k8s is somehow all-local), then ran the actual re-verification cycle the QA framing called
for: redeploy AWS for real (`k8s/deploy-aws.sh`, clean - both real resource checks 39/39, a fresh
HTTP smoke test with a new login/JWT), then tear it down again with the fixed `teardown-aws.sh`.

**Confirmed live: no crash loop this time.** `kubectl get pods -A` after teardown showed zero
`api` pods at all (Step 1 scaled it to 0 and confirmed termination before Kafka was ever touched) -
contrast with the first teardown attempt, where `api` pods existed and were stuck in
`CrashLoopBackOff`. `k8s/check-resources-aws.sh` afterward showed the same 5 "failures" as before,
but this time all 5 are expected (exactly what Steps 1-3 intentionally removed -
`api`'s `/0` desired-replica count, not a crash signature), with none of the earlier unexpected
6th failure. The bug was reproduced once, the fix was applied, and the identical scenario re-run
end-to-end came back clean - not just reasoned about as correct.

Current real state: `api`/`traefik-web`/Kafka's StatefulSet+PVCs all cleanly removed;
`frontend`/`traefik`(Deployment)/`kafka-headless`(Service) still present, matching the script's
documented scope; EKS cluster/RDS/ElastiCache/IAM all still live and Terraform-tracked. AWS is
mid-teardown, not fully torn down (`terraform destroy` not yet run) or currently deployed.

## Done — AWS fully torn down for real, `terraform destroy` clean, independently confirmed against live APIs

User asked to finish tearing AWS down completely so it stops accruing charges - explained the real
difference between `terraform apply "tfplan-destroy"` (applies a frozen saved plan, no prompt) and
plain `terraform destroy` (computes its own fresh plan, requires a typed `yes`) before the user ran
it, per the README's documented two-step review-then-destroy flow. Also found and cleared three
stale local plan files (`tfplan`, `tfplan2`, `tfplan-destroy`, all predating today's several
deploy/teardown cycles) before generating a fresh destroy plan - confirmed all three were already
covered by `terraform/.gitignore`'s `tfplan*` pattern, so never at risk of being committed, but
worth clearing for unambiguous review before an irreversible action.

**`terraform destroy` completed clean: 51 resources destroyed, zero errors.** Runtime dominated by
the same two resources that were slowest to create - `aws_eks_node_group.main` (10m15s) and
`aws_elasticache_replication_group.main` (4m34s) - consistent with their original creation times,
not a new finding. `terraform show` confirms empty state.

**Independently verified against 9 real AWS API checks (not just trusting "Destroy complete")**,
per the README's "Confirm no residue" section: EKS cluster, EC2 worker instances, load balancers
(both `elbv2` and classic `elb` APIs), EBS volumes, NAT gateway, RDS instance, ElastiCache
replication group, and the RDS-managed Secrets Manager secret - **all 9 returned empty.** AWS is
genuinely, fully torn down, not just reported as such. `check-resources-aws.sh` correctly failed
afterward (it reads cluster identity from `terraform output`, which no longer exists with empty
state) - expected, not a bug. `check-costs-aws.sh` still shows stale pre-teardown data per its own
documented 24-48h Cost Explorer lag - worth a follow-up re-run in a day or two as a second,
independent cost confirmation, not needed to trust today's teardown.

**This closes the loop the user's "confirm everything" QA framing opened**: a real bug was found
running teardown for the first time ever, fixed, and the entire cycle (deploy → confirm → teardown
→ confirm → full destroy → confirm) was re-run end-to-end rather than assumed fixed from reasoning
alone. AWS is now the only cloud this session with a fully closed, zero-residue-confirmed teardown
story to match its earlier deploy confidence.

## Done — GCP's retry succeeded: both real bugs from the first attempt confirmed fixed

User retried the interrupted GCP apply (`terraform apply tfplan2`, the saved plan targeting just
the two failed resources). Both fixes held:

- **`google_service_account_iam_member.app_workload_identity`** - the `depends_on
  [google_container_cluster.main]` fix added earlier applied cleanly (4s, no error) - confirms the
  root cause (the binding racing the cluster's own Workload Identity Pool creation) was correctly
  diagnosed, not just plausibly guessed.
- **The `GCE_STOCKOUT` in `us-central1-b`** - confirmed genuinely transient, as expected for a
  capacity issue rather than a config problem: the broken node pool was destroyed (2m53s) and
  recreated successfully (1m54s) on retry, this time landing fine in the same zone that failed
  before. No zone swap was needed - the "retry as-is" choice paid off.

`terraform apply tfplan2` completed clean: 2 added, 0 changed, 1 destroyed.
`check-resources-gcp.sh` confirms **17/17** real resource checks pass - VPC/subnet/router/NAT/PSA
peering, GKE cluster + node pool `RUNNING`, all 4 GCE worker instances `RUNNING` (3 from the main
pool across zones + 1 from the extra pool), Cloud SQL `RUNNABLE` on Postgres 18, Memorystore
`ACTIVE` on Valkey 9.0, both Artifact Registry repos, and the Secret Manager secret. **GCP's
Terraform layer now matches AWS's confidence bar** - IAM-auth backport fully live and verified, not
just planned.

## Done — GCP app-deploy layer redeployed clean, matching AWS's full confidence bar

User ran `k8s/deploy-gcp.sh` for real against the confirmed-clean GCP Terraform. Zero errors across
the entire pipeline - image build/push, Traefik/StorageClass/Kafka/api/frontend apply, all
rollouts. **`k8s/check-resources-gcp.sh` (kubectl-layer, separate from the Terraform-layer script
of the same name in `terraform/gcp/`) confirms 15/15** - critically, `api Deployment ready: 2/2`
clean, no repeat of AWS's Redis-TLS-health-hang crash-loop. Confirmed directly: both `api` pods
`0` restarts. A real HTTP smoke test (frontend `200`, login with the seeded `demo` credentials
issuing a real JWT) confirms actual functionality, not just `kubectl`-reported readiness - same
depth of verification AWS got.

**This cross-cloud-confirms the `management.health.redis.enabled: false` fix from earlier**:
GCP's Memorystore now requires the same IAM-auth-plus-TLS posture as AWS's ElastiCache (today's
backport), which would have caused the identical health-check-hang crash-loop here too without
that fix already being in place project-wide (one `application.yml` change, not per-cloud) -
exactly as predicted when the fix was made. GCP never needed to rediscover the bug independently.

`estimate-costs-gcp.sh` also re-run for the first time against this session's live inventory:
~$169.80/mo if left running (4 nodes now, not 3 - the extra single-zone node pool from an earlier
session's overcommitment fix - plus Memorystore, Cloud SQL, Cloud NAT, the external forwarding
rule, and Kafka's PVCs). **GCP now matches AWS's full deploy-confirm confidence bar** (Terraform
17/17 + app-deploy 15/15 + HTTP smoke test).

## Done — GCP fully torn down for real, `terraform destroy` clean, independently confirmed against live APIs

User chose to tear GCP down completely to match AWS's zero-residue bar, mirroring the same
teardown → destroy → residue-check cycle end to end.

`k8s/teardown-gcp.sh` ran clean - all three of its steps (scale `api` to 0 releasing live Cloud SQL
connections, delete the LoadBalancer Service + confirm the real forwarding rule gone, delete
Kafka's StatefulSet/PVCs + confirm the real persistent disks gone) completed without incident. This
script already had its own live-found `api`-scale-to-0 fix from an earlier session (the original
motivation for AWS's own equivalent fix today), so nothing new was found here - it held up on
reuse, as expected.

**`terraform destroy` completed clean: 25 resources destroyed, zero errors.** Runtime dominated by
`google_memorystore_instance.main` (8m16s) and `google_container_cluster.main` (4m13s) - both
consistent with their original creation times (9m47s and 26m21s respectively), not a new finding.
`terraform show`/`terraform state list` both confirm empty state.

**Independently verified against 9 real GCP API checks** (mirroring AWS's residue-check depth,
adapted to GCP's own resource shapes): GKE cluster, GCE worker instances, forwarding rules/load
balancer, persistent disks, Cloud SQL instance, Memorystore instance, Secret Manager secret,
Artifact Registry repos, and the VPC network - **all 9 returned empty** ("Listed 0 items", GCP's
own equivalent of AWS's `[]`). GCP is genuinely, fully torn down, not just reported as such.

**Both AWS and GCP now share the identical, strongest confidence bar this session established**:
Terraform applied and confirmed live, app-deploy layer confirmed live with a real HTTP smoke test,
then torn down and independently confirmed zero-residue against real cloud APIs - not assumed
correct from "Destroy complete" alone at any step.

## Done — built `terraform/azure/check-costs-azure.sh`, closing Azure's last documented script gap

User flagged Azure still lacked a cost-check script, the one piece AWS (`check-costs-aws.sh`) and
GCP (`estimate-costs-gcp.sh`) both already had. Investigated live rather than assumed before
building anything: `az consumption usage list` (no extra extension needed) looked like the obvious
first choice, but every cost/quantity/date field it returns came back as a literal `"None"` string
- unusable. The `costmanagement` CLI extension, once installed, only exposes
`export`/`show-operation-result` subcommands - no ad-hoc query command, despite the underlying
`Microsoft.CostManagement/query` REST API fully supporting one. Called that REST API directly via
`az rest` instead, confirmed live it returns real structured billing data grouped by service and
date.

**This is a genuine structural advantage over GCP's own cost script**: `check-costs-azure.sh` gets
real billing data with zero export/setup prerequisite, unlike `estimate-costs-gcp.sh`, which had to
fall back to a list-price estimate because GCP's BigQuery billing export was never configured.
Built mirroring `check-costs-aws.sh`'s structure (per-day, per-service breakdown, `$0.00` shown
explicitly for days with no line items, not silently omitted).

Ran it live against the real subscription - confirmed the same billing-lag limitation AWS's and
GCP's own cost checks already established, now for a third cloud: a query run against this
session's fully live AKS/Postgres/Managed Redis deployment (applied and running the entire
session) still showed only the bootstrap Storage Account's negligible cost, nothing for the
actually-running compute. Documented explicitly in the script's own header and in
`terraform/azure/README.md`'s new "Cost check" section - this is expected, not a bug, and matches
the pattern already established for the other two clouds.

Also fixed a user-environment issue along the way (not a bug in anything built): `kubectl`'s
current context was still pointed at GCP's now-destroyed GKE cluster (the `i/o timeout` error was
against GCP's real, now-gone control-plane IP) - pointed it back at AKS via the
`kubeconfig_update_command` output.

## Done — Azure's app-deploy layer confirmed live end-to-end - the last untested piece across all three clouds

Applied the two pending outputs for real (`terraform apply`, output-only, `0 added, 0 changed, 0
destroyed`, both `node_resource_group`/`redis_port` now in state) - this unblocked
`k8s/deploy-azure.sh`, which had failed immediately on a `KeyError: 'redis_port'` on its first
attempt (expected, exactly as the README had flagged - not a new bug).

**`k8s/deploy-azure.sh` ran clean: every `kubectl apply` step showed `created`, all rollouts
succeeded, real LoadBalancer IP assigned.** Re-confirmed independently: `terraform/azure/
check-resources-azure.sh` 22/22, `k8s/check-resources-azure.sh` 15/15, and a real HTTP smoke test
(frontend `200`, login with the seeded `demo` credentials issuing a real JWT) - Postgres/Kafka/
JWT-auth all genuinely work end to end on Azure, matching AWS's and GCP's own confirmation depth.
Redis stays unauthenticated as already documented (the Lettuce credential-provider gap); the
health-check fix keeps this from crash-looping the app, exactly as it did on AWS/GCP.

**One real, honestly-reported anomaly, not swept under the rug**: one of the two `api` pods
restarted once during this deploy. `kubectl describe` showed the same "connection refused" probe
signature as the earlier AWS timing bug, but a *single* occurrence, self-resolved (0 restarts
since) - not a repeat of today's crash-loop-class bugs, which looped indefinitely until fixed.
Plausible cause: first-ever cold image pull + JVM start on that specific AKS node pushed just past
the existing 45s liveness margin once. Not chased further since it didn't block or recur - flagged
in `terraform/azure/README.md` as a known, low-severity data point in case it becomes a pattern on
future Azure deploys.

**This closes the loop on the one piece that had been untested live across all three clouds all
session** - Azure's Terraform layer was already fully confirmed; its app-deploy layer now is too.

## Done — Azure fully torn down for real, `terraform destroy` clean, independently confirmed against live APIs

User ran the full teardown cycle: `k8s/teardown-azure.sh` first (clean on its first-ever real run -
see the script's own updated header comment - no new bugs found, a first among the three clouds'
teardown scripts), then a real `terraform destroy`.

**`terraform destroy` completed clean: 20 resources destroyed, zero errors.** Runtime dominated by
`azurerm_kubernetes_cluster.main` (4m43s) and `azurerm_managed_redis.main` (3m20s) - both
consistent with their original creation times, not a new finding. `terraform state list`/
`terraform show` both confirm empty state.

**Independently verified against 8 real Azure API checks** - Azure has one extra-strong check
neither AWS nor GCP has available: ARM resource groups are a hard containment boundary, so
confirming both the main resource group and AKS's auto-created node resource group
(`MC_grid-meter-app-rg_grid-meter-app-aks_centralus`) are gone is itself authoritative proof
everything inside them is gone too. Checked individually anyway for parity with AWS's/GCP's own
residue-check depth: AKS cluster, Postgres Flexible Server, Managed Redis, Key Vault, ACR, and the
VNet (subscription-wide, not resource-group-scoped) - **all 8 checks confirmed empty/gone.** Azure
is genuinely, fully torn down, not just reported as such. `check-resources-azure.sh` correctly
failed afterward with the same expected "has terraform apply been run yet?" guard AWS's/GCP's
identical scripts show - expected, not a bug.

**All three clouds now share the identical, strongest confidence bar this session established,
completing the full cycle for all of them**: Terraform applied and confirmed live, app-deploy
layer confirmed live with a real HTTP smoke test, then torn down and independently confirmed
zero-residue against real cloud APIs - not assumed correct from "Destroy complete" alone at any
step, for any cloud.

## Done — AWS Lettuce credential-provider scoped and implemented, with unit tests

User's explicit sequencing after the 3-cloud teardown write-up above: "commit and push, then move
forward with code changes, then retest one platform at a time." AWS scoped and implemented first,
not all three at once - GCP/Azure deliberately left for later, separate sessions.

Grounded the design against real, installed artifacts rather than memory of the Spring/Lettuce
APIs, per this project's standing discipline: `javap`/`unzip -l` against the actual installed
`spring-boot-data-redis-4.1.0`/`spring-data-redis-4.1.0`/`lettuce-core-7.5.2.RELEASE` jars
confirmed the real extension point is `LettuceClientConfiguration.LettuceClientConfigurationBuilder
.redisCredentialsProviderFactory(RedisCredentialsProviderFactory)`, wired via a Spring Boot
`LettuceClientConfigurationBuilderCustomizer` bean - not a full `RedisStandaloneConfiguration`/
`LettuceConnectionFactory` override, and not Lettuce's own `RedisURI.Builder.withAuthentication`
(the wiring point an initial pass had assumed before checking).

Pulled AWS's own reference implementation (`aws-samples/elasticache-iam-auth-demo-app`, via `gh
api`) rather than hand-deriving the SigV4 token construction - this caught a real, non-obvious fact
before it became a bug: the reference app's `pom.xml` had already moved off the older
`auth`-module `Aws4Signer` onto the newer `AwsV4HttpSigner` (`http-auth-aws` module, the SRA
signer redesign), confirmed by reading its actual current source rather than an older
tutorial/pattern. Also confirmed AWS's reference implementation uses Lettuce's one-shot
`resolveCredentials()` with a hand-cached/memoized token (10-minute cache against the token's real
15-minute TTL), not the streaming `Flux`-based variant an initial pass had assumed was the better
fit - deviating from AWS's own verified-working pattern for no reason would have added risk, not
value.

**New code** (`api/src/main/java/com/gridmeter/api/config/aws/`): `ElastiCacheAuthTokenRequest`
(builds the signed token), `AwsElastiCacheCredentialsProvider` (Lettuce `RedisCredentialsProvider`,
hand-rolled cache/expiry - no Guava dependency added just for `Suppliers.memoizeWithExpiration`,
matching this project's minimal-footprint ethos), `AwsRedisConfig` (`@Profile("cloud-aws")` bean
wiring, also sets `.useSsl()` since ElastiCache's IAM auth requires TLS). `pom.xml`: added
`software.amazon.awssdk:auth` + `http-auth-aws` via the `software.amazon.awssdk:bom` (version
2.46.7, confirmed authoritatively via Maven Central's own search API after web-search snippets for
this artifact returned conflicting numbers) - deliberately not AWS's own reference `pom.xml`'s
`aws-sdk-java` mega-artifact, wildly disproportionate to "sign one SigV4 request."

**6 new unit tests**, no mocks for the signer itself (it's a deterministic, offline operation -
the token is never actually sent over the network): `ElastiCacheAuthTokenRequestTest` exercises
the real `AwsV4HttpSigner` against fake static credentials and asserts the token's shape (one
assertion needed fixing after a real run showed the credential scope is URL-encoded, `%2F` not
`/` - caught by actually running the test, not assumed). `AwsElastiCacheCredentialsProviderTest`
verifies cache-hit/regenerate-after-expiry behavior via a controllable fake `Clock`, this project's
own "poll/control time, don't sleep" testing discipline applied to a unit test instead of an
infrastructure script - no real 10-minute wait.

**Full existing suite re-run after the `pom.xml` change, per the user's own explicitly-validated
concern that a dependency addition warrants re-running everything**: 98/98 tests clean across all
21 test classes (including the 2 new ones), zero regressions from the new AWS SDK dependency.

## Done — wired the new AWS code into the k8s/Terraform layer so a real pod can actually use it

The credential-provider code alone was inert without this - `terraform/aws/elasticache-iam-auth.tf`
(from earlier today) already expected a K8s ServiceAccount named exactly `grid-meter-app` in
namespace `default` that didn't exist yet in any manifest.

`terraform/aws/outputs.tf`: 3 new outputs (`app_irsa_role_arn`, `elasticache_app_user_id`,
`elasticache_replication_group_id`) - none of these existed before since nothing consumed them
yet; `terraform validate` clean. `k8s/api-aws.yaml`: new `ServiceAccount` object (`grid-meter-app`,
annotated `eks.amazonaws.com/role-arn` with a placeholder, same pattern as the existing image
placeholder) + `serviceAccountName` on the pod spec, plus 3 new env vars (`AWS_REGION`,
`GRID_METER_AWS_ELASTICACHE_USER_ID`, `GRID_METER_AWS_ELASTICACHE_REPLICATION_GROUP_ID`) feeding
`AwsRedisConfig`. `k8s/deploy-aws.sh`: reads the 3 new Terraform outputs, changed
`SPRING_PROFILES_ACTIVE` from `cloud` to `cloud,cloud-aws` (activates the new profile-gated bean
tree without touching GCP's/Azure's still-shared `cloud` profile), sed-substitutes the IRSA role
ARN alongside the existing image substitution. `application.yml`: new `cloud-aws`-profile-activation
block (env vars read directly via `@Value("${ENV_VAR_NAME}")`, matching `SPRING_DATA_REDIS_HOST`'s
existing direct-placeholder convention - an initial pass had added an unnecessary intermediate
`grid-meter.aws.elasticache.*` property path, removed once inconsistency was noticed).

**Important, explicitly-flagged gap**: none of this was ever actually deployed against a live pod
before AWS was torn down again tonight (see below) - the credential-provider code compiles and its
unit tests pass, but a real, live IAM-auth Redis connection from a running pod has **not** been
confirmed. This is still open, not silently assumed working.

## Done — tonight's shutdown: a real context-mismatch bug found and fixed before it could hide a false "clean" teardown

User asked to shut resources down for the night. First `k8s/teardown-aws.sh` run reported all
three steps as "nothing found - already deleted, or never created" - but the script's own printed
`Current context: grid-meter-app-aks` gave it away: that's the Azure AKS context name, not AWS's
EKS cluster, the same class of stale-context bug found earlier this session on GCP. The user typed
`y` past the script's own confirmation prompt without noticing, so it ran clean against the wrong
(and already-destroyed) cluster - a false "nothing to clean up," not real confirmation.

Root-caused before fixing: `kubectl config use-context` to the existing EKS context entry
(`arn:aws:eks:...:cluster/grid-meter-app-eks`, already present in `~/.kube/config`) still failed
with a DNS resolution error against its cached endpoint hostname - the cached entry itself was
stale, most likely from an earlier point in the session before the EKS cluster was recreated
(a recreated cluster gets a new control-plane endpoint hostname; the old cached one simply stops
resolving, permanently). Fixed by regenerating it fresh (`aws eks update-kubeconfig --name
grid-meter-app-eks --region us-west-2 --profile grid-meter`), confirmed via `kubectl get nodes`
(3 real nodes, healthy, `4h52m` old).

**Re-running both scripts against the now-correct context showed the real state, for the right
reason this time**: `kubectl get pods -A` showed only `kube-system` pods - no `api`/`traefik`/
`kafka`/`frontend` had ever actually been deployed onto this particular cluster incarnation (the
EKS cluster itself was live and Terraform-tracked, but the app layer above it genuinely was never
applied tonight). `k8s/check-resources-aws.sh` re-run against the correct context returned clean
real `NotFound` responses from the live API server (not DNS failures) for all 15 checks - correctly
confirming there was nothing for `teardown-aws.sh` to do, this time as a verified fact rather than
an accidental-right-answer-for-the-wrong-reason.

User then ran `terraform destroy` directly (safe, since the k8s layer was independently confirmed
empty first) - **confirmed complete: AWS Terraform state is now empty (0 resources)**, checked
directly via `terraform show -json` after the destroy.

## Open

- **Azure and GCP are fully closed out and fully torn down**, matching bars established earlier
  today: Azure (Terraform 22/22, app-deploy 15/15 + HTTP smoke test, `terraform destroy` 20
  resources/zero errors, 8/8 residue checks empty); GCP (Terraform 17/17, app-deploy 15/15 + HTTP
  smoke test, `terraform destroy` 25 resources/zero errors, 9/9 residue checks empty). Zero
  resources remain on either. Neither has the Lettuce credential-provider work yet - still fully
  password/legacy-auth-inert on Redis until their own scoping pass, same as AWS was before tonight.
- **AWS is fully torn down again as of tonight (0 resources in Terraform state, confirmed via
  `terraform show -json`)** - but this teardown followed a session that added real, uncommitted
  code (the Lettuce credential-provider implementation) that was never actually exercised against
  a live pod before teardown. The code compiles and its 6 new unit tests pass (98/98 full suite,
  zero regressions), and the Terraform/k8s wiring to make it reachable (IRSA role ARN, ElastiCache
  user ID/replication group ID outputs, the `grid-meter-app` ServiceAccount, the `cloud-aws`
  profile) is all in place - but **a real, live IAM-auth Redis connection from a running AWS pod
  has never been confirmed.** This is the single most important open item: the next AWS redeploy
  needs to specifically verify this (watch `kubectl logs` while hitting a Redis-touching endpoint,
  per the directions given tonight), not just confirm the app comes up healthy the way
  `management.health.redis.enabled: false` already lets it do regardless of whether Redis auth
  actually works.
- **A real stale-kubeconfig bug was found and fixed tonight, same class as an earlier GCP finding**:
  an EKS context entry in `~/.kube/config` had a dead cached control-plane endpoint (most likely
  from the cluster being recreated earlier in the session), and separately the *current* context
  was still pointed at Azure's already-destroyed AKS cluster - both silently produce a false
  "nothing found" from `teardown-aws.sh`/`check-resources-aws.sh` rather than an error a user would
  necessarily catch from the confirmation prompt alone. Worth remembering for any future multi-
  cloud session: always sanity-check `kubectl config current-context` explicitly (not just trust a
  script's own printed context line) after switching between clouds, and regenerate
  (`aws eks update-kubeconfig`/`az aks get-credentials`/`gcloud container clusters get-credentials`)
  rather than assume an existing cached context entry is still valid if a cluster may have been
  recreated since it was generated.
- **AWS's new code (`config/aws/`, its tests, the `pom.xml`/`application.yml`/Terraform/k8s
  changes) is uncommitted** as of this write-up - deliberately not committed yet, since the live
  IAM-auth connection point above is still unverified. Committing before that live check would
  mean committing code with an untested critical path, at odds with this project's own
  "verify live before trusting" discipline throughout today.
- **GCP's and Azure's own Lettuce credential-provider work hasn't been started** - explicitly
  sequenced after AWS's (scope → implement → retest one cloud at a time, the user's own directive),
  not attempted in parallel.

## Next

1. **Redeploy AWS and confirm the IAM-auth Redis connection actually works live** - the one
   real unverified piece of tonight's work. `k8s/deploy-aws.sh` now provisions everything needed
   (ServiceAccount, IRSA role annotation, the 3 new env vars); after it runs, use the
   `kubectl logs -f` + Redis-touching-endpoint approach from tonight's conversation to confirm no
   `NOAUTH`/`WRONGPASS`/`RedisConnectionException` shows up. Only once that's confirmed does it
   make sense to re-enable `management.health.redis.enabled` for the `cloud-aws` case specifically
   (leave GCP's/Azure's `cloud` profile disabled until their own credential-provider work lands -
   re-enabling it project-wide now would crash-loop GCP/Azure again).
2. Commit AWS's credential-provider work once step 1 confirms it live - not before.
3. **GCP's and Azure's own Lettuce credential-provider implementations**, one at a time, following
   the same scope-first pattern AWS's just went through (real jar/API inspection, a real reference
   implementation to ground the token mechanism against, unit tests with a controllable fake
   `Clock`, full-suite re-run after any `pom.xml` change) - GCP's IAM token and Azure's Entra ID
   `WorkloadIdentityCredential` will each need their own equivalent research pass, not a copy-paste
   of AWS's SigV4 mechanism.
4. Longer-carried items: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost fix,
   `docs/testing-expansion-scope.md` task #9+.
