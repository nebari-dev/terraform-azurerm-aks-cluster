variable "storage_account_name" {
  type        = string
  description = "Name of the Longhorn backup storage account. Must be globally unique, 3-24 lowercase alphanumeric characters."
}

variable "container_name" {
  type        = string
  description = "Name of the Longhorn backup blob container."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group that contains the storage account."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "tags" {
  type    = map(string)
  default = {}
}
