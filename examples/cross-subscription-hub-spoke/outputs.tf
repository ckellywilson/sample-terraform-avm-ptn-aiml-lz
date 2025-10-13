output "ai_foundry_resource_id" {
  description = "Resource ID of the Azure AI Foundry instance"
  value       = module.ai_ml_landing_zone.ai_foundry_resource_id
}

output "ai_foundry_endpoint" {
  description = "Endpoint URL of the Azure AI Foundry instance"
  value       = module.ai_ml_landing_zone.ai_foundry_endpoint
}

output "spoke_vnet_id" {
  description = "Resource ID of the spoke virtual network"
  value       = azurerm_virtual_network.spoke_vnet.id
}

output "spoke_resource_group_id" {
  description = "Resource ID of the spoke resource group"
  value       = azurerm_resource_group.spoke_rg.id
}

output "private_endpoints_subnet_id" {
  description = "Resource ID of the private endpoints subnet"
  value       = azurerm_subnet.private_endpoints.id
}

output "hub_to_spoke_peering_status" {
  description = "Status of hub to spoke VNet peering"
  value       = azurerm_virtual_network_peering.hub_to_spoke.virtual_network_access
}

output "spoke_to_hub_peering_status" {
  description = "Status of spoke to hub VNet peering"
  value       = azurerm_virtual_network_peering.spoke_to_hub.virtual_network_access
}

output "dns_zone_links" {
  description = "Private DNS zone virtual network links created"
  value = {
    for zone_name, link in azurerm_private_dns_zone_virtual_network_link.spoke_dns_links :
    zone_name => {
      link_name = link.name
      enabled   = link.registration_enabled
    }
  }
}