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
# Control-plane and kubelet identities (both user-assigned).
#
# A custom kubelet_identity on the cluster requires the cluster identity to
# also be UserAssigned (azurerm provider RequiredWith). The control-plane
# identity needs "Managed Identity Operator" on the kubelet identity so AKS
# can attach it to the VMSS nodes.
# ───────────────────────────────────────────────────────────────────────────

resource "azurerm_user_assigned_identity" "cluster" {
  name                = "${var.project_name}-cluster"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  tags                = local.tags
}

resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "${var.project_name}-kubelet"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  tags                = local.tags
}

resource "azurerm_role_assignment" "cluster_kubelet_operator" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
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

  # NAP (node_provisioning_mode="Auto") requires every pool to have
  # autoscaling DISABLED — Azure rejects the nodeProvisioningProfile PATCH
  # otherwise. When NAP is on, fix the pool at min_count nodes and let NAP
  # provision additional capacity via its own NodePools. When NAP is off, run
  # the classic cluster-autoscaler with min/max.
  default_node_pool {
    name                 = local.system_pool_name
    vm_size              = local.system_pool.vm_size
    auto_scaling_enabled = var.node_provisioning_mode != "Auto"
    node_count           = var.node_provisioning_mode == "Auto" ? local.system_pool.min_count : null
    min_count            = var.node_provisioning_mode == "Auto" ? null : local.system_pool.min_count
    max_count            = var.node_provisioning_mode == "Auto" ? null : local.system_pool.max_count
    os_disk_size_gb      = local.system_pool.os_disk_size_gb
    vnet_subnet_id       = local.node_subnet_id
    node_labels          = local.system_pool.labels
    zones                = local.system_pool.zones
    tags                 = local.tags
  }

  identity {
    type         = var.identity_type
    identity_ids = [azurerm_user_assigned_identity.cluster.id]
  }

  kubelet_identity {
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
  }

  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin_mode
    network_data_plane  = var.network_data_plane
    pod_cidr            = var.network_plugin_mode == "overlay" ? var.pod_cidr : null
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  tags = local.tags

  depends_on = [azurerm_role_assignment.cluster_kubelet_operator]
}

# ───────────────────────────────────────────────────────────────────────────
# Additional user node pools
# ───────────────────────────────────────────────────────────────────────────

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = local.user_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  auto_scaling_enabled  = var.node_provisioning_mode != "Auto"
  node_count            = var.node_provisioning_mode == "Auto" ? each.value.min_count : null
  min_count             = var.node_provisioning_mode == "Auto" ? null : each.value.min_count
  max_count             = var.node_provisioning_mode == "Auto" ? null : each.value.max_count
  mode                  = each.value.mode
  os_disk_size_gb       = each.value.os_disk_size_gb
  vnet_subnet_id        = local.node_subnet_id
  node_labels           = each.value.labels
  node_taints           = each.value.taints
  zones                 = each.value.zones
  tags                  = local.tags
}

# ───────────────────────────────────────────────────────────────────────────
# Role assignment: AKS identity → node subnet
#
# Required for both networking modes:
#   * BYO subnet — the cluster identity has no implicit perms on a subnet
#     it didn't create.
#   * Module-created VNet — the VNet lives in the user's RG (not the AKS-
#     managed MC_* node RG), so the cluster identity also has no implicit
#     access here. Without this, NAP's Karpenter reports SubnetsReady=False
#     with a 403 from ARM.
# ───────────────────────────────────────────────────────────────────────────

resource "azurerm_role_assignment" "network_contributor" {
  scope                = local.node_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

# ───────────────────────────────────────────────────────────────────────────
# Node Auto Provisioning (NAP / Karpenter)
#
# The stable azurerm provider does not yet expose nodeProvisioningProfile
# (hashicorp/terraform-provider-azurerm#31418), so we PATCH it onto the cluster
# via azapi once azurerm has created it. NAP requires the Cilium dataplane,
# which the node_provisioning_mode variable validation enforces.
# ───────────────────────────────────────────────────────────────────────────

resource "azapi_update_resource" "node_auto_provisioning" {
  count = var.node_provisioning_mode == "Auto" ? 1 : 0

  type        = "Microsoft.ContainerService/managedClusters@2025-05-01"
  resource_id = azurerm_kubernetes_cluster.this.id

  body = {
    properties = {
      nodeProvisioningProfile = {
        mode = "Auto"
      }
    }
  }
}
