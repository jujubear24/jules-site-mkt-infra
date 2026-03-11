# ──────────────────────────────────────────────────────────────────────
# Azure Container Registry
# ──────────────────────────────────────────────────────────────────────
# Admin auth is disabled. Container Apps pull images using the
# User-Assigned Managed Identity with the AcrPull role.
#
# Images are built and pushed outside of Terraform using:
#   az acr build --registry <name> --image <tag> --file <Dockerfile> .
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_container_registry" "main" {
  name                = replace("acr${local.name_prefix}", "-", "")
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.acr_sku
  admin_enabled       = false
  tags                = local.common_tags
}

# ──────────────────────────────────────────────────────────────────────
# AcrPull Role Assignment
# ──────────────────────────────────────────────────────────────────────
# Grants the ACA Managed Identity permission to pull images from this
# registry. No other principals need pull access.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca.principal_id
}