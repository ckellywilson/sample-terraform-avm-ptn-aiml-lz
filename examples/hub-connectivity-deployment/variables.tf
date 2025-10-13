# Hub Connectivity Deployment Variables

variable "hub_subscription_id" {
  description = "The subscription ID for the hub/connectivity subscription"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "East US"
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "aiml-lz"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "poc"
}

variable "hub_vnet_address_space" {
  description = "Address space for the hub virtual network"
  type        = string 
  default     = "10.0.0.0/16"
}

variable "firewall_sku_name" {
  description = "Azure Firewall SKU name"
  type        = string
  default     = "AZFW_VNet"
}

variable "firewall_sku_tier" {
  description = "Azure Firewall SKU tier"
  type        = string
  default     = "Standard"
}

variable "firewall_subnet_address_prefix" {
  description = "Address prefix for Azure Firewall subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "shared_services_subnet_address_prefix" {
  description = "Address prefix for shared services subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "gateway_subnet_address_prefix" {
  description = "Address prefix for VPN Gateway subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_dns_zones" {
  description = "List of private DNS zones to create"
  type        = list(string)
  default     = [
    "privatelink.api.azureml.ms",
    "privatelink.notebooks.azure.net",
    "privatelink.file.core.windows.net",
    "privatelink.blob.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.queue.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.cognitiveservices.azure.com",
    "privatelink.openai.azure.com",
    "privatelink.search.windows.net",
    "privatelink.mongo.cosmos.azure.com"
  ]
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}