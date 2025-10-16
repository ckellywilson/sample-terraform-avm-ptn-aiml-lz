variable "location" {
  description = "Azure region for the hub infrastructure"
  type        = string
  default     = "East US 2"
}

variable "location_short" {
  description = "Short name for the Azure region (used in naming)"
  type        = string
  default     = "eus2"
}

variable "hub_address_space" {
  description = "Address space for the hub virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ai_ml_address_space" {
  description = "Address space that will be used by AI/ML landing zones (for firewall rules)"
  type        = string
  default     = "192.168.0.0/22"
}

variable "firewall_sku" {
  description = "SKU tier for Azure Firewall (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.firewall_sku)
    error_message = "Firewall SKU must be Basic, Standard, or Premium."
  }
}

variable "custom_dns_servers" {
  description = "Custom DNS servers for firewall policy (leave empty for Azure defaults)"
  type        = list(string)
  default     = []
}

variable "create_private_dns_zones" {
  description = "Whether to create private DNS zones in the hub"
  type        = bool
  default     = true
}

variable "create_log_analytics" {
  description = "Whether to create a Log Analytics workspace in the hub"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "hub"
    ManagedBy   = "terraform"
    Pattern     = "azure-landing-zone"
  }
}