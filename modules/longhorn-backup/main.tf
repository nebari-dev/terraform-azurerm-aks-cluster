# Storage account + blob container for Longhorn off-cluster backups
# (Longhorn's native azblob:// target).
#
# NOTE: azurerm has no force_destroy for non-empty containers, so retain-on-
# destroy must be enforced by the consumer (e.g. by removing these resources
# from Terraform state before `terraform destroy`).

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_container" "this" {
  name               = var.container_name
  storage_account_id = azurerm_storage_account.this.id
}
