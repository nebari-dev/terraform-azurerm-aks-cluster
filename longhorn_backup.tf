################################################################################
# Longhorn backup container (optional)
################################################################################
# Optional storage account + blob container for Longhorn off-cluster backups
# (Longhorn's native azblob:// target). Disabled by default; enabled by
# consumers (e.g. Nebari Infrastructure Core) that schedule Longhorn backups.
#
# NOTE: azurerm has no force_destroy for non-empty containers, so retain-on-
# destroy must be enforced by the consumer (e.g. by removing these resources
# from Terraform state before `terraform destroy`).

resource "azurerm_storage_account" "longhorn_backup" {
  count                    = var.longhorn_backup_container_create ? 1 : 0
  name                     = var.longhorn_backup_storage_account
  resource_group_name      = local.resource_group_name
  location                 = local.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_container" "longhorn_backup" {
  count              = var.longhorn_backup_container_create ? 1 : 0
  name               = var.longhorn_backup_container_name
  storage_account_id = azurerm_storage_account.longhorn_backup[0].id
}
