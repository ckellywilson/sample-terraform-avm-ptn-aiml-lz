variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  
  validation {
    condition = contains(["dev", "staging", "prod", "development", "stage", "uat", "pre-prod", "integration", "production", "live", "main", "sandbox", "test"], var.environment)
    error_message = "Environment must be one of the supported values."
  }
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
  default     = "aiml-lz"
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment"
}

variable "vnet_address_space" {
  type        = string
  description = "Address space for the AI/ML Landing Zone VNet"
}

variable "hub_address_space" {
  type        = string
  description = "Address space for the Hub VNet"
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

variable "enable_diagnostic_logs" {
  type        = bool
  description = "Enable diagnostic logging for resources"
}

variable "purge_on_destroy" {
  type        = bool
  description = "Whether to purge soft-delete capable resources on destroy"
  default     = false
}

variable "sku_tier" {
  type        = string
  description = "SKU tier for resources (Basic, Standard, Premium)"
  default     = "Standard"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to resources"
  default     = {}
}
