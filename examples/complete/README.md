# Complete example

Provisions an AKS cluster with the module's full default feature set: VNet, system + user + worker node pools, Azure CNI Overlay networking, public API endpoint.

## Usage

```bash
export ARM_SUBSCRIPTION_ID=<your-sub-id>
tofu init
tofu apply
```

After apply, fetch a kubeconfig with the command in the `kubeconfig_command` output.
