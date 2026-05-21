variable "project_name" {
  type    = string
  default = "nebari-byo-example"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "existing_resource_group_name" {
  type        = string
  description = "Name of an existing resource group."
}

variable "existing_vnet_id" {
  type        = string
  description = "Full resource ID of an existing VNet."
}

variable "existing_node_subnet_id" {
  type        = string
  description = "Full resource ID of an existing subnet for AKS nodes."
}
