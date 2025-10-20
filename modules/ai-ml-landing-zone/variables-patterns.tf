# Added variable to control deployment pattern
variable "deployment_pattern" {
  type        = string
  description = "Deployment pattern: 'hub-spoke' or 'standalone'"
  default     = "hub-spoke"

  validation {
    condition     = contains(["hub-spoke", "standalone"], var.deployment_pattern)
    error_message = "Deployment pattern must be either 'hub-spoke' or 'standalone'."
  }
}

# Optional hub configuration for cross-subscription scenarios
variable "existing_hub_config" {
  type = object({
    hub_vnet_id                  = optional(string)
    hub_firewall_ip              = optional(string)
    hub_dns_servers              = optional(list(string), [])
    hub_dns_zones_resource_group = optional(string)
  })
  description = "Configuration for existing hub resources (cross-subscription scenarios)"
  default     = {}
}