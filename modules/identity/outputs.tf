output "id" {
  description = "Full Azure resource ID of the identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "client_id" {
  description = "Client ID of the identity."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "principal_id" {
  description = "Principal/object ID of the identity."
  value       = azurerm_user_assigned_identity.this.principal_id
}
