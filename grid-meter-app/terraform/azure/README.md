# terraform/azure

Provisions the Azure infrastructure `grid-meter-app` runs on in the cloud: a VNet, an AKS
cluster + node pool, a managed Azure Database for PostgreSQL Flexible Server, Azure Managed Redis,
and an Azure Container Registry. The app-deploy layer (`k8s/deploy-azure.sh`, ACR image build/push,
Azure-specific k8s manifest variants) now exists too and has been confirmed live end-to-end - see
"App-deploy layer" below.

See `docs/cloud-deployment-scope.md` for the full per-layer reasoning (why Postgres/Redis are
managed here but Kafka is self-hosted in-cluster identically across every target — `kind`, AWS,
GCP, and this), and `docs/identity.md`/this file's own "Real findings" section for the specific
Azure identity-model context that kicked this pass off (Microsoft Entra ID vs. Azure Resource
Manager being two genuinely separate control planes — see below).

## Status: fully torn down, zero residue confirmed (2026-09-23)

The full cycle is now complete and independently verified: `terraform apply` (live, both layers
confirmed - 22/22 Terraform-layer checks, 15/15 kubectl-layer checks, a real HTTP smoke test with
a real login/JWT via `k8s/deploy-azure.sh`), then `k8s/teardown-azure.sh` (clean on its first real
run, no new bugs) and `terraform destroy` (20 resources, zero errors). **8 independent residue
checks against real Azure APIs all confirmed empty/gone** - see "Teardown" below. This matches
AWS's/GCP's own zero-residue confidence bar exactly - all three clouds now share the same
deploy-confirm-teardown-confirm cycle, none of it assumed correct from tool output alone.

To bring this back up: `cd terraform/azure && terraform init && terraform plan -out tfplan &&
terraform apply tfplan`, then `../../k8s/deploy-azure.sh` - see "Usage" and "App-deploy layer"
below.

This pass went from plan-only to a real, twice-partially-failed, twice-fixed live apply — three
separate real platform errors were found and fixed along the way, all live-verified, none guessed.
See "Real findings" below for the full account.

## Prerequisites

1. `az login` (authenticates the CLI; the `azurerm` provider auto-detects this session rather than
   needing a dedicated service principal, matching AWS's/GCP's own "authenticate via the
   already-logged-in CLI" pattern).
2. An Azure subscription with billing set up. This pass used a brand-new personal Microsoft
   account with zero prior Azure usage — confirmed live that a real (non-virtual, non-prepaid)
   card plus phone verification is required even for the free trial ($200 credit / 30 days, 12
   months of select free services), the same pattern GCP's own trial signup had.
3. **Resource provider registration** — a genuinely new-to-this-project prerequisite step neither
   AWS nor GCP needed in the same shape. A fresh Azure subscription starts with essentially none
   of Azure's hundreds of resource-provider namespaces registered; the very first real
   `terraform apply` (bootstrap module) failed outright with `MissingSubscriptionRegistration`
   until `Microsoft.Storage` was registered. Registered every namespace this project's full stack
   will touch up front rather than hit this once per service:
   ```bash
   for ns in Microsoft.Storage Microsoft.ContainerService Microsoft.DBforPostgreSQL \
             Microsoft.Cache Microsoft.ContainerRegistry Microsoft.Network Microsoft.Compute \
             Microsoft.OperationalInsights Microsoft.Insights Microsoft.KeyVault \
             Microsoft.ManagedIdentity; do
     az provider register --namespace "$ns" --wait
   done
   ```
   (`Microsoft.KeyVault`/`Microsoft.ManagedIdentity` were missed in the original list and only
   caught by a live apply failure - see "Real findings." `az provider list --output table` shows
   hundreds of other namespaces still `NotRegistered` - that's expected; only the ones above are
   needed here.) Note the `azurerm` provider block also exposes
   `resource_provider_registrations`/`resource_providers_to_register` attributes that can handle
   this from Terraform itself - not used this pass since registration was already done manually
   before that was noticed, worth considering for a from-scratch subscription next time.
4. Terraform >= 1.11.0 (same floor as AWS/GCP).
5. `kubectl` installed, for interacting with the cluster once it exists.
6. `TF_CLI_ARGS="-no-color"` and `az config set core.no_color=true` set persistently (both
   confirmed live, 2026-09-22) - accessibility fixes for this user, unrelated to correctness, but
   worth keeping in the prerequisites list since they're now standing environment setup.

## Real findings (2026-09-22 through 2026-09-23)

Checked live rather than assumed, same discipline as the AWS/GCP passes. Grouped by when they
surfaced - the first batch below was already in the 2026-09-22 plan-only pass; everything after
"First live apply" only showed up once real resources actually started provisioning, which is
exactly why this project treats a clean `plan`/`validate` as necessary but not sufficient.

### Found before any apply (`validate`-time / provider-schema research)

- **Identity is genuinely split into two separate control planes** - the specific thing this pass
  was kicked off to explore. Microsoft Entra ID (formerly Azure AD) is tenant-scoped identity
  (users, groups, app registrations, service principals); Azure Resource Manager is
  subscription/resource-scoped authorization. Terraform models this as two separate providers,
  `azurerm` (ARM) and `azuread` (Entra ID) - this config only ever needed `azurerm`, since AKS's
  managed identities (cluster identity, kubelet identity, and now the app's own workload identity)
  are native to `azurerm` and Terraform authenticates via the already-logged-in `az` CLI rather
  than a Terraform-provisioned service principal.
- **AKS explicitly doesn't support/recommend B-series (burstable) VMs for system node pools**,
  despite B-series technically meeting the documented 2-vCPU/4GB minimum - a real platform-specific
  constraint neither AWS's EKS (t3.medium, burstable) nor GCP's GKE (e2-medium) has.
- **Postgres Flexible Server, unlike AKS node pools, DOES support Burstable (B-series) SKUs** -
  `B_Standard_B1ms`, matching AWS's db.t4g.micro/GCP's db-f1-micro cost-conscious sizing exactly. A
  real, worth-noting contrast with the AKS finding above, not an inconsistency.
  - PostgreSQL 18 confirmed GA on Azure Flexible Server, matching this project's stack pin exactly.
  - `storage_mb` is a fixed enum (32768/65536/131072/...), not an arbitrary GB integer - 32768
    (32GB) confirmed live as both the actual minimum and the default.
  - No AWS-RDS-style `manage_master_user_password` convenience - the same gap GCP's Cloud SQL had.
    Wired up the same substitute: `random_password` + Azure Key Vault, filling Secret Manager's role.
  - Private networking needs its own dedicated, delegated subnet PLUS a private DNS zone plus a
    VNet link - genuinely more moving parts than AWS's private-subnet-placement or GCP's
    shared-PSA-range approach.
- **ACR is a single registry holding multiple image repositories by path**, the same structural
  model as GCP's Artifact Registry, not AWS ECR's repo-per-image model.
- **AKS auto-creates a second, hidden Resource Group** (`MC_<rg>_<name>_<region>`) to hold the
  actual VM scale set/node NICs/load balancer - neither AWS's EKS nor GCP's GKE has an equivalent.
  Nothing to declare for it; just don't mistake it for drift later.
- **`azurerm_key_vault`'s RBAC-mode attribute is `rbac_authorization_enabled`**, not the
  `enable_rbac_authorization` name some still-current docs/examples show;
  `azurerm_private_dns_zone_virtual_network_link` takes `private_dns_zone_id` (not
  `private_dns_zone_name`) with no `resource_group_name` argument at all - both caught by
  `validate` before ever reaching a live API call.
- **A `node_provisioning_profile` block became required on `azurerm_kubernetes_cluster` as of
  azurerm 5.x** - `mode = "Manual"` opts out of AKS's newer Node Auto-Provisioning, keeping the
  fixed-size `default_node_pool` as the only node-management mechanism.

### First live apply (2026-09-23, eastus) - three real platform errors

- **AKS rejected `zones = ["1","2","3"]`** with `AvailabilityZoneNotSupported`. Checked live via
  `az vm list-skus` across eastus/eastus2/centralus for the same VM size - all three showed
  identical `NotAvailableForSubscription` restrictions on every zone, confirming this is a
  **subscription-tier-wide restriction** (a free-trial quota limit), not region- or VM-size-specific.
  Fixed by defaulting `aks_availability_zones` to `[]` and only setting the node pool's `zones`
  argument (as `null`, not `[]` - a real, deliberate distinction) when non-empty.
- **`Microsoft.KeyVault` was never registered** - a real oversight in this project's own
  provider-registration pass, not a platform surprise. Fixed live, added to the prerequisites list
  above so it isn't missed again.
- **Postgres Flexible Server provisioning is entirely blocked in `eastus`** for this subscription -
  `az postgres flexible-server list-skus --location eastus` returns `"reason": "Provisioning is
  restricted in this region"`. Checked live across 5 candidate regions: `eastus`/`eastus2`/
  `westus2`/`southcentralus` all identically blocked, `centralus`/`westus3` both open. Moved
  `azure_region` to `centralus`.

A region-change "replace" plan didn't list three resources that were actually going to be
cascade-destroyed by their parent Resource Group's replacement (`azurerm_subnet.aks`/
`.postgres`/`azurerm_private_dns_zone.postgres`) - Terraform's diffing doesn't detect a
name-string-referenced-parent replacement as needing to replace its children. Resolved with a full
`terraform destroy` (confirmed via `plan -destroy` showing the real 9-resource list) + fresh
`apply` from empty state, not a risky in-place replace.

### Second live apply (2026-09-23, centralus) - four more real platform errors

- **`Standard_D2as_v5` isn't in this subscription's centralus-allowed VM-size list** - the error
  response itself enumerated every allowed size; `Standard_D2as_v7` (same family, newer generation)
  was in that list. Switched to it.
- **Key Vault RBAC mode grants the creating principal nothing implicitly** - `rbac_authorization_enabled
  = true` means writing a secret failed with `403 Forbidden`/`ForbiddenByRbac` until an explicit
  `azurerm_role_assignment` ("Key Vault Secrets Officer") was added. RBAC role assignments have a
  real, undocumented-duration propagation delay with no live status API to poll - `time_sleep`
  (30s) is used here as a deliberate, explained exception to this project's own "poll, don't sleep"
  rule, not an unexamined shortcut.
- **Postgres needs `public_network_access_enabled = false` declared explicitly** once
  `delegated_subnet_id`/`private_dns_zone_id` are set - its own computed default silently conflicts
  with private networking (`ConflictingPublicNetworkAccessAndVirtualNetworkConfiguration`).
- **The legacy Azure Cache for Redis product is now actively BLOCKED from new creation**, not just
  "being retired eventually": `"Azure Cache for Redis is retiring, create Azure Managed Redis
  instance instead."` - a materially different, more urgent finding than 2026-09-22's research had
  suggested, and it invalidated that night's explicit "stay on legacy Redis" decision. Re-escalated
  to the user (a third option - self-host Redis in AKS - was also offered) rather than resolved
  silently. **User chose Azure Managed Redis.** See "Redis: two real reversals" below.

### Third live apply (2026-09-23) - Managed Redis's own required block, then AKS quota, then two computed-attribute quirks

- **`azurerm_managed_redis` requires a `default_database` block** ("`default_database` must be
  provided when creating a new resource") despite every attribute inside that block being
  individually optional - not documented as a required block anywhere obviously prominent, caught
  by a live `plan` error, not `validate` (the block being entirely absent is itself what's invalid,
  which `validate` doesn't catch since an absent optional-nested-attributes block is normally fine).
  Added the block with `access_keys_authentication_enabled = false` set explicitly - the whole
  point of choosing this product is Entra ID auth, so leaving this undeclared would have silently
  left legacy access-key auth available alongside it.
- **AKS failed with `InsufficientVCPUQuota`**: this subscription's regional vCPU cap is a hard 4
  (confirmed live via `az vm list-usage`, identical in `centralus` and `westus3` - subscription-wide,
  not region-specific, the same shape of restriction as the zone finding above), and 3 nodes ×
  `Standard_D2as_v7`'s 2 vCPU = 6 exceeded it. **User chose to drop `aks_node_count` to 2** (4 vCPU,
  fits exactly) over requesting a quota increase (free-trial subscriptions typically can't
  self-serve this). Kafka's 3 broker pods lose strict one-per-node placement as a result - a real,
  accepted tradeoff for a demo subscription.
- **`azurerm_postgresql_flexible_server`'s `zone` attribute can't be cleared in-place**: leaving it
  undeclared in config (after dropping explicit zone-pinning) made every subsequent plan try to
  "correct" the live, Azure-auto-assigned value back to unset - which the API flatly rejects
  (`` `zone` can only be changed when exchanged with the zone specified in
  `high_availability.0.standby_availability_zone` ``, not a true in-place-updatable field at all
  outside an HA zone-swap operation). Fixed with `lifecycle { ignore_changes = [zone] }` - the
  correct tool here, not a workaround, since this project genuinely doesn't care which zone Azure
  picked.
- **`azurerm_kubernetes_cluster`'s `default_node_pool.upgrade_settings` is optional+computed** the
  same way - AKS auto-populates it (`max_surge = "10%"`, `drain_timeout_in_minutes = 0`,
  `node_soak_duration_in_minutes = 0`) when left undeclared, and every subsequent plan then tried to
  unset it, showing a perpetual spurious diff. Declared explicitly matching the platform's own
  live-confirmed default - this project's standing "declare load-bearing defaults" principle,
  resolved here to "match the platform's own default" rather than `ignore_changes`, since unlike
  `zone` this one doesn't reject in-place changes outright.

After all of the above: `terraform plan` reports **No changes** against live state - independently
confirmed, not just trusted from "Apply complete."

## Redis: two real reversals, not indecision

1. **2026-09-22 (plan-only research)**: Azure Managed Redis's Entra-ID-only auth (no
   password/access-key attribute exists on the resource at all) would need real new Lettuce
   application code the app doesn't have yet. User chose to stay on the legacy
   `azurerm_redis_cache` (Basic C0, Redis 6.0-capped) to keep the app's Redis client identical
   across every cloud target, accepting the version-currency cost explicitly.
2. **2026-09-23 (first live apply)**: that tradeoff turned out to be moot - Azure now actively
   **blocks new creation** of the legacy product outright, not merely retiring it on a future date.
   Re-escalated to the user with a newly-offered third option (self-host Redis in AKS, matching how
   Kafka is already self-hosted identically across every cloud target). **User chose Azure Managed
   Redis** over both the (now-impossible) legacy option and self-hosting.

**Consequence, now required, not optional**: the Spring Boot app's `spring.data.redis.*`
host/port/password config cannot connect to Azure Managed Redis as configured - it needs a custom
Lettuce credential provider doing Entra ID token acquisition/refresh (`azure-identity`'s
`DefaultAzureCredential`/`WorkloadIdentityCredential`). Not yet implemented - see "What's next."

## IAM-auth backport (2026-09-23): AWS and GCP now get the same treatment

Once Azure's Redis move was forced onto Entra-ID-only auth, the user explicitly asked to backport
the same tighter posture to AWS's ElastiCache and GCP's Memorystore rather than leave them on
password auth only because nothing had forced it there yet (`terraform/aws/elasticache-iam-auth.tf`,
`terraform/gcp/gke.tf`'s new `google_service_account.app`/`memorystore.tf` changes). This Azure
pass's own version of that backport:

- `workload_identity_enabled`/`oidc_issuer_enabled` set explicitly on the AKS cluster (aks.tf) -
  previously nothing gave a pod its own Entra ID identity at all (the cluster's own
  `SystemAssigned` identity is for control-plane operations; `kubelet_identity` is node-level,
  image-pulls only).
- `azurerm_user_assigned_identity.app` + `azurerm_federated_identity_credential.app`
  (`redis-iam-auth.tf`) - federates the app's future K8s ServiceAccount
  (`system:serviceaccount:default:grid-meter-app`) to this identity via AKS's OIDC issuer.
- `azurerm_managed_redis_access_policy_assignment.app` grants that identity data-plane access to
  Managed Redis. Confirmed live this is a genuinely different access-control layer from Key Vault's
  Azure-RBAC model used elsewhere in this config (Azure RBAC governs management-plane access to the
  *resource*; access-policy-assignment governs actual data read/write) - not an inconsistency with
  how Key Vault access is granted.

**Terraform-side, real but currently inert**: `k8s/api-azure.yaml` exists now (added 2026-09-23,
see "App-deploy layer" below) but doesn't yet carry the ServiceAccount object/annotation this
federated identity actually needs - no pod can federate it until that manifest work and the
Lettuce credential-provider app code both land, tracked as required follow-up, the same split
already applied to Azure's own Managed Redis Terraform-vs-app-code gap above.

## App-deploy layer (2026-09-23): confirmed live end-to-end

`k8s/deploy-azure.sh`, `k8s/teardown-azure.sh`, `k8s/check-resources-azure.sh` (kubectl-layer),
`terraform/azure/check-resources-azure.sh` (Terraform-layer), `k8s/storageclass-azure.yaml`,
`k8s/traefik-azure.yaml`, `k8s/api-azure.yaml` - all written matching AWS's/GCP's existing
structure. Two real, Azure-specific facts worth calling out (found via live web search before
writing, not guessed):

- **AKS auto-creates a default StorageClass** (`managed-csi`, Standard SSD LRS) the same way GKE
  does (unlike EKS, which has none) - `deploy-azure.sh` un-defaults it before applying
  `storageclass-azure.yaml`, mirroring `deploy-gcp.sh`'s identical step.
- **The Azure Disk CSI driver's XFS-override parameter is `fsType` (plain camelCase)**, not the
  `csi.storage.k8s.io/fstype` generic CSI parameter key AWS's/GCP's drivers both share - confirmed
  via the driver's own upstream parameter docs specifically to avoid silently carrying over a
  parameter name that happens to be wrong for this one driver. The underlying reason for needing
  XFS at all (ext4's auto-created `lost+found` directory fatally breaking Kafka's LogManager on
  startup) is unchanged from AWS's/GCP's own live-found bug.

**Both layers now confirmed live**: `terraform/azure/check-resources-azure.sh` (22/22, after
fixing one real bug - `az redisenterprise` is a dynamically-installed CLI extension whose
first-ever invocation prints install warnings on stderr that the script's own `check()` merges
into captured output by design; fixed by pre-installing the extension quietly up front) and
`k8s/check-resources-azure.sh` (15/15) both pass against the real, live-deployed cluster. A real
HTTP smoke test (frontend `200`, login with the seeded `demo` credentials issuing a real JWT)
confirms actual functionality - the app's Postgres/Kafka/JWT-auth path all genuinely work end to
end on Azure. Redis remains unauthenticated as already documented (the Lettuce credential-provider
gap) - the health-check fix keeps this from crash-looping the app, matching AWS's/GCP's own
already-confirmed behavior.

**One real, honestly-reported anomaly**: one of the two `api` pods restarted once during this
first deploy (`kubectl describe`: two consecutive `Liveness`/`Readiness probe failed: connection
refused` events, i.e. Tomcat genuinely wasn't listening yet when the 45s-delayed liveness probe
fired) - a single occurrence, self-resolved, not a repeat of the crash-loop-class bugs found
earlier today (those looped indefinitely; this one didn't recur). Plausible cause: first-ever cold
image pull + JVM start on this specific AKS node pushed just past the existing probe margin once.
Not chased further since it didn't block or repeat - worth knowing if it becomes a recurring
pattern on future Azure deploys, in which case the probe margins may need a further bump
specifically for this cloud.

Two new Terraform outputs (`node_resource_group`, `redis_port`) these scripts needed - added
earlier and **applied to live state** (output-only, confirmed via `terraform apply`: `0 added, 0
changed, 0 destroyed`, both outputs now present).

## Teardown: confirmed clean, zero residue, first-run success

Full cycle run for real (2026-09-23): `k8s/teardown-azure.sh` (clean on its first-ever real run -
no new bugs found, unlike AWS's identical script, which needed a real fix after finding a
crash-loop the hard way; Azure's already had the equivalent Step 1 fix applied proactively from
the start), then `terraform destroy` (20 resources, zero errors, ~9 minutes dominated by
`azurerm_kubernetes_cluster.main` at 4m43s and `azurerm_managed_redis.main` at 3m20s - both
consistent with their original creation times).

**Independently verified against 8 real Azure API checks, not trusted from "Destroy complete"
alone**: `az group exists` confirms both the main resource group (`grid-meter-app-rg`) and AKS's
auto-created node resource group (`MC_grid-meter-app-rg_grid-meter-app-aks_centralus`) are gone -
a stronger single check than AWS's/GCP's own residue batteries have available, since ARM resource
groups are a hard containment boundary and everything inside one is necessarily gone once the
group itself is. Checked individually anyway for parity: AKS cluster, Postgres Flexible Server,
Managed Redis, Key Vault, ACR, and the VNet (subscription-wide) - **all 8 checks confirmed
empty/gone.**

```bash
# Confirm no residue (don't just trust "Destroy complete")
az group exists --name grid-meter-app-rg                                    # expect: false
az group exists --name MC_grid-meter-app-rg_grid-meter-app-aks_<region>     # expect: false
az aks list --query "[?name=='grid-meter-app-aks']"                          # expect: []
az postgres flexible-server list --query "[?name=='grid-meter-app-postgres']" # expect: []
az redisenterprise list --query "[?name=='grid-meter-app-redis']"            # expect: []
az keyvault list --query "[?name=='grid-meter-app-kv']"                      # expect: []
az acr list --query "[?name=='<your ACR name>']"                             # expect: []
az network vnet list --query "[?name=='grid-meter-app-vnet']"                # expect: []
```

## Cost check: real billing data, not a list-price estimate

`check-costs-azure.sh` queries real Azure Cost Management data by service - a genuine structural
advantage over GCP's `estimate-costs-gcp.sh`, which had to fall back to a list-price estimate
because its BigQuery billing export was never set up. Azure's Cost Management Query API works
without any export prerequisite at all.

Two real things confirmed live before writing it (2026-09-23), not assumed: `az consumption usage
list` (no extension needed) looked like the obvious first choice, but every cost/quantity/date
field it returns is a literal `"None"` string - unusable. The installed `costmanagement` CLI
extension (1.0.0) only exposes `export`/`show-operation-result` subcommands, no ad-hoc query
command, despite the underlying REST API fully supporting one - the script calls
`Microsoft.CostManagement/query` directly via `az rest` instead.

Same limitation as AWS's `check-costs-aws.sh`/GCP's own cost checks, confirmed live: billing data
lags real usage by more than same-day. A query run against this session's fully live
AKS/Postgres/Managed Redis deployment (applied and running the entire session) still showed only
the bootstrap Storage Account's own negligible cost - nothing for the actually-running compute.
Re-run a day or two after a teardown for a meaningful answer.

## Directory structure

```
terraform/azure/
  bootstrap/           # one-time state backend setup (Resource Group + Storage Account + Blob Container) - APPLIED, real
  backend.tf           # wires this main config to bootstrap's Storage Account
  versions.tf          # azurerm ~> 5.5, random ~> 3.6, time ~> 0.12
  providers.tf
  variables.tf
  locals.tf
  network.tf           # Resource Group, VNet, AKS subnet, Postgres delegated subnet + private DNS zone
  aks.tf                # AKS cluster (2-node pool, workload identity enabled), kubelet identity -> AcrPull role assignment
  postgresql.tf        # Flexible Server + database, random_password + Key Vault secret, RBAC role assignment + propagation sleep
  rediscache.tf        # Azure Managed Redis (Entra ID auth only - see "Redis: two real reversals" above)
  redis-iam-auth.tf    # app workload identity, federated credential, Managed Redis access-policy assignment
  acr.tf               # Container Registry, Basic SKU
  outputs.tf
  check-resources-azure.sh  # live Terraform-layer resource check - run and confirmed 22/22 (2026-09-23)
  check-costs-azure.sh      # real Cost Management billing data by service - run and confirmed clean (2026-09-23)
```

## Usage

```bash
cd terraform/azure
terraform init
terraform fmt
terraform validate
terraform plan -out tfplan
terraform apply tfplan   # run by the user, never Claude Code - see AWS/GCP READMEs for why
```

## What's next

1. ~~Apply the two new outputs~~ - **done**, applied to live state.
2. ~~Run `k8s/deploy-azure.sh` for real~~ - **done**, confirmed live end-to-end (22/22 + 15/15 +
   HTTP smoke test) - see "App-deploy layer" above, including one honestly-reported single-restart
   anomaly (self-resolved, not blocking).
3. ~~Run a real `k8s/teardown-azure.sh` + `terraform destroy` cycle~~ - **done**, clean on the
   first real run, zero residue independently confirmed - see "Teardown" above. Azure now matches
   AWS's/GCP's full confidence bar exactly.
4. **Lettuce credential-provider app code (all three clouds now, not just Azure)**: AWS SigV4
   ElastiCache IAM token, GCP IAM token, Azure Entra ID token via `WorkloadIdentityCredential` -
   real Spring Boot/Java application work, materially different in kind from the Terraform/Bash
   work above, not attempted inline. Needs matching tests.
5. **K8s ServiceAccount objects + manifest wiring** for the identity-federation work to actually
   activate, all three clouds (`system:serviceaccount:default:grid-meter-app`, annotated
   per-cloud) - none of `api-aws.yaml`/`api-gcp.yaml`/`api-azure.yaml` carry a `ServiceAccount`
   object or `serviceAccountName` field yet (all three currently run as the implicit `default` SA).
6. ~~A cost-estimate or real cost-check script~~ - **done**: `check-costs-azure.sh`, real
   Cost Management billing data (no export setup needed, unlike GCP's own gap) - see "Cost check"
   above.
