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
  subscription_id = "35c779b2-b36f-40ca-9ee5-d434a15742ef"
}
provider "http" {}

