# ──────────────────────────────────────────────────────────────────────
# Outputs populated as resources are provisioned in subsequent commits.
# ──────────────────────────────────────────────────────────────────────

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

# output "acr_login_server" {
#   description = "Login server URL for the Container Registry"
#   value       = azurerm_container_registry.main.login_server
# }

# output "front_door_endpoint" {
#   description = "Front Door endpoint hostname (public URL)"
#   value       = azurerm_cdn_frontdoor_endpoint.main.host_name
# }

# output "site_fqdn" {
#   description = "FQDN of the Marketing Site container app"
#   value       = azurerm_container_app.site.ingress[0].fqdn
# }

# output "api_fqdn" {
#   description = "FQDN of the Marketing API container app (internal)"
#   value       = azurerm_container_app.api.ingress[0].fqdn
# }