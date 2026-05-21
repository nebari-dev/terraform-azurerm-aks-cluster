module "aks_cluster" {
  source = "../.."

  project_name = var.project_name
  location     = var.location

  create_resource_group        = false
  existing_resource_group_name = var.existing_resource_group_name

  create_vnet             = false
  existing_vnet_id        = var.existing_vnet_id
  existing_node_subnet_id = var.existing_node_subnet_id

  node_groups = {
    system = {
      vm_size   = "Standard_D2_v3"
      min_count = 1
      max_count = 3
      mode      = "System"
    }
  }

  tags = {
    Environment = "development"
    Project     = "nebari"
  }
}
