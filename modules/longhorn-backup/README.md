# modules/longhorn-backup

Storage account + blob container for Longhorn off-cluster backups (Longhorn's native `azblob://` target).

The root module calls it when `longhorn_backup_container_create = true`, so consumers normally set that variable rather than instantiating this module directly. The usage below is for callers that need the storage outside a cluster deployment.

Requires azurerm provider >= 4.9 (`storage_account_id` on `azurerm_storage_container`).

> **NOTE:** azurerm has no `force_destroy` for non-empty containers, so retain-on-destroy must be enforced by the consumer (e.g. by removing these resources from Terraform state before `terraform destroy`).

## Usage

```hcl
module "longhorn_backup" {
  source               = "../../modules/longhorn-backup"
  storage_account_name = "myclusterlonghorn" # 3-24 lowercase alphanumeric, globally unique
  container_name       = "longhorn-backups"
  resource_group_name  = "my-rg"
  location             = "eastus"

  tags = {
    Environment = "development"
  }
}
```
