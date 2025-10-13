# Scenario 3: Standalone Application Landing Zone
# All resources self-contained in one subscription, no external hub dependencies

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

# Direct use of Azure AI/ML Landing Zone module in standalone mode
module "standalone_ai_ml_landing_zone" {
  source  = "Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/azurerm"
  version = "~> 1.0"
  
  location            = "East US 2"
  resource_group_name = "aiml-standalone-rg-${random_string.suffix.result}"
  
  vnet_definition = {
    name          = "aiml-standalone-vnet"
    address_space = "10.50.0.0/16"
  }
  
  # AI Foundry Configuration
  ai_foundry_definition = {
    purge_on_destroy = true
    ai_foundry = {
      create_ai_agent_service = true
    }
    ai_model_deployments = {
      "gpt-4o" = {
        name = "gpt-4o"
        model = {
          format  = "OpenAI"
          name    = "gpt-4o"
          version = "2024-08-06"
        }
        scale = {
          type     = "Standard"
          capacity = 10
        }
      }
    }
    ai_projects = {
      project_1 = {
        name                       = "standalone-ai-project"
        description                = "Standalone AI project for independent workload"
        display_name               = "Standalone AI Project"
        create_project_connections = true
        cosmos_db_connection = {
          new_resource_map_key = "this"
        }
        ai_search_connection = {
          new_resource_map_key = "this"
        }
        storage_account_connection = {
          new_resource_map_key = "this"
        }
      }
    }
  }
  
  # Supporting Services - all self-contained
  genai_container_registry_definition = {
    enable_diagnostic_settings = false
  }
  
  genai_cosmosdb_definition = {
    enable_diagnostic_settings = false
    consistency_level          = "Session"
  }
  
  genai_key_vault_definition = {
    public_network_access_enabled = true # For development/testing
    network_acls = {
      bypass   = "AzureServices"
      ip_rules = ["${data.http.ip.response_body}/32"]
    }
  }
  
  genai_storage_account_definition = {
    enable_diagnostic_settings = false
  }
  
  ks_ai_search_definition = {
    enable_diagnostic_settings = false
  }
  
  # Standalone mode - no external dependencies
  flag_platform_landing_zone = false
  enable_telemetry           = true
  
  tags = {
    Scenario     = "Standalone-Application"
    Environment  = "Development"
    CostCenter   = "Application-AIML"
    Owner        = "app-team@company.com"
    Pattern      = "Self-Contained"
  }
}

# Generate unique naming suffix
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Get current IP for firewall rules
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}