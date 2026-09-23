# Azure Managed Redis, not the legacy "Azure Cache for Redis" (azurerm_redis_cache) - REVERSED
# 2026-09-23 from the 2026-09-22 decision documented below, after a real live apply failure showed
# the legacy product is no longer just "being retired eventually" but actively BLOCKED from new
# creation right now: `az`/the API itself returns "Azure Cache for Redis is retiring, create Azure
# Managed Redis instance instead" on any attempt to create one. The tradeoff from last night is
# real but now moot - there's no simpler managed alternative left to weigh it against.
#
# Original 2026-09-22 reasoning, kept for context: Managed Redis authenticates via Entra ID tokens
# ONLY (confirmed via its own provider schema - no password/access-key attribute exists on it at
# all), which the app's existing spring.data.redis.* host/port/password config can't use without
# new application code (a custom Lettuce credential provider with token refresh). **This
# application-code work is now a required follow-up, not an optional one** - see this project's
# status log / terraform/azure/README.md "What's next" for tracking. Terraform can stand up the
# instance itself regardless of whether the app can authenticate to it yet.
resource "azurerm_managed_redis" "main" {
  name                = "${var.project_name}-redis"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region
  sku_name            = var.redis_sku_name

  # No VNet-injection attribute found on this resource's schema at the Balanced_B0 tier (checked
  # live via `terraform providers schema -json`, 2026-09-22) - unlike AWS's ElastiCache/GCP's
  # Memorystore, both fully private, Azure Managed Redis's entry tier appears to be public-endpoint
  # only (secured by its own Entra-ID-based access-policy mechanism, not network isolation). A
  # real, Azure-specific gap relative to AWS/GCP's private-only data-tier posture, not an
  # oversight.
  high_availability_enabled = false # single-node, matching AWS's/GCP's own single-node cost-conscious cache sizing - this project's local track already builds real Redis HA (Sentinel) by hand

  # Required block - "default_database must be provided when creating a new resource" (live error,
  # 2026-09-23), not documented as optional despite every one of its own attributes being optional.
  default_database {
    # Explicit false, not left as an undeclared default: this resource's whole point (per the header
    # comment above) is Entra ID token auth, not legacy shared-secret access keys. Leaving this
    # unset would silently leave access-key auth available alongside Entra ID rather than actually
    # enforcing the tighter posture the product migration is for.
    access_keys_authentication_enabled = false
  }

  tags = local.common_tags
}
