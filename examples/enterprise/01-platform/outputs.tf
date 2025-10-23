output "hub_network_info" {
  description = "Hub network information for workload consumption"
  value = {
    virtual_network_resource_id           = module.connectivity_hub.virtual_network_resource_id
    firewall_ip_address                   = module.connectivity_hub.firewall_ip_address
    dns_resolver_inbound_ip_addresses     = module.connectivity_hub.dns_resolver_inbound_ip_addresses
    resource_group_resource_id            = module.connectivity_hub.resource_group_resource_id
  }
  sensitive = false
}

output "platform_location" {
  description = "The location where platform resources are deployed"
  value       = var.location
}

output "platform_resource_group_name" {
  description = "The name of the platform resource group"
  value       = split("/", module.connectivity_hub.resource_group_resource_id)[4]
}