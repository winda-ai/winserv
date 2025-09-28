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
  features {}
  # Authentication handled via Azure CLI locally (user) or ARM_* env vars (OIDC in CI).
  # subscription_id can be inferred from ARM_SUBSCRIPTION_ID; omit here for portability.
}
provider "http" {}

