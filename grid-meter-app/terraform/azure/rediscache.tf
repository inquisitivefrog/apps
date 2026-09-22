# Legacy "Azure Cache for Redis" (azurerm_redis_cache), chosen deliberately over the newer Azure
# Managed Redis product - user decision (2026-09-22) after a real tradeoff surfaced live: Managed
# Redis authenticates via Entra ID tokens ONLY (confirmed via its own provider schema - no
# password/access-key attribute exists on it at all), which the app's existing
# spring.data.redis.* host/port/password config can't use without new application code (a custom
# Lettuce credential provider with token refresh). This legacy product keeps the simple
# password-based auth the app already uses identically across AWS/GCP/kind, at the real cost of
# capping at Redis 6.0 (confirmed live; app targets 8.10) and Azure's own announced retirement of
# this product by September 2028 - both acceptable for this project's demo timeframe, not for a
# real production system.
resource "azurerm_redis_cache" "main" {
  name                = "${var.project_name}-redis"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region

  capacity = var.redis_capacity
  family   = var.redis_family
  sku_name = var.redis_sku_name

  minimum_tls_version  = "1.2"
  non_ssl_port_enabled = false # TLS-only, matching this project's cert-manager/TLS-everywhere posture for every other cloud endpoint

  # No VNet-injection attribute available at Basic/Standard tiers (Premium-only, confirmed via
  # Microsoft's own Azure Cache for Redis docs) - the same public-endpoint-only limitation Azure
  # Managed Redis's entry tier had, just paired here with real password auth instead of no auth
  # option at all. Secured by TLS + the access key azurerm_redis_cache generates, not network
  # isolation - a real, accepted gap relative to AWS's/GCP's fully private data tier, not an
  # oversight.

  tags = local.common_tags
}
