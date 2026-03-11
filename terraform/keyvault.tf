# ──────────────────────────────────────────────────────────────────────
# Azure Key Vault
# ──────────────────────────────────────────────────────────────────────
# RBAC-based authorization (no access policies). Secrets are populated
# by Terraform after the data-layer resources are created in commits
# 5-6. Container Apps reference secrets via the Managed Identity.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_key_vault" "main" {
  name                       = "kv-${local.name_prefix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  purge_protection_enabled   = false # POC only — enable in production
  soft_delete_retention_days = 7

  tags = local.common_tags
}

# ──────────────────────────────────────────────────────────────────────
# Role Assignments
# ──────────────────────────────────────────────────────────────────────

# Deployer (current az login principal) — needs to write secrets
resource "azurerm_role_assignment" "kv_deployer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Container Apps Managed Identity — needs to read secrets at runtime
resource "azurerm_role_assignment" "kv_aca" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aca.principal_id
}
