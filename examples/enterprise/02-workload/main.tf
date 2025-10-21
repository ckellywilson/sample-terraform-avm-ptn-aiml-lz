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

# Get the deployer IP address for testing purposes
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

# AI/ML Landing Zone workload deployment
module "aiml_workload" {
  source  = "Azure/avm-ptn-aiml-landing-zone/azurerm"
  version = "~> 0.1"

  location            = var.location
  resource_group_name = var.workload_resource_group_name != "" ? var.workload_resource_group_name : "rg-aiml-enterprise-${substr(module.naming.unique-seed, 0, 5)}"
  
  # Spoke virtual network configuration that connects to platform hub
  vnet_definition = {
    name          = var.spoke_vnet_name
    address_space = var.spoke_address_space
    dns_servers   = [for key, value in local.hub_info.dns_resolver_inbound_ip_addresses : value]
    
    # Connect to platform-managed hub
    hub_vnet_peering_definition = {
      peer_vnet_resource_id = local.hub_info.virtual_network_resource_id
      firewall_ip_address   = local.hub_info.firewall_ip_address
    }
  }
  
  # AI Foundry configuration for enterprise deployment
  ai_foundry_definition = {
    purge_on_destroy = var.purge_on_destroy
    ai_foundry = {
      create_ai_agent_service = true
    }
    ai_model_deployments = var.ai_model_deployments
    ai_projects          = var.ai_projects
    ai_search_definition = var.ai_search_definition
    cosmosdb_definition  = var.cosmosdb_definition
    key_vault_definition = var.key_vault_definition
    storage_account_definition = var.storage_account_definition
  }
  
  # Application Gateway configuration
  app_gateway_definition = var.app_gateway_definition
  
  # No bastion deployment - use platform-provided bastion
  bastion_definition = {}
  
  # Container App Environment configuration
  container_app_environment_definition = var.container_app_environment_definition
  
  # Enterprise deployment settings
  enable_telemetry            = var.enable_telemetry
  flag_platform_landing_zone = true  # Key difference - this is an enterprise deployment
  
  # GenAI service configurations
  genai_container_registry_definition = var.genai_container_registry_definition
  genai_cosmosdb_definition = var.genai_cosmosdb_definition
  genai_key_vault_definition = {
    public_network_access_enabled = var.genai_key_vault_definition.public_network_access_enabled
    network_acls = {
      bypass   = var.genai_key_vault_definition.network_acls.bypass
      ip_rules = concat(var.genai_key_vault_definition.network_acls.ip_rules, ["${data.http.ip.response_body}/32"])
    }
  }
  genai_storage_account_definition = var.genai_storage_account_definition
  ks_ai_search_definition = var.ks_ai_search_definition
  
  # Reference platform-managed private DNS zones
  private_dns_zones = {
    existing_zones_resource_group_resource_id = local.hub_info.resource_group_resource_id
  }
}

locals {
  # Hub information from platform deployment
  # This supports both remote state and direct data source approaches
  hub_info = var.use_remote_state ? data.terraform_remote_state.platform[0].outputs.hub_network_info : {
    virtual_network_resource_id       = data.azurerm_virtual_network.hub[0].id
    virtual_network_name              = data.azurerm_virtual_network.hub[0].name
    firewall_ip_address              = var.hub_firewall_ip_address
    dns_resolver_inbound_ip_addresses = var.hub_dns_resolver_ips
    resource_group_resource_id       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.hub_resource_group_name}"
    resource_group_name              = var.hub_resource_group_name
  }
}