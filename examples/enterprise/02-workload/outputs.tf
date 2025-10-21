output "workload_resource_group_name" {
  description = "The name of the workload resource group"
  value       = module.aiml_workload.resource_group_name
}

output "spoke_virtual_network_resource_id" {
  description = "The resource ID of the spoke virtual network"
  value       = module.aiml_workload.virtual_network_resource_id
}

output "ai_foundry_resource_id" {
  description = "The resource ID of the AI Foundry account"
  value       = module.aiml_workload.ai_foundry_resource_id
}

output "application_gateway_public_ip" {
  description = "The public IP address of the Application Gateway"
  value       = module.aiml_workload.application_gateway_public_ip_address
}

output "workload_location" {
  description = "The location where workload resources are deployed"
  value       = var.location
}

output "hub_connection_info" {
  description = "Information about the hub connection"
  value = {
    method                     = var.use_remote_state ? "remote_state" : "data_sources"
    hub_virtual_network_id     = local.hub_info.virtual_network_resource_id
    hub_firewall_ip            = local.hub_info.firewall_ip_address
    hub_resource_group_name    = local.hub_info.resource_group_name
  }
  sensitive = false
}