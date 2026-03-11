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
# On initial deploy, the default placeholder image is used so that all
# infrastructure is provisioned before container images exist in ACR.
# After running `az acr build`, re-apply with your ACR image refs:
#
# site_image = "<acr_name>.azurecr.io/marketing-site:latest"
# api_image  = "<acr_name>.azurecr.io/marketing-api:latest"

# ──────────────────────────────────────────────────────────────────────
# Database — supply password via CLI or env var:
#   terraform apply -var="sql_admin_password=YourSecurePassword123!"
#   export TF_VAR_sql_admin_password="YourSecurePassword123!"
# ──────────────────────────────────────────────────────────────────────

sql_admin_login = "sqladmin"
