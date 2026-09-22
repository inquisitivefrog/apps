# terraform/azure

Provisions the Azure infrastructure `grid-meter-app` would run on in the cloud: a VNet, an AKS
cluster + node pool, a managed Azure Database for PostgreSQL Flexible Server, a managed Azure
Cache for Redis instance, and an Azure Container Registry. **Infrastructure only** — deploying the
app onto the cluster (a future `k8s/deploy-azure.sh`, ACR image build/push, Azure-specific k8s
manifest variants) is out of scope for this pass, mirroring how both AWS's and GCP's own k8s
overlays were separate follow-ups after their own infra-only passes.

See `docs/cloud-deployment-scope.md` for the full per-layer reasoning (why Postgres/Redis are
managed here but Kafka is self-hosted in-cluster identically across every target — `kind`, AWS,
GCP, and this), and `docs/identity.md`/this file's own "Real findings" section for the specific
Azure identity-model context that kicked this pass off (Microsoft Entra ID vs. Azure Resource
Manager being two genuinely separate control planes — see below).

## Status: plan-only, confirmed clean against a real Azure subscription (2026-09-22)

`terraform plan` against this subscription reports a clean **15 to add, 0 to change, 0 to
destroy** — real, live-checked (not just `validate`), but **nothing has been applied yet**, per
this pass's explicitly confirmed scope (matching how both AWS's and GCP's own tracks started).
`terraform/azure/bootstrap/` has been applied for real, though — the state backend itself is live.

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
             Microsoft.OperationalInsights Microsoft.Insights; do
     az provider register --namespace "$ns" --wait
   done
   ```
   (`az provider list --output table` shows hundreds of other namespaces still `NotRegistered` -
   that's expected; only the ones above are needed here.) Note the `azurerm` provider block also
   exposes `resource_provider_registrations`/`resource_providers_to_register` attributes that can
   handle this from Terraform itself - not used this pass since registration was already done
   manually before that was noticed, worth considering for a from-scratch subscription next time.
4. Terraform >= 1.11.0 (same floor as AWS/GCP).
5. `kubectl` installed, for interacting with the cluster once it exists.
6. `TF_CLI_ARGS="-no-color"` and `az config set core.no_color=true` set persistently (both
   confirmed live, 2026-09-22) - accessibility fixes for this user, unrelated to correctness, but
   worth keeping in the prerequisites list since they're now standing environment setup.

## Real findings (2026-09-22)

Checked live rather than assumed, same discipline as the AWS/GCP passes:

- **Identity is genuinely split into two separate control planes** - the specific thing this pass
  was kicked off to explore. Microsoft Entra ID (formerly Azure AD) is tenant-scoped identity
  (users, groups, app registrations, service principals); Azure Resource Manager is
  subscription/resource-scoped authorization. Terraform models this as two separate providers,
  `azurerm` (ARM) and `azuread` (Entra ID) - this config only ever needed `azurerm`, since AKS's
  managed identities (cluster identity, kubelet identity) are native to `azurerm` and Terraform
  authenticates via the already-logged-in `az` CLI rather than a Terraform-provisioned service
  principal, keeping Azure's identity setup comparably simple to AWS/GCP rather than pulling in a
  second provider.
- **AKS explicitly doesn't support/recommend B-series (burstable) VMs for system node pools**,
  despite B-series technically meeting the documented 2-vCPU/4GB minimum - confirmed live via
  Microsoft's own AKS VM-size docs. A real platform-specific constraint neither AWS's EKS
  (t3.medium, burstable) nor GCP's GKE (e2-medium) has. Used `Standard_D2as_v5` instead (2 vCPU,
  8GB, general-purpose, confirmed cheapest current-gen AKS-supported size at ~$0.086/hr in eastus).
- **Azure Cache for Redis (classic) caps at Redis 6.0** and is being retired by Azure itself
  (September 2028) - the same version-ceiling shape AWS's ElastiCache and GCP's Memorystore for
  Redis both hit. But **Azure deliberately did not adopt Valkey** the way AWS/GCP did to get past
  that ceiling (confirmed live via web search) - its modern path is "Azure Managed Redis," built
  on genuine Redis Software via a direct Microsoft/Redis Ltd. partnership. That product
  authenticates via Entra ID tokens ONLY (confirmed via its own provider schema - no password/
  access-key attribute exists on it at all), which the app's existing `spring.data.redis.*` host/
  port/password config can't use without real new application code. **User decision (2026-09-22)**:
  stayed on the legacy `azurerm_redis_cache` (Basic C0) to keep the app's Redis client identical
  across AWS/GCP/Azure/`kind` - Redis-version currency lost, zero app-code impact kept. Revisit if
  Azure Managed Redis ever gains simpler auth, or if the legacy product's 2028 retirement becomes
  actually relevant.
- **Postgres Flexible Server, unlike AKS node pools, DOES support Burstable (B-series) SKUs** -
  `B_Standard_B1ms`, matching AWS's db.t4g.micro/GCP's db-f1-micro cost-conscious sizing exactly. A
  real, worth-noting contrast with the AKS finding above rather than an inconsistency - two
  different Azure services, two different real constraints.
  - PostgreSQL 18 confirmed GA on Azure Flexible Server (web search against Microsoft's own
    release notes), matching this project's stack pin exactly - same result AWS's RDS and GCP's
    Cloud SQL version checks both found.
  - `storage_mb` is a fixed enum (32768/65536/131072/...), not an arbitrary GB integer like AWS's/
    GCP's storage-size fields - 32768 (32GB) confirmed live as both the actual minimum and the
    default.
  - No AWS-RDS-style `manage_master_user_password` convenience (confirmed via the real provider
    schema) - the same gap GCP's Cloud SQL had. Wired up the same substitute GCP used:
    `random_password` + a managed secret store, Azure Key Vault filling Secret Manager's role.
  - Private networking needs its own dedicated, delegated subnet PLUS a private DNS zone plus a
    VNet link - genuinely more moving parts than AWS's private-subnet-placement or GCP's
    shared-PSA-range approach, not a simplification skipped here.
- **ACR is a single registry holding multiple image repositories by path**
  (`<registry>.azurecr.io/api`, `.../frontend`), the same structural model as GCP's Artifact
  Registry, not AWS ECR's repo-per-image model - checked against ACR's own documented naming model
  *before* writing this as one `azurerm_container_registry` resource, specifically to avoid
  repeating the GCP session's own real "assumed the wrong repo-vs-image model" bug a second time.
- **AKS auto-creates a second, hidden Resource Group** (`MC_<rg>_<name>_<region>`) to hold the
  actual VM scale set/node NICs/load balancer backing the cluster - neither AWS's EKS nor GCP's
  GKE has an equivalent auto-created second resource container. Nothing to declare for it (Azure
  manages its lifecycle automatically), just worth knowing it exists when looking at the real
  subscription later and not mistaking it for drift.
- **Azure Managed Identity/Key Vault RBAC naming caught two real bugs at `terraform validate`
  time**, before ever reaching a live API call: `azurerm_key_vault`'s RBAC-mode attribute is
  `rbac_authorization_enabled` (required), not the `enable_rbac_authorization` name some
  still-current docs/examples show; `azurerm_private_dns_zone_virtual_network_link` takes
  `private_dns_zone_id` (not `private_dns_zone_name`) and has no `resource_group_name` argument at
  all (inferred from the zone ID) - both guessed wrong on first draft, both caught by `validate`
  itself rather than a live apply.
- **A `node_provisioning_profile` block became required on `azurerm_kubernetes_cluster` as of
  azurerm 5.x** (confirmed via a real `terraform validate` failure - not documented as a breaking
  change anywhere obviously prominent). `mode = "Manual"` explicitly opts out of AKS's newer Node
  Auto-Provisioning (a Karpenter-based feature), keeping the fixed-size `default_node_pool`
  declared elsewhere in this config as the only node-management mechanism, matching AWS's/GCP's
  own static node-count sizing.
- **Every major resource schema in this config was verified against the real installed provider**
  (`terraform providers schema -json` in a scratch directory), not assumed from documentation or
  web search summaries - this caught the `storage_account_id`-not-`storage_account_name` breaking
  change on `bootstrap/`'s own `azurerm_storage_container` before it ever became a live bug, and
  the RBAC/DNS-link naming issues above before `terraform validate` even had to catch them for me
  on the second pass through those two resources specifically.

## Directory structure

```
terraform/azure/
  bootstrap/     # one-time state backend setup (Resource Group + Storage Account + Blob Container) - APPLIED, real
  backend.tf     # wires this main config to bootstrap's Storage Account
  versions.tf    # azurerm ~> 5.5, random ~> 3.6
  providers.tf
  variables.tf
  locals.tf
  network.tf     # Resource Group, VNet, AKS subnet, Postgres delegated subnet + private DNS zone
  aks.tf         # AKS cluster, system node pool, kubelet identity -> AcrPull role assignment
  postgresql.tf  # Flexible Server + database, random_password + Key Vault secret
  rediscache.tf  # legacy Azure Cache for Redis, Basic C0
  acr.tf         # Container Registry, Basic SKU
  outputs.tf
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

1. A real `terraform apply` (user-run) - this pass deliberately stopped at plan-only, matching the
   confirmed scope. Given AWS's and GCP's own histories, expect at least one real live-apply-only
   bug this scratch-dir schema verification and `validate` couldn't have caught in advance.
2. `k8s/deploy-azure.sh` / `teardown-azure.sh` and Azure-specific k8s manifest variants
   (`storageclass-azure.yaml`, `traefik-azure.yaml`, `api-azure.yaml`) - the app-deploy layer,
   mirroring AWS's/GCP's own later phase.
3. `terraform/azure/check-resources-azure.sh` / `k8s/check-resources-azure.sh` - the live
   verification scripts every other cloud track has, once there's real infrastructure to check.
4. A cost-estimate or real cost-check script, mirroring GCP's `estimate-costs-gcp.sh` (a
   real `check-costs-azure.sh` would need Azure Cost Management's own export/API setup, not
   yet investigated).
