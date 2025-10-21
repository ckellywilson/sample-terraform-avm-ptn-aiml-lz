# Data source to get current client configuration
data "azurerm_client_config" "current" {}

# Data source for platform deployment outputs via remote state
data "terraform_remote_state" "platform" {
  count   = var.use_remote_state ? 1 : 0
  backend = var.remote_state_backend
  config  = var.remote_state_config
}

# Alternative: Direct data sources for existing hub infrastructure
# Use these when not using remote state
data "azurerm_virtual_network" "hub" {
  count               = var.use_remote_state ? 0 : 1
  name                = var.hub_virtual_network_name
  resource_group_name = var.hub_resource_group_name
}

data "azurerm_firewall" "hub" {
  count               = var.use_remote_state ? 0 : 1
  name                = var.hub_firewall_name
  resource_group_name = var.hub_resource_group_name
}

data "azurerm_private_dns_resolver" "hub" {
  count               = var.use_remote_state ? 0 : 1
  name                = var.hub_dns_resolver_name
  resource_group_name = var.hub_resource_group_name
}