variable "location" {
  type        = string
  default     = "East US 2"
  description = "Azure region where all resources should be deployed."
}

variable "name_prefix" {
  type        = string
  default     = "aiml"
  description = "Prefix for all resource names. Must be 10 characters or less and alphanumeric."
  
  validation {
    condition = var.name_prefix == null || (
      length(var.name_prefix) <= 10 &&
      can(regex("^[a-z0-9]+$", var.name_prefix))
    )
    error_message = "The name_prefix must contain only lowercase alphanumeric characters and be 10 characters or less."
  }
}

variable "ai_lz_vnet_address_space" {
  type        = string
  default     = "192.168.0.0/23"
  description = "Address space for the AI/ML landing zone virtual network."
}

variable "existing_hub_resource_group_name" {
  type        = string
  description = "Name of the existing hub virtual network resource group."
}

variable "existing_hub_vnet_name" {
  type        = string
  description = "Name of the existing hub virtual network."
}

variable "hub_dns_servers" {
  type        = list(string)
  default     = []
  description = "List of DNS servers to use from the hub network. Leave empty to use Azure default DNS."
}

variable "create_reverse_peering" {
  type        = bool
  default     = false
  description = "Whether to create reverse peering from hub to AI/ML LZ. Requires appropriate permissions on the hub."
}

variable "enable_hub_peering_settings" {
  type = object({
    allow_forwarded_traffic        = optional(bool, true)
    use_remote_gateways           = optional(bool, false)
    allow_gateway_transit_on_hub  = optional(bool, true)
  })
  default = {
    allow_forwarded_traffic       = true
    use_remote_gateways          = false
    allow_gateway_transit_on_hub = true
  }
  description = "Configuration for VNet peering settings between AI/ML LZ and hub."
}

variable "existing_private_dns_zones" {
  type = object({
    resource_group_name = optional(string)
    blob_zone_name      = optional(string)
    vault_zone_name     = optional(string)
    search_zone_name    = optional(string)
    cosmos_zone_name    = optional(string)
    cognitive_zone_name = optional(string)
  })
  default = {
    resource_group_name = null
    blob_zone_name      = null
    vault_zone_name     = null
    search_zone_name    = null
    cosmos_zone_name    = null
    cognitive_zone_name = null
  }
  description = "Configuration for existing private DNS zones. If provided, will use existing zones instead of creating new ones."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "ai-ml-landing-zone"
    ManagedBy   = "terraform"
    Pattern     = "hub-spoke"
  }
  description = "Tags to be applied to all resources."
}