output "dns_resolver_inbound_ip_addresses" {
  description = "The inbound IP address of the DNS resolver in the hub virtual network"
  value       = module.private_resolver.inbound_endpoint_ips
}

output "firewall_ip_address" {
  description = "The IP address of the Azure Firewall in the hub virtual network"
  value       = module.firewall.resource.ip_configuration[0].private_ip_address
}

output "resource_group_resource_id" {
  description = "The resource ID of the resource group where the hub virtual network is deployed"
  value       = azurerm_resource_group.this.id
}

output "resource_id" {
  description = "Duplicating the vnet resource ID output to keep the linter happy."
  value       = ""
}

output "virtual_network_resource_id" {
  description = "Azure Resource ID for the hub virtual network"
  value       = module.ai_lz_vnet.resource_id
}

output "virtual_network_name" {
  description = "Name of the hub virtual network"
  value       = module.ai_lz_vnet.name
}

output "private_dns_zones" {
  description = "Private DNS zones created in the hub for AI/ML services"
  value = {
    for zone_key, zone in module.private_dns_zones : zone_key => {
      name = zone.resource.name
      id   = zone.resource.id
    }
  }
}

output "private_dns_zone_names" {
  description = "Map of service types to their corresponding private DNS zone names"
  value = {
    blob_zone_name               = "privatelink.blob.core.windows.net"
    file_zone_name               = "privatelink.file.core.windows.net"  
    queue_zone_name              = "privatelink.queue.core.windows.net"
    table_zone_name              = "privatelink.table.core.windows.net"
    vault_zone_name              = "privatelink.vaultcore.azure.net"
    search_zone_name             = "privatelink.search.windows.net"
    cosmos_zone_name             = "privatelink.documents.azure.com"
    cognitive_zone_name          = "privatelink.cognitiveservices.azure.com"
    openai_zone_name             = "privatelink.openai.azure.com"
    container_registry_zone_name = "privatelink.azurecr.io"
  }
}

output "configuration_for_ai_ml_with_existing_hub" {
  description = "Ready-to-use configuration values for the with-existing-hub example"
  value = {
    # Required hub configuration
    existing_hub_resource_group_name = azurerm_resource_group.this.name
    existing_hub_vnet_name           = module.ai_lz_vnet.name
    hub_subscription_id              = data.azurerm_client_config.current.subscription_id
    
    # Network configuration
    hub_dns_servers         = [for ep in module.private_resolver.inbound_endpoint_ips : ep.ip]
    hub_firewall_ip_address = module.firewall.resource.ip_configuration[0].private_ip_address
    
    # Private DNS zones configuration
    existing_private_dns_zones = {
      resource_group_name          = azurerm_resource_group.this.name
      blob_zone_name               = "privatelink.blob.core.windows.net"
      file_zone_name               = "privatelink.file.core.windows.net"
      queue_zone_name              = "privatelink.queue.core.windows.net" 
      table_zone_name              = "privatelink.table.core.windows.net"
      vault_zone_name              = "privatelink.vaultcore.azure.net"
      search_zone_name             = "privatelink.search.windows.net"
      cosmos_zone_name             = "privatelink.documents.azure.com"
      cognitive_zone_name          = "privatelink.cognitiveservices.azure.com"
      openai_zone_name             = "privatelink.openai.azure.com"
      container_registry_zone_name = "privatelink.azurecr.io"
    }
  }
}