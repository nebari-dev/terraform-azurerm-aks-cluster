output "cluster_name" {
  value = module.aks_cluster.cluster_name
}

output "kubeconfig_command" {
  value = module.aks_cluster.kubeconfig_command
}
