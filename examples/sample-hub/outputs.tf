output "hub_resource_group_name" {
  description = "Name of the hub resource group"
  value       = azurerm_resource_group.hub.name
}

output "hub_virtual_network_name" {
  description = "Name of the hub virtual network"
  value       = module.hub_vnet.name
}

output "hub_virtual_network_id" {
  description = "Resource ID of the hub virtual network"
  value       = module.hub_vnet.resource_id
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Public IP address of the Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}

output "dns_resolver_inbound_ip" {
  description = "Inbound IP address of the DNS private resolver"
  value       = azurerm_private_dns_resolver_inbound_endpoint.hub.ip_configurations[0].private_ip_address
}

output "private_dns_zones" {
  description = "Private DNS zones created in the hub"
  value = {
    for k, v in azurerm_private_dns_zone.ai_services : k => {
      name = v.name
      id   = v.id
    }
  }
}

output "spoke_route_table_id" {
  description = "Route table ID for spoke networks to use firewall as next hop"
  value       = azurerm_route_table.spoke_routes.id
}

output "configuration_for_ai_ml_landing_zone" {
  description = "Configuration values to use in the AI/ML Landing Zone with-existing-hub example"
  value = {
    existing_hub_resource_group_name = azurerm_resource_group.hub.name
    existing_hub_vnet_name           = module.hub_vnet.name
    hub_dns_servers                  = [azurerm_private_dns_resolver_inbound_endpoint.hub.ip_configurations[0].private_ip_address]
    firewall_ip_address              = azurerm_firewall.hub.ip_configuration[0].private_ip_address
    existing_private_dns_zones = var.create_private_dns_zones ? {
      resource_group_name = azurerm_resource_group.hub.name
      blob_zone_name      = "privatelink.blob.core.windows.net"
      vault_zone_name     = "privatelink.vaultcore.azure.net"
      search_zone_name    = "privatelink.search.windows.net"
      cosmos_zone_name    = "privatelink.documents.azure.com"
      cognitive_zone_name = "privatelink.cognitiveservices.azure.com"
    } : null
  }
}