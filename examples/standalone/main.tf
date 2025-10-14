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

# Resource Group for standalone AI/ML Landing Zone
resource "azurerm_resource_group" "ai_ml" {
  name     = "${local.prefix}-ai-ml-rg"
  location = var.location
  tags     = var.tags
}

# AI/ML Landing Zone Virtual Network (standalone - no hub)
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

resource "azurerm_subnet" "ai_ml_web" {
  name                 = "web"
  resource_group_name  = azurerm_resource_group.ai_ml.name
  virtual_network_name = azurerm_virtual_network.ai_ml.name
  address_prefixes     = [cidrsubnet(var.ai_lz_vnet_address_space, 3, 2)]
}

# Network Security Group for compute subnet
resource "azurerm_network_security_group" "ai_ml_compute" {
  name                = "${local.prefix}-compute-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_ml.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associate NSG with compute subnet
resource "azurerm_subnet_network_security_group_association" "ai_ml_compute" {
  subnet_id                 = azurerm_subnet.ai_ml_compute.id
  network_security_group_id = azurerm_network_security_group.ai_ml_compute.id
}

# Storage Account for AI Foundry
resource "azurerm_storage_account" "ai_foundry" {
  name                     = "${replace(local.prefix, "-", "")}aistorage"
  resource_group_name      = azurerm_resource_group.ai_ml.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Enable public access for standalone deployment
  public_network_access_enabled = true
  
  tags = var.tags
}

# Key Vault for AI Foundry
resource "azurerm_key_vault" "ai_foundry" {
  name                = "${local.prefix}-ai-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_ml.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  sku_name = "standard"
  
  # Enable public access for standalone deployment
  public_network_access_enabled = true
  
  # Access policy for current user
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
    ]
  }
  
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
  
  # Enable public access for standalone deployment
  public_network_access_enabled = true
  
  tags = var.tags
}

# AI Search Service
resource "azurerm_search_service" "ai_foundry" {
  name                = "${local.prefix}-ai-search"
  resource_group_name = azurerm_resource_group.ai_ml.name
  location            = var.location
  sku                 = "standard"
  
  # Enable public access for standalone deployment
  public_network_access_enabled = true
  
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
  
  # Enable public access for standalone deployment
  public_network_access_enabled = true
  
  tags = var.tags
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "ai_foundry" {
  name                = "${local.prefix}-ai-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_ml.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = var.tags
}