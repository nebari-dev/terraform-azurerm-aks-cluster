terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.9"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0"
    }
  }
}
