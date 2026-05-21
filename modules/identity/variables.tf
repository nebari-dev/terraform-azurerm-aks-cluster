variable "name" {
  type        = string
  description = "Name of the user-assigned managed identity."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group that contains the identity."
}

variable "role_assignments" {
  type = map(object({
    scope                = string
    role_definition_name = string
  }))
  description = "Map of role assignments to create. Key is a stable identifier; value is the scope and role."
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
