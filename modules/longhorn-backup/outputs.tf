output "storage_account_id" {
  description = "Full Azure resource ID of the storage account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.this.name
}

output "container_id" {
  description = "Full Azure resource ID of the blob container."
  value       = azurerm_storage_container.this.id
}

output "container_name" {
  description = "Name of the blob container."
  value       = azurerm_storage_container.this.name
}
