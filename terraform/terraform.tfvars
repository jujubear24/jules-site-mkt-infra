# ──────────────────────────────────────────────────────────────────────
# General
# ──────────────────────────────────────────────────────────────────────

subscription_id = "REPLACE_WITH_YOUR_SUBSCRIPTION_ID"
project         = "mkt"
environment     = "prod"
location        = "canadacentral"

tags = {
  Project     = "Marketing Site"
  Environment = "Production"
  ManagedBy   = "Terraform"
}

# ──────────────────────────────────────────────────────────────────────
# Container Images
# ──────────────────────────────────────────────────────────────────────
# After running `az acr build`, update these with your ACR login server:
#   <acr_name>.azurecr.io/marketing-site:latest
#   <acr_name>.azurecr.io/marketing-api:latest

site_image = "REPLACE_AFTER_ACR_BUILD"
api_image  = "REPLACE_AFTER_ACR_BUILD"

# ──────────────────────────────────────────────────────────────────────
# Database — supply password via CLI or env var:
#   terraform apply -var="sql_admin_password=YourSecurePassword123!"
#   export TF_VAR_sql_admin_password="YourSecurePassword123!"
# ──────────────────────────────────────────────────────────────────────

sql_admin_login = "sqladmin"
