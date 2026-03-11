# ──────────────────────────────────────────────────────────────────────
# Azure Cache for Redis
# ──────────────────────────────────────────────────────────────────────
# Used by the Marketing Site to cache the datetime response with a
# 5-second TTL, reducing load on the API and SQL database.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_redis_cache" "main" {
  name                          = "redis-${local.name_prefix}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  capacity                      = var.redis_capacity
  family                        = var.redis_sku == "Premium" ? "P" : "C"
  sku_name                      = var.redis_sku
  non_ssl_port_enabled          = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = local.common_tags

  redis_configuration {}
}

# ──────────────────────────────────────────────────────────────────────
# Private Endpoint — Redis (ADR-3)
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_private_endpoint" "redis" {
  name                = "pe-redis-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-redis-${local.name_prefix}"
    private_connection_resource_id = azurerm_redis_cache.main.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-redis"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }
}

# ──────────────────────────────────────────────────────────────────────
# Key Vault Secret — Redis Connection String (ADR-5)
# ──────────────────────────────────────────────────────────────────────
# Uses the SSL port (6380) with the primary access key.
# The StackExchange.Redis client in the Site app parses this format.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_key_vault_secret" "redis_connection_string" {
  name         = "redis-connection-string"
  key_vault_id = azurerm_key_vault.main.id

  value = "${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port},password=${azurerm_redis_cache.main.primary_access_key},ssl=True,abortConnect=False"

  depends_on = [azurerm_role_assignment.kv_deployer]
}
