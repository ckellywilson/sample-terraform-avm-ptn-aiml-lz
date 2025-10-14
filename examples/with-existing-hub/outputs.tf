output "ai_ml_resource_group_name" {
  description = "The name of the AI/ML Landing Zone resource group."
  value       = azurerm_resource_group.ai_ml.name
}

output "ai_ml_virtual_network_name" {
  description = "The name of the AI/ML Landing Zone virtual network."
  value       = azurerm_virtual_network.ai_ml.name
}

output "ai_ml_virtual_network_id" {
  description = "The resource ID of the AI/ML Landing Zone virtual network."
  value       = azurerm_virtual_network.ai_ml.id
}

output "hub_virtual_network_id" {
  description = "The resource ID of the existing hub virtual network."
  value       = data.azurerm_virtual_network.existing_hub.id
}

output "vnet_peering_id" {
  description = "The resource ID of the VNet peering from AI/ML LZ to hub."
  value       = azurerm_virtual_network_peering.ai_ml_to_hub.id
}

output "reverse_vnet_peering_id" {
  description = "The resource ID of the reverse VNet peering from hub to AI/ML LZ (if created)."
  value       = var.create_reverse_peering ? azurerm_virtual_network_peering.hub_to_ai_ml[0].id : null
}

output "storage_account_name" {
  description = "The name of the AI Foundry storage account."
  value       = azurerm_storage_account.ai_foundry.name
}

output "key_vault_name" {
  description = "The name of the AI Foundry Key Vault."
  value       = azurerm_key_vault.ai_foundry.name
}

output "cognitive_services_name" {
  description = "The name of the AI Services account."
  value       = azurerm_cognitive_account.ai_foundry.name
}

output "ai_search_service_name" {
  description = "The name of the AI Search service."
  value       = azurerm_search_service.ai_foundry.name
}

output "cosmos_db_account_name" {
  description = "The name of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.ai_foundry.name
}

output "application_insights_name" {
  description = "The name of the Application Insights component."
  value       = azurerm_application_insights.ai_foundry.name
}

output "private_dns_zones" {
  description = "Information about private DNS zones (created or existing)."
  value = {
    blob_zone_id      = var.existing_private_dns_zones.blob_zone_name == null ? azurerm_private_dns_zone.blob[0].id : data.azurerm_private_dns_zone.existing_blob[0].id
    vault_zone_id     = var.existing_private_dns_zones.vault_zone_name == null ? (length(azurerm_private_dns_zone.vault) > 0 ? azurerm_private_dns_zone.vault[0].id : null) : (length(data.azurerm_private_dns_zone.existing_vault) > 0 ? data.azurerm_private_dns_zone.existing_vault[0].id : null)
    search_zone_id    = var.existing_private_dns_zones.search_zone_name == null ? (length(azurerm_private_dns_zone.search) > 0 ? azurerm_private_dns_zone.search[0].id : null) : (length(data.azurerm_private_dns_zone.existing_search) > 0 ? data.azurerm_private_dns_zone.existing_search[0].id : null)
    cosmos_zone_id    = var.existing_private_dns_zones.cosmos_zone_name == null ? (length(azurerm_private_dns_zone.cosmos) > 0 ? azurerm_private_dns_zone.cosmos[0].id : null) : (length(data.azurerm_private_dns_zone.existing_cosmos) > 0 ? data.azurerm_private_dns_zone.existing_cosmos[0].id : null)
    cognitive_zone_id = var.existing_private_dns_zones.cognitive_zone_name == null ? (length(azurerm_private_dns_zone.cognitive) > 0 ? azurerm_private_dns_zone.cognitive[0].id : null) : (length(data.azurerm_private_dns_zone.existing_cognitive) > 0 ? data.azurerm_private_dns_zone.existing_cognitive[0].id : null)
  }
}