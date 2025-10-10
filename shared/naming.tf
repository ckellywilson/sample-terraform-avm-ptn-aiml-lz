# Consistent naming convention across environments
locals {
  naming_convention = {
    resource_group = "${var.project_name}-rg-${var.environment}-${random_string.suffix.result}"
    vnet          = "${var.project_name}-vnet-${var.environment}"
    hub_vnet      = "${var.project_name}-hub-vnet-${var.environment}"
    ai_foundry    = "${var.project_name}-aif-${var.environment}"
    key_vault     = "${var.project_name}kv${var.environment}${random_string.suffix.result}"
    storage       = "${var.project_name}st${var.environment}${random_string.suffix.result}"
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}
