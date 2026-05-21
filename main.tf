# ───────────────────────────────────────────────────────────────────────────
# Resource group
# ───────────────────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = "${var.project_name}-rg"
  location = var.location
  tags     = local.tags
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1

  name = var.existing_resource_group_name
}

# ───────────────────────────────────────────────────────────────────────────
# Virtual network + node subnet
# ───────────────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "this" {
  count = var.create_vnet ? 1 : 0

  name                = "${var.project_name}-vnet"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  address_space       = [var.vnet_cidr_block]
  tags                = local.tags
}

resource "azurerm_subnet" "nodes" {
  count = var.create_vnet ? 1 : 0

  name                 = "${var.project_name}-nodes"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.node_subnet_cidr_block]
}
