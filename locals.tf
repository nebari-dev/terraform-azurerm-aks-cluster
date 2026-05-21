locals {
  # Tags merged onto every resource so NIC's tag-based discovery works.
  tags = merge(var.tags, {
    "nic.nebari.dev/cluster-name" = var.project_name
    "nic.nebari.dev/managed-by"   = "nic"
  })

  # Identify the system pool. If exactly one node group has mode="System",
  # use it. Otherwise default to the first key (alphabetical by Terraform's
  # map iteration).
  explicit_system_pools = [
    for name, ng in var.node_groups : name if ng.mode == "System"
  ]
  system_pool_name = length(local.explicit_system_pools) > 0 ? local.explicit_system_pools[0] : keys(var.node_groups)[0]
  system_pool = merge(var.node_groups[local.system_pool_name], { mode = "System" })

  # User pools = everything except the system pool.
  user_pools = {
    for name, ng in var.node_groups : name => ng
    if name != local.system_pool_name
  }
}
