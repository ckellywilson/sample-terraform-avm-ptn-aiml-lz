terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraform-state-rg-hub"
    storage_account_name = "tfstatehub564063"
    container_name       = "tfstate"
    key                  = "hub.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  subscription_id = "808c8f6e-4a1c-417e-9a77-db2619ce3d1a"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Generate unique suffix for resource names
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  prefix = "hub-${var.location_short}-${random_string.suffix.result}"

  # Common tags for all resources
  common_tags = merge(var.tags, {
    "DeployedBy" = "terraform"
    "Purpose"    = "ai-ml-hub-infrastructure"
  })
}

# Resource group for hub infrastructure
resource "azurerm_resource_group" "hub" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.common_tags
}

# Hub Virtual Network using ALZ AVM
module "hub_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.7.0"

  name                = "vnet-${local.prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = [var.hub_address_space]

  subnets = {
    AzureFirewallSubnet = {
      name             = "AzureFirewallSubnet"
      address_prefixes = [cidrsubnet(var.hub_address_space, 8, 0)]
    }
    GatewaySubnet = {
      name             = "GatewaySubnet"
      address_prefixes = [cidrsubnet(var.hub_address_space, 8, 1)]
    }
    AzureBastionSubnet = {
      name             = "AzureBastionSubnet"
      address_prefixes = [cidrsubnet(var.hub_address_space, 8, 2)]
    }
    SharedServices = {
      name             = "SharedServices"
      address_prefixes = [cidrsubnet(var.hub_address_space, 8, 3)]
    }
    DNSPrivateResolver = {
      name             = "DNSPrivateResolver"
      address_prefixes = [cidrsubnet(var.hub_address_space, 8, 4)]
      delegation = [{
        name = "Microsoft.Network.dnsResolvers"
        service_delegation = {
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
          name    = "Microsoft.Network/dnsResolvers"
        }
      }]
    }
  }

  tags = local.common_tags
}

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "pip-afw-${local.prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = local.common_tags
}

# Firewall Policy
resource "azurerm_firewall_policy" "hub" {
  name                = "afwpol-${local.prefix}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  sku                 = var.firewall_sku

  dns {
    proxy_enabled = true
    servers       = var.custom_dns_servers
  }

  tags = local.common_tags
}

# Firewall Policy Rule Collection Group for AI/ML traffic
resource "azurerm_firewall_policy_rule_collection_group" "ai_ml" {
  name               = "ai-ml-rules"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 500

  application_rule_collection {
    name     = "ai-ml-app-rules"
    priority = 500
    action   = "Allow"

    rule {
      name = "azure-ai-services"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses = [var.ai_ml_address_space]
      destination_fqdns = [
        "*.cognitiveservices.azure.com",
        "*.openai.azure.com",
        "*.search.windows.net",
        "*.blob.core.windows.net",
        "*.vault.azure.net",
        "*.documents.azure.com",
        "*.azure.com",
        "*.microsoft.com",
        "*.windows.net"
      ]
    }

    rule {
      name = "package-managers"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = [var.ai_ml_address_space]
      destination_fqdns = [
        "*.pypi.org",
        "*.pythonhosted.org",
        "*.conda.io",
        "*.anaconda.com",
        "*.ubuntu.com",
        "*.canonical.com"
      ]
    }
  }

  network_rule_collection {
    name     = "ai-ml-network-rules"
    priority = 400
    action   = "Allow"

    rule {
      name                  = "dns"
      protocols             = ["UDP"]
      source_addresses      = [var.ai_ml_address_space]
      destination_addresses = ["168.63.129.16", "169.254.169.254"]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "ntp"
      protocols             = ["UDP"]
      source_addresses      = [var.ai_ml_address_space]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }
}

# Azure Firewall
resource "azurerm_firewall" "hub" {
  name                = "afw-${local.prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku
  firewall_policy_id  = azurerm_firewall_policy.hub.id
  zones               = ["1", "2", "3"]

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.hub_vnet.subnets["AzureFirewallSubnet"].resource_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = local.common_tags
}

# DNS Private Resolver
resource "azurerm_private_dns_resolver" "hub" {
  name                = "dnspr-${local.prefix}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  virtual_network_id  = module.hub_vnet.resource_id

  tags = local.common_tags
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "hub" {
  name                    = "dnspr-in-${local.prefix}"
  private_dns_resolver_id = azurerm_private_dns_resolver.hub.id
  location                = var.location

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = module.hub_vnet.subnets["DNSPrivateResolver"].resource_id
  }

  tags = local.common_tags
}

# Central Private DNS Zones for AI/ML services
resource "azurerm_private_dns_zone" "ai_services" {
  for_each = var.create_private_dns_zones ? toset([
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.queue.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.search.windows.net",
    "privatelink.documents.azure.com",
    "privatelink.cognitiveservices.azure.com",
    "privatelink.api.azureml.ms",
    "privatelink.notebooks.azure.net"
  ]) : toset([])

  name                = each.value
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# Link DNS zones to hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each = azurerm_private_dns_zone.ai_services

  name                  = "hub-link-${replace(each.key, ".", "-")}"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = module.hub_vnet.resource_id
  registration_enabled  = false

  tags = local.common_tags
}

# Log Analytics Workspace for monitoring (optional)
resource "azurerm_log_analytics_workspace" "hub" {
  count               = var.create_log_analytics ? 1 : 0
  name                = "law-${local.prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# Route table for spoke networks (to direct traffic through firewall)
resource "azurerm_route_table" "spoke_routes" {
  name                = "rt-spoke-via-firewall"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name

  route {
    name                   = "InternetViaFirewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }

  tags = local.common_tags
}