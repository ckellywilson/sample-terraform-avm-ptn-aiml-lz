# Hub Connectivity Deployment Outputs

output "hub_virtual_network_id" {
  description = "Resource ID of the hub virtual network"
  value       = module.alz_connectivity.virtual_networks.primary_hub.id
}

output "hub_virtual_network_name" {
  description = "Name of the hub virtual network"
  value       = module.alz_connectivity.virtual_networks.primary_hub.name
}

output "hub_resource_group_name" {
  description = "Name of the hub resource group"
  value       = module.alz_connectivity.virtual_networks.primary_hub.resource_group_name
}

output "hub_resource_group_id" {
  description = "Resource ID of the hub resource group"
  value       = module.alz_connectivity.resource_group_id
}

output "private_dns_zones" {
  description = "Map of private DNS zones created"
  value       = module.alz_connectivity.private_dns_zones
}

output "azure_firewall_id" {
  description = "Resource ID of the Azure Firewall"
  value       = module.alz_connectivity.firewalls.primary_hub.id
}

output "azure_firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = module.alz_connectivity.firewalls.primary_hub.ip_configuration[0].private_ip_address
}