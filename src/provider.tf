terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
  backend "azurerm" {}
}
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
        prevent_deletion_if_contains_resources = false
    }
  }
  # Authentication handled via Azure CLI locally (user) or ARM_* env vars (OIDC in CI).
  # subscription_id can be inferred from ARM_SUBSCRIPTION_ID; omit here for portability.
}
provider "http" {}

