# ───────────────────────────────────────────────────────────────────────────
# Common
# ───────────────────────────────────────────────────────────────────────────

variable "project_name" {
  type        = string
  description = "Name prefix applied to all resources (e.g. \"my-nebari-azure\")."
}

variable "location" {
  type        = string
  description = "Azure region (e.g. \"eastus\")."
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources. Module-level NIC tags are merged in."
  default     = {}
}

# ───────────────────────────────────────────────────────────────────────────
# Resource group
# ───────────────────────────────────────────────────────────────────────────

variable "create_resource_group" {
  type        = bool
  description = "If true, the module creates the resource group. If false, existing_resource_group_name must be set."
  default     = true
}

variable "existing_resource_group_name" {
  type        = string
  description = "Name of an existing resource group to use when create_resource_group=false."
  default     = null
}

# ───────────────────────────────────────────────────────────────────────────
# Networking
# ───────────────────────────────────────────────────────────────────────────

variable "create_vnet" {
  type        = bool
  description = "If true, the module creates a VNet and node subnet. If false, existing_vnet_id and existing_node_subnet_id must be set."
  default     = true
}

variable "vnet_cidr_block" {
  type        = string
  description = "VNet CIDR when create_vnet=true."
  default     = "10.0.0.0/16"
}

variable "node_subnet_cidr_block" {
  type        = string
  description = "Node subnet CIDR when create_vnet=true."
  default     = "10.0.0.0/22"
}

variable "existing_vnet_id" {
  type        = string
  description = "Full resource ID of an existing VNet when create_vnet=false."
  default     = null
}

variable "existing_node_subnet_id" {
  type        = string
  description = "Full resource ID of an existing subnet for AKS nodes when create_vnet=false."
  default     = null
}

variable "network_plugin" {
  type        = string
  description = "AKS network plugin. \"azure\" (recommended) or \"kubenet\"."
  default     = "azure"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "network_plugin must be one of: azure, kubenet."
  }
}

variable "network_plugin_mode" {
  type        = string
  description = "AKS network plugin mode. \"overlay\" (recommended for new clusters) or null for legacy Azure CNI."
  default     = "overlay"
}

variable "pod_cidr" {
  type        = string
  description = "Pod CIDR when network_plugin_mode=\"overlay\"."
  default     = "10.244.0.0/16"
}

variable "network_data_plane" {
  type        = string
  description = "AKS network dataplane. \"azure\" (default) or \"cilium\" (Azure CNI Powered by Cilium). \"cilium\" requires network_plugin=\"azure\" and network_plugin_mode=\"overlay\"."
  default     = "azure"
  validation {
    condition     = contains(["azure", "cilium"], var.network_data_plane)
    error_message = "network_data_plane must be one of: azure, cilium."
  }
  validation {
    condition     = var.network_data_plane != "cilium" || (var.network_plugin == "azure" && var.network_plugin_mode == "overlay")
    error_message = "network_data_plane=\"cilium\" requires network_plugin=\"azure\" and network_plugin_mode=\"overlay\"."
  }
}

variable "service_cidr" {
  type        = string
  description = "Kubernetes service CIDR. Must not overlap with VNet or pod_cidr."
  default     = "10.0.16.0/22"
}

variable "dns_service_ip" {
  type        = string
  description = "IP address within service_cidr used by CoreDNS."
  default     = "10.0.16.10"
}

# ───────────────────────────────────────────────────────────────────────────
# Cluster
# ───────────────────────────────────────────────────────────────────────────

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version (e.g. \"1.34\"). If null, AKS picks the current default."
  default     = null
}

variable "private_cluster_enabled" {
  type        = bool
  description = "If true, the API server is reachable only via a private endpoint."
  default     = false
}

variable "authorized_ip_ranges" {
  type        = list(string)
  description = "List of CIDRs allowed to reach the API server. Ignored when private_cluster_enabled=true."
  default     = []
}

variable "sku_tier" {
  type        = string
  description = "AKS SKU tier. \"Free\", \"Standard\", or \"Premium\"."
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be one of: Free, Standard, Premium."
  }
}

variable "identity_type" {
  type        = string
  description = "AKS managed-identity type. Must be \"UserAssigned\" because this module provisions a user-assigned kubelet identity, which the azurerm provider requires to be paired with a UserAssigned cluster identity."
  default     = "UserAssigned"
  validation {
    condition     = var.identity_type == "UserAssigned"
    error_message = "Only UserAssigned is supported in this version."
  }
}

variable "node_provisioning_mode" {
  type        = string
  description = "AKS node provisioning mode. \"Manual\" (default) or \"Auto\" to enable Node Auto Provisioning (Karpenter). \"Auto\" requires network_data_plane=\"cilium\". Applied via the azapi provider because the stable azurerm provider does not yet expose this argument (see hashicorp/terraform-provider-azurerm#31418)."
  default     = "Manual"
  validation {
    condition     = contains(["Manual", "Auto"], var.node_provisioning_mode)
    error_message = "node_provisioning_mode must be one of: Manual, Auto."
  }
  validation {
    condition     = var.node_provisioning_mode != "Auto" || var.network_data_plane == "cilium"
    error_message = "node_provisioning_mode=\"Auto\" requires network_data_plane=\"cilium\"."
  }
}

# ───────────────────────────────────────────────────────────────────────────
# Node groups
# ───────────────────────────────────────────────────────────────────────────

variable "node_groups" {
  type = map(object({
    vm_size         = string
    min_count       = number
    max_count       = number
    mode            = optional(string, "User")
    os_disk_size_gb = optional(number, 128)
    labels          = optional(map(string), {})
    taints          = optional(list(string), [])
    zones           = optional(list(string), [])
  }))
  description = "Map of node-pool name to config. Exactly one pool must have mode=\"System\"; if none specified, the first entry is defaulted to System."

  validation {
    condition     = length(var.node_groups) >= 1
    error_message = "At least one node group is required."
  }

  validation {
    condition = length([
      for name, ng in var.node_groups : name if ng.mode == "System"
    ]) <= 1
    error_message = "At most one node group may have mode=\"System\"."
  }
}
