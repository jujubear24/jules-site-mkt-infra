# ──────────────────────────────────────────────────────────────────────
# Current Client
# ──────────────────────────────────────────────────────────────────────
# Used to grant the deployer access to Key Vault for secret management
# during terraform apply, without hardcoding any principal IDs.
# ──────────────────────────────────────────────────────────────────────

data "azurerm_client_config" "current" {}

# ──────────────────────────────────────────────────────────────────────
# User-Assigned Managed Identity
# ──────────────────────────────────────────────────────────────────────
# Single identity shared by both Container Apps. Role assignments:
#   - acrPull on ACR          (commit 4)
#   - Key Vault Secrets User  (this commit)
#
# Using user-assigned (vs system-assigned) so the identity and its
# permissions exist before the Container Apps are created, avoiding
# circular dependencies.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_user_assigned_identity" "aca" {
  name                = "id-aca-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}