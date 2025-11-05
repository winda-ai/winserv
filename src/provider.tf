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
    bitwarden-secrets = {
      source = "bitwarden/bitwarden-secrets"
      version = "~> 0.5"
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

provider "bitwarden-secrets" {
  api_url         = "https://vault.bitwarden.com/api"
  identity_url    = "https://vault.bitwarden.com/identity"
  # access_token    = "${var.bitwarden_access_token}" # BW_ACCESS_TOKEN env var used automatically
  organization_id = "85e9ba59-b2af-45c6-9fee-b34500846195"
}

