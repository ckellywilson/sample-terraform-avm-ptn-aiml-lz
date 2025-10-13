# Scenario 1: Single Subscription Hub-Spoke Configuration
# This represents your current setup - both hub and spoke in same subscription

terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Use your existing module configuration
module "ai_ml_landing_zone" {
  source = "../../modules/ai-ml-landing-zone"
  
  environment         = "dev"
  project_name        = "aiml-single"
  location           = "East US 2"
  vnet_address_space = "10.0.0.0/16"
  hub_address_space  = "10.1.0.0/24"
  
  enable_diagnostic_logs = false
  purge_on_destroy      = true
  sku_tier              = "Basic"
  
  tags = {
    Scenario     = "Single-Subscription-Hub-Spoke"
    Environment  = "Development"
    CostCenter   = "IT-Platform"
    Owner        = "platform-team@company.com"
  }
}