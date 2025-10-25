# Outputs for the standalone example

# output "ai_foundry_resource_id" {
#   description = "The resource ID of the AI Foundry hub"
#   value       = module.test.ai_foundry_resource_id
#   sensitive   = false
# }

# output "ai_foundry_principal_id" {
#   description = "The principal ID of the AI Foundry hub's managed identity"
#   value       = module.test.ai_foundry_principal_id
#   sensitive   = false
# }

output "storage_account_rbac_enabled" {
  description = "Whether RBAC role assignments were created for storage account access"
  value       = local.ai_foundry_requires_storage_rbac
}

output "storage_shared_key_enabled" {
  description = "Whether shared access keys are enabled for storage accounts"
  value       = var.storage_shared_access_key_enabled
}

# output "resource_group_name" {
#   description = "The name of the resource group where resources are deployed"
#   value       = module.test.resource_group_name
# }

# output "virtual_network_resource_id" {
#   description = "The resource ID of the virtual network"
#   value       = module.test.virtual_network_resource_id
# }