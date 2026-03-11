terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # ──────────────────────────────────────────────────────────────────────
  # State Management
  # ──────────────────────────────────────────────────────────────────────
  # For this POC, state is stored locally. In production, uncomment the
  # block below to centralize state in an Azure Storage Account with
  # locking and versioning enabled.
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "marketing-site.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }

  subscription_id = var.subscription_id
}