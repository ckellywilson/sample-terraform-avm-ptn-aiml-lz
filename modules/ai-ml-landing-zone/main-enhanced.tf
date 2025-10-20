# Enhanced AI/ML Landing Zone Module - Multi-Pattern Support
# Supports: hub-spoke (same subscription), cross-subscription, and standalone patterns

# Get current IP address for firewall rules
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

# Generate unique naming suffix
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Local values for resource naming and configuration
locals {
  environment_config = {
    location               = var.location
    vnet_address_space     = var.vnet_address_space
    hub_address_space      = var.hub_address_space
    enable_diagnostic_logs = var.enable_diagnostic_logs
    purge_on_destroy       = var.purge_on_destroy
    sku_tier               = var.sku_tier
  }

  resource_names = {
    resource_group = "${var.project_name}-rg-${var.environment}-${random_string.suffix.result}"
    vnet           = "${var.project_name}-vnet-${var.environment}"
    hub_vnet       = "${var.project_name}-hub-vnet-${var.environment}"
  }

  merged_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Pattern     = var.deployment_pattern
    },
    var.tags
  )

  # Determine if we need to create a hub or use existing one
  create_hub       = var.deployment_pattern == "hub-spoke" && var.existing_hub_config.hub_vnet_id == null
  use_existing_hub = var.deployment_pattern == "hub-spoke" && var.existing_hub_config.hub_vnet_id != null
  standalone_mode  = var.deployment_pattern == "standalone"
}

# Example Hub Module for network foundation (only in hub-spoke mode without existing hub)
module "example_hub" {
  count   = local.create_hub ? 1 : 0
  source  = "Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/azurerm//modules/example_hub_vnet"
  version = "~> 1.0"

  deployer_ip_address = "${data.http.ip.response_body}/32"
  location            = local.environment_config.location
  resource_group_name = "${local.resource_names.resource_group}-hub"

  vnet_definition = {
    address_space = local.environment_config.hub_address_space
  }

  enable_telemetry = var.enable_telemetry
  name_prefix      = "${var.project_name}-${var.environment}-hub"
  tags             = local.merged_tags
}

# Data sources for existing hub resources (cross-subscription scenario)
data "azurerm_virtual_network" "existing_hub" {
  count               = local.use_existing_hub ? 1 : 0
  name                = split("/", var.existing_hub_config.hub_vnet_id)[8]
  resource_group_name = split("/", var.existing_hub_config.hub_vnet_id)[4]
}

# Main AI/ML Landing Zone Module
module "ai_ml_landing_zone" {
  source  = "Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/azurerm"
  version = "~> 1.0"

  location            = local.environment_config.location
  resource_group_name = local.resource_names.resource_group

  # VNet definition varies by pattern
  vnet_definition = local.standalone_mode ? {
    name          = local.resource_names.vnet
    address_space = local.environment_config.vnet_address_space
    } : local.use_existing_hub ? {
    name          = local.resource_names.vnet
    address_space = local.environment_config.vnet_address_space
    dns_servers   = var.existing_hub_config.hub_dns_servers

    hub_vnet_peering_definition = {
      peer_vnet_resource_id = var.existing_hub_config.hub_vnet_id
      firewall_ip_address   = var.existing_hub_config.hub_firewall_ip
    }
    } : {
    # Default hub-spoke with created hub
    name          = local.resource_names.vnet
    address_space = local.environment_config.vnet_address_space
    dns_servers   = local.create_hub ? [for key, value in module.example_hub[0].dns_resolver_inbound_ip_addresses : value] : []

    hub_vnet_peering_definition = local.create_hub ? {
      peer_vnet_resource_id = module.example_hub[0].virtual_network_resource_id
      firewall_ip_address   = module.example_hub[0].firewall_ip_address
    } : null
  }

  # AI Foundry Configuration
  ai_foundry_definition = {
    purge_on_destroy = var.purge_on_destroy
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
        enable_diagnostic_settings = var.enable_diagnostic_logs
      }
    }
    cosmosdb_definition = {
      this = {
        enable_diagnostic_settings = var.enable_diagnostic_logs
        consistency_level          = "Session"
      }
    }
    key_vault_definition = {
      this = {
        enable_diagnostic_settings = var.enable_diagnostic_logs
      }
    }
    storage_account_definition = {
      this = {
        enable_diagnostic_settings      = var.enable_diagnostic_logs
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

  # Application Gateway Configuration (only for production)
  app_gateway_definition = var.environment == "prod" ? {
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
  } : null

  # Supporting Services
  genai_container_registry_definition = {
    enable_diagnostic_settings = var.enable_diagnostic_logs
  }

  genai_cosmosdb_definition = {
    enable_diagnostic_settings = var.enable_diagnostic_logs
    consistency_level          = "Session"
  }

  genai_key_vault_definition = {
    public_network_access_enabled = var.environment == "dev" ? true : false
    network_acls = var.environment == "dev" ? {
      bypass   = "AzureServices"
      ip_rules = ["${data.http.ip.response_body}/32"]
    } : null
  }

  genai_storage_account_definition = {
    enable_diagnostic_settings      = var.enable_diagnostic_logs
    shared_access_key_enabled       = false # Disable shared key access for security compliance
    default_to_oauth_authentication = true  # Force OAuth authentication for all operations
  }

  ks_ai_search_definition = {
    enable_diagnostic_settings = var.enable_diagnostic_logs
  }

  # Private DNS Zones configuration varies by pattern
  private_dns_zones = local.standalone_mode ? {} : local.use_existing_hub ? {
    existing_zones_resource_group_resource_id = var.existing_hub_config.hub_dns_zones_resource_group
    } : local.create_hub ? {
    existing_zones_resource_group_resource_id = module.example_hub[0].resource_group_resource_id
  } : {}

  # Platform landing zone flag
  flag_platform_landing_zone = !local.standalone_mode
  enable_telemetry           = var.enable_telemetry
  tags                       = local.merged_tags

  depends_on = [module.example_hub]
}