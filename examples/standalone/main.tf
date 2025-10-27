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
  subscription_id     = var.subscription_id
  storage_use_azuread = var.storage_use_azuread_authentication
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

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.3.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# Get the deployer IP address to allow for public write to the key vault. This is to make sure the tests run.
# In practice your deployer machine will be on a private network and this will not be required.
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

# Get current subscription information
data "azurerm_client_config" "current" {}

# Local values for storage RBAC logic
locals {
  # Storage RBAC logic
  storage_shared_key_disabled      = !var.storage_shared_access_key_enabled
  ai_foundry_requires_storage_rbac = local.storage_shared_key_disabled
}

module "test" {
  source = "github.com/ckellywilson/terraform-azurerm-avm-ptn-aiml-landing-zone"

  location            = var.location
  resource_group_name = "ai-lz-rg-standalone-${substr(module.naming.unique-seed, 0, 5)}"
  vnet_definition = {
    name          = "ai-lz-vnet-standalone"
    address_space = "192.168.0.0/23" # has to be out of 192.168.0.0/16 currently. Other RFC1918 not supported for foundry capabilityHost injection.
  }
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
        enable_diagnostic_settings = false
        shared_access_key_enabled  = var.storage_shared_access_key_enabled
        endpoints = {
          blob = {
            type = "blob"
          }
        }
      }
    }
  }
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
  bastion_definition = {
  }
  container_app_environment_definition = {
    enable_diagnostic_settings = false
  }
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = false # Standalone deployments are always self-contained (no platform infrastructure)

  # DNS zones configuration for standalone deployment
  private_dns_zones = {
    existing_zones_resource_group_resource_id = var.existing_dns_zones_rg_id != null ? var.existing_dns_zones_rg_id : azurerm_resource_group.dns_zones[0].id
    allow_internet_resolution_fallback        = false
  }

  genai_container_registry_definition = {
    enable_diagnostic_settings = false
  }
  genai_cosmosdb_definition = {
    enable_diagnostic_settings = false
  }
  genai_key_vault_definition = {
    #this is for AVM testing purposes only. Doing this as we don't have an easy for the test runner to be privately connected for testing.
    public_network_access_enabled = true
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
}
