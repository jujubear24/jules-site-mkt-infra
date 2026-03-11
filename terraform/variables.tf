# ──────────────────────────────────────────────────────────────────────
# General
# ──────────────────────────────────────────────────────────────────────

variable "subscription_id" {
  description = "Azure subscription ID for deployment"
  type        = string
}

variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "mkt"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "canadacentral"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ──────────────────────────────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────────────────────────────

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aca_subnet_prefix" {
  description = "CIDR prefix for the ACA environment subnet (min /23)"
  type        = string
  default     = "10.0.0.0/23"
}

variable "pe_subnet_prefix" {
  description = "CIDR prefix for the Private Endpoints subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# ──────────────────────────────────────────────────────────────────────
# Container Registry
# ──────────────────────────────────────────────────────────────────────

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
}

# ──────────────────────────────────────────────────────────────────────
# Container Apps
# ──────────────────────────────────────────────────────────────────────

variable "site_image" {
  description = "Full image reference for the Marketing Site container"
  type        = string
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "api_image" {
  description = "Full image reference for the Marketing API container"
  type        = string
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "site_min_replicas" {
  description = "Minimum replica count for the Site container app"
  type        = number
  default     = 0
}

variable "site_max_replicas" {
  description = "Maximum replica count for the Site container app"
  type        = number
  default     = 10
}

variable "api_min_replicas" {
  description = "Minimum replica count for the API container app"
  type        = number
  default     = 0
}

variable "api_max_replicas" {
  description = "Maximum replica count for the API container app"
  type        = number
  default     = 5
}

# ──────────────────────────────────────────────────────────────────────
# Database
# ──────────────────────────────────────────────────────────────────────

variable "sql_admin_login" {
  description = "Administrator login for the SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "Administrator password for the SQL Server"
  type        = string
  sensitive   = true
}

variable "sql_min_capacity" {
  description = "Minimum vCore capacity for SQL Serverless (can be 0.5)"
  type        = number
  default     = 0.5
}

variable "sql_max_capacity" {
  description = "Maximum vCore capacity for SQL Serverless"
  type        = number
  default     = 2
}

variable "sql_auto_pause_delay" {
  description = "Minutes of inactivity before SQL auto-pauses (-1 to disable)"
  type        = number
  default     = 60
}

# ──────────────────────────────────────────────────────────────────────
# Redis
# ──────────────────────────────────────────────────────────────────────

variable "redis_sku" {
  description = "SKU family for Azure Cache for Redis (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}

variable "redis_capacity" {
  description = "Size of the Redis cache (0-6)"
  type        = number
  default     = 0
}