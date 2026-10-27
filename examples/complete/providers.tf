provider "azurerm" {
  resource_providers_to_register = [
    "Microsoft.Compute",
    "Microsoft.ContainerService",
    "Microsoft.ManagedIdentity",
    "Microsoft.Network",
    "Microsoft.Storage",
  ]
  features {}
}
