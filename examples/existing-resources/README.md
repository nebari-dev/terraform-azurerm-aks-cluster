# Existing-resources example

Provisions an AKS cluster reusing an existing resource group and VNet/subnet. Useful for enterprise scenarios with pre-existing infrastructure governance.

## Usage

```bash
export ARM_SUBSCRIPTION_ID=<your-sub-id>
tofu init
tofu apply \
  -var existing_resource_group_name=my-rg \
  -var existing_vnet_id=/subscriptions/.../virtualNetworks/my-vnet \
  -var existing_node_subnet_id=/subscriptions/.../subnets/my-nodes
```
