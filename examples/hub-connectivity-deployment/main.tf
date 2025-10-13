# Hub Connectivity Deployment using Azure Verified Modules
# This creates a complete connectivity landing zone with hub infrastructure

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
  }
}

# Provider for Hub Subscription (Connectivity)
provider "azurerm" {
  subscription_id = var.hub_subscription_id
  features {}
}

# Generate unique naming suffix
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Local values for resource naming and tagging
locals {
  resource_names = {
    resource_group = "${var.project_name}-hub-rg-${var.environment}-${random_string.suffix.result}"
    hub_vnet      = "${var.project_name}-hub-vnet-${var.environment}"
  }
  
  merged_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Component   = "Connectivity"
    },
    var.tags
  )
}

# Deploy Azure Landing Zone Connectivity Hub
module "alz_connectivity" {
  source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
  version = "~> 1.0"
  
  location = var.location
  
  # Hub VNet Configuration
  hub_virtual_networks = {
    primary_hub = {
      name                            = local.resource_names.hub_vnet
      resource_group_name             = local.resource_names.resource_group
      resource_group_creation_enabled = true
      location                        = var.location
      address_space                   = [var.hub_vnet_address_space]
      
      # Azure Firewall Configuration
      firewall = {
        sku_name              = var.firewall_sku_name
        sku_tier              = var.firewall_sku_tier
        subnet_address_prefix = var.firewall_subnet_address_prefix
        firewall_policy = {
          name = "${var.project_name}-firewall-policy-${var.environment}"
          sku  = var.firewall_sku_tier
        }
      }
      
      # Subnets for shared services
      subnets = {
        shared-services = {
          name             = "shared-services-subnet"
          address_prefixes = [var.shared_services_subnet_address_prefix]
        }
        gateway-subnet = {
          name             = "GatewaySubnet"
          address_prefixes = [var.gateway_subnet_address_prefix]
        }
      }
    }
  }
  
  # Private DNS Zones for Azure AI/ML services
  dns_zones = var.private_dns_zones
  
  tags = local.merged_tags
}