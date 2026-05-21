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
  system_pool      = merge(var.node_groups[local.system_pool_name], { mode = "System" })

  # User pools = everything except the system pool.
  user_pools = {
    for name, ng in var.node_groups : name => ng
    if name != local.system_pool_name
  }
}

locals {
  resource_group_name     = var.create_resource_group ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.existing[0].name
  resource_group_location = var.create_resource_group ? azurerm_resource_group.this[0].location : data.azurerm_resource_group.existing[0].location

  vnet_id        = var.create_vnet ? azurerm_virtual_network.this[0].id : var.existing_vnet_id
  node_subnet_id = var.create_vnet ? azurerm_subnet.nodes[0].id : var.existing_node_subnet_id
}
