# modules/identity

User-assigned managed identity + optional role assignments.

This sub-module is a seam for future Workload Identity / user-assigned-AKS-identity work. The root module does not call it in v0.1.0.

## Usage

```hcl
module "kubelet_identity" {
  source              = "../../modules/identity"
  name                = "my-cluster-kubelet"
  location            = "eastus"
  resource_group_name = "my-rg"

  role_assignments = {
    acr_pull = {
      scope                = azurerm_container_registry.this.id
      role_definition_name = "AcrPull"
    }
  }
}
```
