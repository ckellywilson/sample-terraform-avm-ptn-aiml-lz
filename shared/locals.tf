# Shared locals across all environments
locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = "AI-ML-Landing-Zone"
    ManagedBy   = "Terraform"
    Repository  = "sample-default-terraform-avm-ptn-aiml-lz"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Environment-specific configurations
  environment_configs = {
    dev = {
      location                = "East US 2"
      vnet_address_space     = "10.0.0.0/16"
      hub_address_space      = "10.1.0.0/24"
      sku_tier               = "Basic"
      enable_diagnostic_logs = false
      purge_on_destroy      = true
    }
    staging = {
      location                = "Central US"
      vnet_address_space     = "10.10.0.0/16"
      hub_address_space      = "10.11.0.0/24"
      sku_tier               = "Standard"
      enable_diagnostic_logs = true
      purge_on_destroy      = false
    }
    prod = {
      location                = "West US 2"
      vnet_address_space     = "10.20.0.0/16"
      hub_address_space      = "10.21.0.0/24"
      sku_tier               = "Premium"
      enable_diagnostic_logs = true
      purge_on_destroy      = false
    }
  }
}
