# Cross-Subscription Hub-Spoke Variables for Azure AI Foundry

# Hub Subscription Configuration
variable "hub_subscription_id" {
  type        = string
  description = "Subscription ID where hub networking resources are deployed"
}

variable "hub_resource_group_name" {
  type        = string
  description = "Resource group name in hub subscription containing private DNS zones"
}

variable "hub_vnet_id" {
  type        = string
  description = "Resource ID of the hub virtual network"
}

variable "hub_private_dns_zones" {
  type = map(string)
  description = "Map of private DNS zones in hub subscription"
  default = {
    "privatelink.api.azureml.ms"                     = ""
    "privatelink.cert.api.azureml.ms"                = ""
    "privatelink.notebooks.azure.net"               = ""
    "privatelink.instances.azureml.ms"               = ""
    "privatelink.inference.ml.azure.com"            = ""
    "privatelink.services.ai.azure.com"             = ""
    "privatelink.cognitiveservices.azure.com"       = ""
    "privatelink.openai.azure.com"                  = ""
    "privatelink.blob.core.windows.net"             = ""
    "privatelink.file.core.windows.net"             = ""
    "privatelink.queue.core.windows.net"            = ""
    "privatelink.table.core.windows.net"            = ""
    "privatelink.vaultcore.azure.net"               = ""
    "privatelink.azurecr.io"                        = ""
    "privatelink.documents.azure.com"               = ""
    "privatelink.search.windows.net"                = ""
  }
}

# Spoke Subscription Configuration (AI Foundry)
variable "spoke_subscription_id" {
  type        = string
  description = "Subscription ID where AI Foundry resources will be deployed"
}

variable "spoke_resource_group_name" {
  type        = string
  description = "Resource group name in spoke subscription for AI Foundry resources"
}

variable "spoke_vnet_address_space" {
  type        = string
  description = "Address space for the spoke VNet containing AI Foundry"
  default     = "10.100.0.0/16"
}

variable "private_endpoints_subnet_address_prefix" {
  type        = string
  description = "Address prefix for private endpoints subnet"
  default     = "10.100.1.0/24"
}

# Common Configuration
variable "location" {
  type        = string
  description = "Azure region for deployment"
  default     = "East US 2"
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "aiml-hub-spoke"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default = {
    Architecture = "Hub-Spoke"
    Pattern      = "Cross-Subscription"
    Workload     = "AI-ML"
  }
}