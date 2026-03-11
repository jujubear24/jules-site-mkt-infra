# ──────────────────────────────────────────────────────────────────────
# Log Analytics Workspace
# ──────────────────────────────────────────────────────────────────────
# Required by the ACA environment for container logs, scaling events,
# and health probe telemetry.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

# ──────────────────────────────────────────────────────────────────────
# Container Apps Environment (ADR-2)
# ──────────────────────────────────────────────────────────────────────
# Deployed into the ACA subnet for VNet integration. This gives the
# container apps a private network path to the PE subnet where SQL
# and Redis live.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${local.name_prefix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id   = azurerm_subnet.aca.id
  tags                       = local.common_tags
}

# ──────────────────────────────────────────────────────────────────────
# Marketing Site — Container App
# ──────────────────────────────────────────────────────────────────────
# External ingress — receives traffic from Front Door.
# Secrets sourced from Key Vault via Managed Identity.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_container_app" "site" {
  name                         = "ca-site-${local.name_prefix}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.aca.id
  }

  # ── Secrets from Key Vault ───────────────────────────────────────
  secret {
    name                = "redis-connection-string"
    key_vault_secret_id = azurerm_key_vault_secret.redis_connection_string.id
    identity            = azurerm_user_assigned_identity.aca.id
  }

  # ── Container definition ─────────────────────────────────────────
  template {
    min_replicas = var.site_min_replicas
    max_replicas = var.site_max_replicas

    container {
      name   = "marketing-site"
      image  = var.site_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "ASPNETCORE_ENVIRONMENT"
        value       = "Production"
      }

      env {
        name        = "REDIS_CONNECTION_STRING"
        secret_name = "redis-connection-string"
      }

      env {
        name  = "MarketingApi__BaseUrl"
        value = "https://${azurerm_container_app.api.ingress[0].fqdn}"
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 8080
      }

      readiness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 8080
      }
    }

    # ── KEDA HTTP Scaler ───────────────────────────────────────────
    http_scale_rule {
      name                = "http-scaling"
      concurrent_requests = "50"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# ──────────────────────────────────────────────────────────────────────
# Marketing API — Container App
# ──────────────────────────────────────────────────────────────────────
# Internal-only ingress — not reachable from the public internet.
# Only the Marketing Site communicates with this service.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_container_app" "api" {
  name                         = "ca-api-${local.name_prefix}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.aca.id
  }

  # ── Secrets from Key Vault ───────────────────────────────────────
  secret {
    name                = "db-connection-string"
    key_vault_secret_id = azurerm_key_vault_secret.db_connection_string.id
    identity            = azurerm_user_assigned_identity.aca.id
  }

  # ── Container definition ─────────────────────────────────────────
  template {
    min_replicas = var.api_min_replicas
    max_replicas = var.api_max_replicas

    container {
      name   = "marketing-api"
      image  = var.api_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "ASPNETCORE_ENVIRONMENT"
        value       = "Production"
      }

      env {
        name        = "DB_CONNECTION_STRING"
        secret_name = "db-connection-string"
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 8080
      }

      readiness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 8080
      }
    }

    # ── KEDA HTTP Scaler ───────────────────────────────────────────
    http_scale_rule {
      name                = "http-scaling"
      concurrent_requests = "20"
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8080
    transport        = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
