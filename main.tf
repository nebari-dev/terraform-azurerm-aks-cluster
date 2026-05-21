# ───────────────────────────────────────────────────────────────────────────
# Resource group
# ───────────────────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = "${var.project_name}-rg"
  location = var.location
  tags     = local.tags
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1

  name = var.existing_resource_group_name
}

# ───────────────────────────────────────────────────────────────────────────
# Virtual network + node subnet
# ───────────────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "this" {
  count = var.create_vnet ? 1 : 0

  name                = "${var.project_name}-vnet"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  address_space       = [var.vnet_cidr_block]
  tags                = local.tags
}

resource "azurerm_subnet" "nodes" {
  count = var.create_vnet ? 1 : 0

  name                 = "${var.project_name}-nodes"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.node_subnet_cidr_block]
}

# ───────────────────────────────────────────────────────────────────────────
# Kubelet identity (user-assigned).
#
# A custom kubelet_identity on the cluster requires the cluster identity to
# also be UserAssigned (azurerm provider RequiredWith). We reuse this same
# identity for the control plane so AKS handles the Managed Identity Operator
# assignment implicitly — avoiding a role assignment the deployer often lacks
# permission to create.
# ───────────────────────────────────────────────────────────────────────────

resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "${var.project_name}-kubelet"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  tags                = local.tags
}

# ───────────────────────────────────────────────────────────────────────────
# AKS cluster (system node pool inline)
# ───────────────────────────────────────────────────────────────────────────

resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.project_name}-aks"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  dns_prefix          = var.project_name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  private_cluster_enabled = var.private_cluster_enabled

  api_server_access_profile {
    authorized_ip_ranges = var.private_cluster_enabled || length(var.authorized_ip_ranges) == 0 ? null : var.authorized_ip_ranges
  }

  default_node_pool {
    name                 = local.system_pool_name
    vm_size              = local.system_pool.vm_size
    min_count            = local.system_pool.min_count
    max_count            = local.system_pool.max_count
    auto_scaling_enabled = true
    os_disk_size_gb      = local.system_pool.os_disk_size_gb
    vnet_subnet_id       = local.node_subnet_id
    node_labels          = local.system_pool.labels
    zones                = local.system_pool.zones
    tags                 = local.tags
  }

  identity {
    type         = var.identity_type
    identity_ids = [azurerm_user_assigned_identity.kubelet.id]
  }

  kubelet_identity {
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
  }

  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin_mode
    pod_cidr            = var.network_plugin_mode == "overlay" ? var.pod_cidr : null
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  tags = local.tags
}

# ───────────────────────────────────────────────────────────────────────────
# Additional user node pools
# ───────────────────────────────────────────────────────────────────────────

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = local.user_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  auto_scaling_enabled  = true
  mode                  = each.value.mode
  os_disk_size_gb       = each.value.os_disk_size_gb
  vnet_subnet_id        = local.node_subnet_id
  node_labels           = each.value.labels
  node_taints           = each.value.taints
  zones                 = each.value.zones
  tags                  = local.tags
}

# ───────────────────────────────────────────────────────────────────────────
# Role assignment: AKS identity → existing subnet (only when BYO networking)
# ───────────────────────────────────────────────────────────────────────────

resource "azurerm_role_assignment" "network_contributor" {
  count = var.create_vnet ? 0 : 1

  scope                = var.existing_node_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
}
