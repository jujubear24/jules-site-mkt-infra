# ──────────────────────────────────────────────────────────────────────
# Azure Front Door Profile (ADR-1)
# ──────────────────────────────────────────────────────────────────────
# Standard tier is sufficient for this POC. Premium adds Private Link
# origins and enhanced WAF rules — a natural upgrade path if the
# pattern graduates to production.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "afd-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = local.common_tags
}

# ──────────────────────────────────────────────────────────────────────
# Endpoint
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "fde-${local.name_prefix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  tags                     = local.common_tags
}

# ──────────────────────────────────────────────────────────────────────
# Origin Group
# ──────────────────────────────────────────────────────────────────────
# Health probes hit the Site's /health endpoint every 30 seconds.
# This lets Front Door detect unhealthy origins and stop routing to
# them before users see errors.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_origin_group" "site" {
  name                     = "og-site-${local.name_prefix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/health"
    protocol            = "Https"
    request_type        = "GET"
    interval_in_seconds = 30
  }
}

# ──────────────────────────────────────────────────────────────────────
# Origin — Marketing Site Container App
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_origin" "site" {
  name                          = "origin-site-${local.name_prefix}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.site.id
  enabled                       = true

  host_name          = azurerm_container_app.site.ingress[0].fqdn
  origin_host_header = azurerm_container_app.site.ingress[0].fqdn
  http_port          = 80
  https_port         = 443
  certificate_name_check_enabled = true
}

# ──────────────────────────────────────────────────────────────────────
# Route — all traffic to the Site origin group
# ──────────────────────────────────────────────────────────────────────
# Caching is disabled. The page auto-refreshes every 1 second and the
# Redis cache has a 5-second TTL — edge caching would serve stale
# content and defeat the real-time datetime display. For a production
# evolution, static assets (CSS/JS/images) should be served from a
# separate origin group with caching enabled.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_route" "site" {
  name                          = "route-site-${local.name_prefix}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.site.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.site.id]

  supported_protocols    = ["Https"]
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"

  link_to_default_domain = true
}

# ──────────────────────────────────────────────────────────────────────
# WAF Policy — OWASP Top 10 Protection
# ──────────────────────────────────────────────────────────────────────
# Prevention mode blocks malicious requests. The DRS 2.1 managed
# ruleset covers the OWASP Top 10 categories: SQL injection, XSS,
# command injection, protocol violations, etc.
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  name                              = replace("waf${local.name_prefix}", "-", "")
  resource_group_name               = azurerm_resource_group.main.name
  sku_name                          = azurerm_cdn_frontdoor_profile.main.sku_name
  enabled                           = true
  mode                              = "Prevention"
  tags                              = local.common_tags

  managed_rule {
    type    = "DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }
}

# ──────────────────────────────────────────────────────────────────────
# Security Policy — attach WAF to the endpoint
# ──────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_security_policy" "main" {
  name                     = "sp-waf-${local.name_prefix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}