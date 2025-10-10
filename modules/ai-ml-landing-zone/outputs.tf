output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_names.resource_group
}

output "vnet_id" {
  description = "ID of the AI/ML Landing Zone VNet"
  value       = module.ai_ml_landing_zone.resource_id
}

output "hub_vnet_id" {
  description = "ID of the Hub VNet"
  value       = module.example_hub.virtual_network_resource_id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
