# ──────────────────────────────────────────────────────────────────────
# Azure SQL Server
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_mssql_server" "main" {
  name                          = "sql-${local.name_prefix}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = var.sql_admin_password
  public_network_access_enabled = false
  tags                          = local.common_tags
}

# ──────────────────────────────────────────────────────────────────────
# Azure SQL Database — Serverless (ADR-4)
# ──────────────────────────────────────────────────────────────────────
# Serverless tier auto-scales vCores between min and max capacity,
# and auto-pauses after the configured idle period. The application
# uses SELECT GETDATE(), which requires only the master-level
# connection — but we provision a named database as the standard
# pattern for the POC template.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_mssql_database" "main" {
  name      = "sqldb-${local.name_prefix}"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "GP_S_Gen5_2"

  min_capacity                = var.sql_min_capacity
  max_size_gb                 = 32
  auto_pause_delay_in_minutes = var.sql_auto_pause_delay

  tags = local.common_tags
}

# ──────────────────────────────────────────────────────────────────────
# Private Endpoint — SQL (ADR-3)
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-sql-${local.name_prefix}"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-sql"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

# ──────────────────────────────────────────────────────────────────────
# Key Vault Secret — DB Connection String (ADR-5)
# ──────────────────────────────────────────────────────────────────────
# Built from Terraform-known values so no manual secret handling.
# The PE FQDN resolves to the private IP via the DNS zone.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "db-connection-string"
  key_vault_id = azurerm_key_vault.main.id

  value = join(";", [
    "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433",
    "Initial Catalog=${azurerm_mssql_database.main.name}",
    "User ID=${var.sql_admin_login}",
    "Password=${var.sql_admin_password}",
    "Encrypt=True",
    "TrustServerCertificate=False",
    "Connection Timeout=30",
  ])

  depends_on = [azurerm_role_assignment.kv_deployer]
}