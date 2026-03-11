# ──────────────────────────────────────────────────────────────────────
# Naming Convention
# ──────────────────────────────────────────────────────────────────────
# All resources follow the pattern: {type}-{project}-{environment}
# Example: rg-mkt-prod, vnet-mkt-prod, aca-mkt-prod-site
# ──────────────────────────────────────────────────────────────────────

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}
