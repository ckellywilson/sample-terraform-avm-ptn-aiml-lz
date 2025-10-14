output "hub_resource_group_name" {
  description = "The name of the hub resource group."
  value       = azurerm_resource_group.hub.name
}

output "hub_virtual_network_name" {
  description = "The name of the hub virtual network."
  value       = azurerm_virtual_network.hub.name
}

output "hub_virtual_network_id" {
  description = "The resource ID of the hub virtual network."
  value       = azurerm_virtual_network.hub.id
}

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