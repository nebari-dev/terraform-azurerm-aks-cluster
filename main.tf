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
