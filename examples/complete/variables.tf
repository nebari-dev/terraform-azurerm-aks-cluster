variable "project_name" {
  type        = string
  description = "Name prefix applied to all resources."
  default     = "nebari-example"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "eastus"
}
