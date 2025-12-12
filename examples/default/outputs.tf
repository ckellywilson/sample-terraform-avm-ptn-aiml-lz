# Outputs for the default example
output "hub_virtual_network_id" {
  description = "The ID of the hub virtual network"
  value       = module.example_hub.virtual_network_resource_id
}

output "hub_firewall_ip_address" {
  description = "The IP address of the Azure Firewall in the hub virtual network"
  value       = module.example_hub.firewall_ip_address
}

output "hub_dns_resolver_inbound_ip_addresses" {
  description = "The inbound IP addresses of the DNS resolver in the hub virtual network"
  value       = module.example_hub.dns_resolver_inbound_ip_addresses
}

# Note: The following outputs will be available after the spoke VNet ID is added
# to the hub module's spoke_vnet_resource_ids and a second apply is performed
# 
# output "resource_group_name" {
#   description = "The name of the resource group where the AI/ML landing zone is deployed"
#   value       = module.test.resource_group_name
# }
#
# output "spoke_vnet_resource_id" {
#   description = "The resource ID of the AI/ML landing zone spoke VNet"
#   value       = module.test.vnet_resource_id
# }