# ──────────────────────────────────────────────────────────────────────
# Private DNS Zones
# ──────────────────────────────────────────────────────────────────────
# Required for Private Endpoint name resolution. Without these zones
# linked to the VNet, the Container Apps would resolve the SQL/Redis
# FQDNs to public IPs — which are blocked — and connections would fail.
# ──────────────────────────────────────────────────────────────────────

# ── SQL ──────────────────────────────────────────────────────────────

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "dnslink-sql-${local.name_prefix}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}

# ── Redis ────────────────────────────────────────────────────────────

resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = "dnslink-redis-${local.name_prefix}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}