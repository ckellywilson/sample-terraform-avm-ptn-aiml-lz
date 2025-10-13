# Cross-Subscription Hub-Spoke Configuration for Azure AI Foundry
# This configuration deploys AI Foundry in a spoke subscription while using
# shared Private DNS Zones from a hub subscription

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

# Provider for Hub Subscription (Connectivity)
provider "azurerm" {
  alias           = "hub"
  subscription_id = var.hub_subscription_id
  features {}
}

# Provider for Spoke Subscription (Application)
provider "azurerm" {
  alias           = "spoke"
  subscription_id = var.spoke_subscription_id
  features {}
}

# Default provider (uses spoke subscription)
provider "azurerm" {
  subscription_id = var.spoke_subscription_id
  features {}
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

# Generate unique naming suffix
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Data sources for existing hub resources
data "azurerm_virtual_network" "hub_vnet" {
  provider            = azurerm.hub
  name                = split("/", var.hub_vnet_id)[8]
  resource_group_name = split("/", var.hub_vnet_id)[4]
}

data "azurerm_resource_group" "hub_dns_rg" {
  provider = azurerm.hub
  name     = var.hub_resource_group_name
}

# Local values for resource naming and configuration
locals {
  resource_names = {
    resource_group = "${var.project_name}-rg-${var.environment}-${random_string.suffix.result}"
    vnet          = "${var.project_name}-spoke-vnet-${var.environment}"
    ai_foundry    = "${var.project_name}-aif-${var.environment}-${random_string.suffix.result}"
  }
  
  merged_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# Resource Group for AI Foundry (Spoke Subscription)
resource "azurerm_resource_group" "spoke_rg" {
  name     = local.resource_names.resource_group
  location = var.location
  tags     = local.merged_tags
}

# Spoke Virtual Network
resource "azurerm_virtual_network" "spoke_vnet" {
  name                = local.resource_names.vnet
  address_space       = [var.spoke_vnet_address_space]
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  
  # Use hub DNS servers for proper name resolution
  dns_servers = length(data.azurerm_virtual_network.hub_vnet.dns_servers) > 0 ? [data.azurerm_virtual_network.hub_vnet.dns_servers[0]] : null
  
  tags = local.merged_tags
}

# Subnet for Private Endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                 = "private-endpoints-subnet"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = [var.private_endpoints_subnet_address_prefix]
}

# VNet Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                = "${local.resource_names.vnet}-to-hub-peering"
  resource_group_name = azurerm_resource_group.spoke_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id = var.hub_vnet_id
  
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true  # Assuming hub has gateway
}

# VNet Peering: Hub to Spoke (requires hub subscription access)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider            = azurerm.hub
  name                = "hub-to-${local.resource_names.vnet}-peering"
  resource_group_name = data.azurerm_virtual_network.hub_vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet.id
  
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

# Link spoke VNet to hub private DNS zones
resource "azurerm_private_dns_zone_virtual_network_link" "spoke_dns_links" {
  provider = azurerm.hub
  for_each = var.hub_private_dns_zones
  
  name                  = "${local.resource_names.vnet}-link"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = each.key
  virtual_network_id    = azurerm_virtual_network.spoke_vnet.id
  registration_enabled  = false
  
  tags = local.merged_tags
}

# Deploy AI/ML Landing Zone with cross-subscription DNS integration
module "ai_ml_landing_zone" {
  source  = "Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/azurerm"
  version = "~> 1.0"
  
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  
  # Use existing spoke VNet instead of creating new one
  vnet_definition = {
    name          = azurerm_virtual_network.spoke_vnet.name
    address_space = azurerm_virtual_network.spoke_vnet.address_space[0]
    resource_id   = azurerm_virtual_network.spoke_vnet.id
  }
  
  # AI Foundry Configuration
  ai_foundry_definition = {
    purge_on_destroy = var.environment == "dev" ? true : false
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
        name                       = "ai-project-1"
        description                = "Cross-subscription AI project"
        display_name               = "AI Project 1"
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
  
  # Private DNS Zones Configuration - Use existing hub zones
  private_dns_zones = {
    existing_zones_resource_group_resource_id = data.azurerm_resource_group.hub_dns_rg.id
  }
  
  # Flag to indicate we're using existing platform landing zone
  flag_platform_landing_zone = true
  
  # Disable creation of new networking components since we're using existing hub
  create_resource_group = false
  
  tags = local.merged_tags
  
  depends_on = [
    azurerm_virtual_network_peering.spoke_to_hub,
    azurerm_virtual_network_peering.hub_to_spoke,
    azurerm_private_dns_zone_virtual_network_link.spoke_dns_links
  ]
}