output "cluster_name" {
  value = module.aks_cluster.cluster_name
}

output "resource_group_name" {
  value = module.aks_cluster.resource_group_name
}

output "kubeconfig_command" {
  value = module.aks_cluster.kubeconfig_command
}
