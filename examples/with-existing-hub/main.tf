terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Provider for hub subscription to read existing hub resources (only needed for cross-subscription)
provider "azurerm" {
  alias           = "hub"
  subscription_id = var.hub_subscription_id
  features {}
}

data "azurerm_client_config" "current" {}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# Get the deployer IP address for firewall rules
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

# Data source to reference existing hub VNet
data "azurerm_virtual_network" "existing_hub" {
  provider            = var.hub_subscription_id != null ? azurerm.hub : azurerm
  name                = var.existing_hub_vnet_name
  resource_group_name = var.existing_hub_resource_group_name
}

# AI/ML Landing Zone Module with Existing Hub Integration
module "ai_ml_landing_zone" {
  source  = "Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/azurerm"
  version = "~> 1.0"

  location            = var.location
  resource_group_name = "ai-lz-rg-with-hub-${substr(module.naming.unique-seed, 0, 5)}"
  
  # VNet configuration with existing hub integration
  vnet_definition = {
    name          = "ai-lz-vnet-with-hub"
    address_space = var.ai_lz_vnet_address_space
    dns_servers   = var.hub_dns_servers
    
    # Hub VNet peering configuration
    hub_vnet_peering_definition = {
      peer_vnet_resource_id = data.azurerm_virtual_network.existing_hub.id
      # Route internet traffic through hub firewall for security
      firewall_ip_address = var.hub_firewall_ip_address
    }
  }
  
  # AI Foundry Configuration (same as default example)
  ai_foundry_definition = {
    purge_on_destroy = true
    ai_foundry = {
      create_ai_agent_service = true
    }
    ai_model_deployments = {
      "gpt-4o" = {
        name = "gpt-4.1"
        model = {
          format  = "OpenAI"
          name    = "gpt-4.1"
          version = "2025-04-14"
        }
        scale = {
          type     = "GlobalStandard"
          capacity = 1
        }
      }
    }
    ai_projects = {
      project_1 = {
        name                       = "project-1"
        description                = "Project 1 description"
        display_name               = "Project 1 Display Name"
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
    ai_search_definition = {
      this = {
        enable_diagnostic_settings = false
      }
    }
    cosmosdb_definition = {
      this = {
        enable_diagnostic_settings = false
        consistency_level          = "Session"
      }
    }
    key_vault_definition = {
      this = {
        enable_diagnostic_settings = false
      }
    }
    storage_account_definition = {
      this = {
        enable_diagnostic_settings      = false
        shared_access_key_enabled       = false # Disable shared key access for security compliance
        default_to_oauth_authentication = true  # Force OAuth authentication for all operations
        endpoints = {
          blob = {
            type = "blob"
          }
        }
      }
    }
  }
  
  # Application Gateway Configuration (optional)
  app_gateway_definition = {
    backend_address_pools = {
      example_pool = {
        name = "example-backend-pool"
      }
    }
    backend_http_settings = {
      example_http_settings = {
        name     = "example-http-settings"
        port     = 80
        protocol = "Http"
      }
    }
    frontend_ports = {
      example_frontend_port = {
        name = "example-frontend-port"
        port = 80
      }
    }
    http_listeners = {
      example_listener = {
        name               = "example-listener"
        frontend_port_name = "example-frontend-port"
      }
    }
    request_routing_rules = {
      example_rule = {
        name                       = "example-rule"
        rule_type                  = "Basic"
        http_listener_name         = "example-listener"
        backend_address_pool_name  = "example-backend-pool"
        backend_http_settings_name = "example-http-settings"
        priority                   = 100
      }
    }
  }
  
  # Supporting Services Configuration
  bastion_definition = {
  }
  container_app_environment_definition = {
    enable_diagnostic_settings = false
  }
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = false # Set to false since we're connecting to existing hub
  genai_container_registry_definition = {
    enable_diagnostic_settings = false
  }
  genai_cosmosdb_definition = {
    enable_diagnostic_settings = false
    consistency_level          = "Session"
  }
  genai_key_vault_definition = {
    public_network_access_enabled = false # Private access only in hub-spoke scenario
    # Remove network_acls since we're using private endpoints
  }
  genai_storage_account_definition = {
    enable_diagnostic_settings      = false
    shared_access_key_enabled       = false # Disable shared key access for security compliance
    default_to_oauth_authentication = true  # Force OAuth authentication for all operations
  }
  ks_ai_search_definition = {
    enable_diagnostic_settings = false
  }
  
  # Use existing private DNS zones from hub or create new ones
  private_dns_zones = var.existing_private_dns_zones.resource_group_name != null ? {
    existing_zones_resource_group_resource_id = "/subscriptions/${var.hub_subscription_id != null ? var.hub_subscription_id : data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.existing_private_dns_zones.resource_group_name}"
  } : {}
  
  tags = var.tags
}

# RBAC: Grant Storage Blob Data Contributor role to current service principal for AI Foundry storage
resource "azurerm_role_assignment" "ai_foundry_storage_blob_contributor" {
  count                = length(module.ai_ml_landing_zone.ai_foundry_storage_accounts)
  scope                = values(module.ai_ml_landing_zone.ai_foundry_storage_accounts)[count.index].resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RBAC: Grant Storage Blob Data Contributor role to current service principal for GenAI storage
resource "azurerm_role_assignment" "genai_storage_blob_contributor" {
  count                = length(module.ai_ml_landing_zone.genai_storage_accounts)
  scope                = values(module.ai_ml_landing_zone.genai_storage_accounts)[count.index].resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}