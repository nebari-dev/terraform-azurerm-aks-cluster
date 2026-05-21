# terraform-azurerm-aks-cluster

A Terraform module that provisions an Azure Kubernetes Service (AKS) cluster for Nebari.

Mirrors the conventions of [terraform-aws-eks-cluster](https://github.com/nebari-dev/terraform-aws-eks-cluster).

## Usage

See [`examples/complete`](./examples/complete) for a reference deployment.

## CI/Testing

Terratest runs against a real Azure subscription. The repo needs these GitHub secrets configured:

- `AZURE_CLIENT_ID` — App registration client ID with federated OIDC credentials trusting this repo.
- `AZURE_TENANT_ID` — Azure AD tenant ID.
- `AZURE_SUBSCRIPTION_ID` — Subscription where test resources are created.

The app registration must have `Contributor` on the subscription (or on a scoped test resource group prefix).

<!-- BEGIN_TF_DOCS -->


## Usage

See `examples/complete` for a working example.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.network_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_subnet.nodes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_user_assigned_identity.kubelet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_resource_group.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_authorized_ip_ranges"></a> [authorized\_ip\_ranges](#input\_authorized\_ip\_ranges) | List of CIDRs allowed to reach the API server. Ignored when private\_cluster\_enabled=true. | `list(string)` | `[]` | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | If true, the module creates the resource group. If false, existing\_resource\_group\_name must be set. | `bool` | `true` | no |
| <a name="input_create_vnet"></a> [create\_vnet](#input\_create\_vnet) | If true, the module creates a VNet and node subnet. If false, existing\_vnet\_id and existing\_node\_subnet\_id must be set. | `bool` | `true` | no |
| <a name="input_dns_service_ip"></a> [dns\_service\_ip](#input\_dns\_service\_ip) | IP address within service\_cidr used by CoreDNS. | `string` | `"10.0.16.10"` | no |
| <a name="input_existing_node_subnet_id"></a> [existing\_node\_subnet\_id](#input\_existing\_node\_subnet\_id) | Full resource ID of an existing subnet for AKS nodes when create\_vnet=false. | `string` | `null` | no |
| <a name="input_existing_resource_group_name"></a> [existing\_resource\_group\_name](#input\_existing\_resource\_group\_name) | Name of an existing resource group to use when create\_resource\_group=false. | `string` | `null` | no |
| <a name="input_existing_vnet_id"></a> [existing\_vnet\_id](#input\_existing\_vnet\_id) | Full resource ID of an existing VNet when create\_vnet=false. | `string` | `null` | no |
| <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type) | AKS managed-identity type. Currently only "SystemAssigned" is supported by this module. | `string` | `"SystemAssigned"` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version (e.g. "1.34"). If null, AKS picks the current default. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region (e.g. "eastus"). | `string` | n/a | yes |
| <a name="input_network_plugin"></a> [network\_plugin](#input\_network\_plugin) | AKS network plugin. "azure" (recommended) or "kubenet". | `string` | `"azure"` | no |
| <a name="input_network_plugin_mode"></a> [network\_plugin\_mode](#input\_network\_plugin\_mode) | AKS network plugin mode. "overlay" (recommended for new clusters) or null for legacy Azure CNI. | `string` | `"overlay"` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Map of node-pool name to config. Exactly one pool must have mode="System"; if none specified, the first entry is defaulted to System. | <pre>map(object({<br/>    vm_size         = string<br/>    min_count       = number<br/>    max_count       = number<br/>    mode            = optional(string, "User")<br/>    os_disk_size_gb = optional(number, 128)<br/>    labels          = optional(map(string), {})<br/>    taints          = optional(list(string), [])<br/>    zones           = optional(list(string), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_node_subnet_cidr_block"></a> [node\_subnet\_cidr\_block](#input\_node\_subnet\_cidr\_block) | Node subnet CIDR when create\_vnet=true. | `string` | `"10.0.0.0/22"` | no |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | Pod CIDR when network\_plugin\_mode="overlay". | `string` | `"10.244.0.0/16"` | no |
| <a name="input_private_cluster_enabled"></a> [private\_cluster\_enabled](#input\_private\_cluster\_enabled) | If true, the API server is reachable only via a private endpoint. | `bool` | `false` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name prefix applied to all resources (e.g. "my-nebari-azure"). | `string` | n/a | yes |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | Kubernetes service CIDR. Must not overlap with VNet or pod\_cidr. | `string` | `"10.0.16.0/22"` | no |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | AKS SKU tier. "Free", "Standard", or "Premium". | `string` | `"Free"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags applied to all resources. Module-level NIC tags are merged in. | `map(string)` | `{}` | no |
| <a name="input_vnet_cidr_block"></a> [vnet\_cidr\_block](#input\_vnet\_cidr\_block) | VNet CIDR when create\_vnet=true. | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | Base64-encoded CA certificate of the AKS API server. |
| <a name="output_cluster_fqdn"></a> [cluster\_fqdn](#output\_cluster\_fqdn) | Fully-qualified domain name of the AKS API server. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Full Azure resource ID of the AKS cluster. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the AKS cluster. |
| <a name="output_host"></a> [host](#output\_host) | URL of the AKS API server (for kubeconfig server field). |
| <a name="output_kube_admin_config_raw"></a> [kube\_admin\_config\_raw](#output\_kube\_admin\_config\_raw) | Ready-to-use kubeconfig for admin access. |
| <a name="output_kubeconfig_command"></a> [kubeconfig\_command](#output\_kubeconfig\_command) | Convenience command to fetch a kubeconfig via the Azure CLI. |
| <a name="output_kubelet_identity_client_id"></a> [kubelet\_identity\_client\_id](#output\_kubelet\_identity\_client\_id) | Client ID of the user-assigned kubelet identity. |
| <a name="output_kubelet_identity_object_id"></a> [kubelet\_identity\_object\_id](#output\_kubelet\_identity\_object\_id) | Object ID of the user-assigned kubelet identity. |
| <a name="output_node_resource_group"></a> [node\_resource\_group](#output\_node\_resource\_group) | Name of the AKS-managed node resource group (MC\_*). |
| <a name="output_node_subnet_id"></a> [node\_subnet\_id](#output\_node\_subnet\_id) | Full Azure resource ID of the node subnet. |
| <a name="output_oidc_issuer_url"></a> [oidc\_issuer\_url](#output\_oidc\_issuer\_url) | OIDC issuer URL of the AKS cluster. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group containing the cluster (created or BYO). |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | Full Azure resource ID of the VNet (created or BYO). |
<!-- END_TF_DOCS -->
