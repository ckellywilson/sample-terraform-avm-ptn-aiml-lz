variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

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

variable "hub_vnet_address_space" {
  type        = string
  default     = "10.10.0.0/24"
  description = "Address space for the hub virtual network."
}

variable "ai_lz_vnet_address_space" {
  type        = string
  default     = "192.168.0.0/23"
  description = "Address space for the AI/ML landing zone virtual network."
}

variable "tags" {
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "ai-ml-landing-zone"
    ManagedBy   = "terraform"
  }
  description = "Tags to be applied to all resources."
}

# Since this is a simplified example, we'll use basic configurations
# without the complex AVM module interface