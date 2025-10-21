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