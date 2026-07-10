output "cluster_id" {
  description = "Full Azure resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_fqdn" {
  description = "Fully-qualified domain name of the AKS API server."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "host" {
  description = "URL of the AKS API server (for kubeconfig server field)."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

# kube_admin_config* is only populated when Azure AD admin is enabled on the
# cluster. This module doesn't enable AAD, so we expose the local-admin
# kubeconfig (kube_config_raw) instead.
output "kube_config_raw" {
  description = "Ready-to-use kubeconfig for cluster-admin access via the local account."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate of the AKS API server."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID of the user-assigned kubelet identity."
  value       = azurerm_user_assigned_identity.kubelet.principal_id
}

output "kubelet_identity_client_id" {
  description = "Client ID of the user-assigned kubelet identity."
  value       = azurerm_user_assigned_identity.kubelet.client_id
}

output "node_resource_group" {
  description = "Name of the AKS-managed node resource group (MC_*)."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "resource_group_name" {
  description = "Name of the resource group containing the cluster (created or BYO)."
  value       = local.resource_group_name
}

output "vnet_id" {
  description = "Full Azure resource ID of the VNet (created or BYO)."
  value       = local.vnet_id
}

output "node_subnet_id" {
  description = "Full Azure resource ID of the node subnet."
  value       = local.node_subnet_id
}

output "kubeconfig_command" {
  description = "Convenience command to fetch a kubeconfig via the Azure CLI."
  value       = "az aks get-credentials --resource-group ${local.resource_group_name} --name ${azurerm_kubernetes_cluster.this.name} --admin"
}
