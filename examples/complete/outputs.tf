output "cluster_name" {
  value = module.aks_cluster.cluster_name
}

output "resource_group_name" {
  value = module.aks_cluster.resource_group_name
}

output "kubeconfig_command" {
  value = module.aks_cluster.kubeconfig_command
}

output "kube_config_raw" {
  value     = module.aks_cluster.kube_config_raw
  sensitive = true
}

output "longhorn_backup_storage_account" {
  value = module.aks_cluster.longhorn_backup_storage_account
}

output "longhorn_backup_container" {
  value = module.aks_cluster.longhorn_backup_container
}
