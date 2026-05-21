output "cluster_id" {
  description = "Full Azure resource ID of the AKS cluster."
  value       = null
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = null
}

output "cluster_fqdn" {
  description = "Fully-qualified domain name of the AKS API server."
  value       = null
}

output "host" {
  description = "URL of the AKS API server (for kubeconfig server field)."
  value       = null
}

output "kube_admin_config_raw" {
  description = "Ready-to-use kubeconfig for admin access."
  value       = null
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate of the AKS API server."
  value       = null
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster (for future Workload Identity work)."
  value       = null
}

output "kubelet_identity_object_id" {
  description = "Object ID of the user-assigned kubelet identity."
  value       = null
}

output "kubelet_identity_client_id" {
  description = "Client ID of the user-assigned kubelet identity."
  value       = null
}

output "node_resource_group" {
  description = "Name of the AKS-managed node resource group (MC_*)."
  value       = null
}

output "resource_group_name" {
  description = "Name of the resource group containing the cluster (created or BYO)."
  value       = null
}

output "vnet_id" {
  description = "Full Azure resource ID of the VNet (created or BYO)."
  value       = null
}

output "node_subnet_id" {
  description = "Full Azure resource ID of the node subnet."
  value       = null
}

output "kubeconfig_command" {
  description = "Convenience command to fetch a kubeconfig via the Azure CLI."
  value       = null
}
