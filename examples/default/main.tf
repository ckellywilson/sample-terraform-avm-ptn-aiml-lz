terraform {
  required_version = ">= 1.9, < 2.0"

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

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

data "azurerm_client_config" "current" {}

# Generate unique suffix for resource names
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  prefix = "${var.name_prefix}-${random_string.suffix.result}"
}

# Resource Group for Hub Landing Zone
resource "azurerm_resource_group" "hub" {
  name     = "${local.prefix}-hub-rg"
  location = var.location
  tags     = var.tags
}

# Example Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = "${local.prefix}-hub-vnet"
  address_space       = [var.hub_vnet_address_space]
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

# Hub Subnet for shared services
resource "azurerm_subnet" "hub_default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_vnet_address_space, 2, 0)]
}

# Resource Group for AI/ML Landing Zone
resource "azurerm_resource_group" "ai_ml" {
  name     = "${local.prefix}-ai-ml-rg"
  location = var.location
  tags     = var.tags
}

# AI/ML Landing Zone Virtual Network
resource "azurerm_virtual_network" "ai_ml" {
  name                = "${local.prefix}-ai-ml-vnet"
  address_space       = [var.ai_lz_vnet_address_space]
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_ml.name
  tags                = var.tags
}

# AI/ML Landing Zone Subnets
resource "azurerm_subnet" "ai_ml_private_endpoints" {
  name                 = "private-endpoints"
  resource_group_name  = azurerm_resource_group.ai_ml.name
  virtual_network_name = azurerm_virtual_network.ai_ml.name
  address_prefixes     = [cidrsubnet(var.ai_lz_vnet_address_space, 3, 0)]
}

resource "azurerm_subnet" "ai_ml_compute" {
  name                 = "compute"
  resource_group_name  = azurerm_resource_group.ai_ml.name
  virtual_network_name = azurerm_virtual_network.ai_ml.name
  address_prefixes     = [cidrsubnet(var.ai_lz_vnet_address_space, 3, 1)]
}

# VNet Peering from AI/ML to Hub
resource "azurerm_virtual_network_peering" "ai_ml_to_hub" {
  name                      = "ai-ml-to-hub"
  resource_group_name       = azurerm_resource_group.ai_ml.name
  virtual_network_name      = azurerm_virtual_network.ai_ml.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways         = false
}

# VNet Peering from Hub to AI/ML
resource "azurerm_virtual_network_peering" "hub_to_ai_ml" {
  name                      = "hub-to-ai-ml"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.ai_ml.id
  
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways         = false
}

# Storage Account for AI Foundry
resource "azurerm_storage_account" "ai_foundry" {
  name                     = "${replace(local.prefix, "-", "")}aistorage"
  resource_group_name      = azurerm_resource_group.ai_ml.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  public_network_access_enabled = false
  
  tags = var.tags
}

# Key Vault for AI Foundry
resource "azurerm_key_vault" "ai_foundry" {
  name                = "${local.prefix}-ai-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_ml.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  sku_name = "standard"
  
  public_network_access_enabled = false
  
  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "ai_foundry" {
  name                = "${local.prefix}-ai-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_ml.name
  application_type    = "web"
  
  tags = var.tags
}

# Cognitive Services Account for AI Foundry
resource "azurerm_cognitive_account" "ai_foundry" {
  name                = "${local.prefix}-ai-cognitive"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_ml.name
  kind                = "AIServices"
  sku_name            = "S0"
  
  public_network_access_enabled = false
  
  tags = var.tags
}

# AI Search Service
resource "azurerm_search_service" "ai_foundry" {
  name                = "${local.prefix}-ai-search"
  resource_group_name = azurerm_resource_group.ai_ml.name
  location            = var.location
  sku                 = "standard"
  
  public_network_access_enabled = false
  
  tags = var.tags
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "ai_foundry" {
  name                = "${local.prefix}-ai-cosmos"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_ml.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  
  consistency_policy {
    consistency_level = "Session"
  }
  
  geo_location {
    location          = var.location
    failover_priority = 0
  }
  
  public_network_access_enabled = false
  
  tags = var.tags
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.ai_ml.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.ai_ml.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.ai_ml.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.ai_ml.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "cognitive" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.ai_ml.name
  tags                = var.tags
}

# Link Private DNS Zones to both VNets
resource "azurerm_private_dns_zone_virtual_network_link" "blob_ai_ml" {
  name                  = "blob-ai-ml-link"
  resource_group_name   = azurerm_resource_group.ai_ml.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.ai_ml.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_hub" {
  name                  = "blob-hub-link"
  resource_group_name   = azurerm_resource_group.ai_ml.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  tags                  = var.tags
}

# Private Endpoints
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "${local.prefix}-storage-blob-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_ml.name
  subnet_id           = azurerm_subnet.ai_ml_private_endpoints.id
  
  private_service_connection {
    name                           = "storage-blob-psc"
    private_connection_resource_id = azurerm_storage_account.ai_foundry.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  
  private_dns_zone_group {
    name                 = "storage-blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
  
  tags = var.tags
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "${local.prefix}-keyvault-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_ml.name
  subnet_id           = azurerm_subnet.ai_ml_private_endpoints.id
  
  private_service_connection {
    name                           = "keyvault-psc"
    private_connection_resource_id = azurerm_key_vault.ai_foundry.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
  
  private_dns_zone_group {
    name                 = "keyvault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.vault.id]
  }
  
  tags = var.tags
}