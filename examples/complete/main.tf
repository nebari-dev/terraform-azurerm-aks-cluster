module "aks_cluster" {
  source = "../.."

  project_name = var.project_name
  location     = var.location

  kubernetes_version      = "1.34"
  sku_tier                = "Free"
  private_cluster_enabled = false

  vnet_cidr_block        = "10.10.0.0/16"
  node_subnet_cidr_block = "10.10.0.0/22"
  pod_cidr               = "10.244.0.0/16"
  service_cidr           = "10.10.16.0/22"
  dns_service_ip         = "10.10.16.10"

  node_groups = {
    system = {
      vm_size   = "Standard_D2_v3"
      min_count = 1
      max_count = 3
      mode      = "System"
    }
    user = {
      vm_size   = "Standard_D4_v3"
      min_count = 1
      max_count = 5
    }
    worker = {
      vm_size   = "Standard_D4_v3"
      min_count = 0
      max_count = 5
    }
  }

  tags = {
    Environment = "development"
    Project     = "nebari"
  }
}

module "longhorn_backup" {
  source = "../../modules/longhorn-backup"

  # Storage account names: 3-24 lowercase alphanumeric characters, globally unique.
  storage_account_name = "${substr(replace(lower(var.project_name), "/[^a-z0-9]/", ""), 0, 21)}lhb"
  container_name       = "longhorn-backups"
  resource_group_name  = module.aks_cluster.resource_group_name
  location             = var.location

  tags = {
    Environment = "development"
    Project     = "nebari"
  }
}
