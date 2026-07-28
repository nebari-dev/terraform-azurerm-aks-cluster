terraform {
  required_version = ">= 1.9"

  required_providers {
    # 4.9 introduced storage_account_id on azurerm_storage_container, used by
    # modules/longhorn-backup.
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
