# DNS Zones for Standalone Deployment
# This file handles the creation of required private DNS zones for standalone deployments
# when existing DNS zones are not provided

# Create DNS zones resource group if not provided
resource "azurerm_resource_group" "dns_zones" {
  count    = var.existing_dns_zones_rg_id == null ? 1 : 0
  name     = "existing-dns-zones-rg"
  location = var.location
  
  tags = {
    Purpose = "Private DNS Zones for AI/ML Landing Zone"
    CreatedBy = "Terraform"
    DeploymentType = "standalone"
  }
}

# Required private DNS zones for AI/ML services in standalone deployment
locals {
  required_dns_zones = {
    "privatelink.vaultcore.azure.net"           = "Azure Key Vault"
    "privatelink.blob.core.windows.net"         = "Azure Storage Blob"
    "privatelink.documents.azure.com"           = "Azure Cosmos DB"
    "privatelink.cognitiveservices.azure.com"   = "Azure Cognitive Services"
    "privatelink.openai.azure.com"              = "Azure OpenAI"
    "privatelink.services.ai.azure.com"         = "Azure AI Services"
    "privatelink.azurecr.io"                    = "Azure Container Registry"
    "privatelink.azure-api.net"                 = "Azure API Management"
    "privatelink.azconfig.io"                   = "Azure App Configuration"
    "privatelink.search.windows.net"            = "Azure AI Search"
    "privatelink.api.azureml.ms"                = "Azure Machine Learning"
    "privatelink.notebooks.azure.net"           = "Azure ML Notebooks"
  }
}

# Create required DNS zones for standalone deployment
resource "azurerm_private_dns_zone" "required_zones" {
  for_each = var.existing_dns_zones_rg_id == null ? local.required_dns_zones : {}

  name                = each.key
  resource_group_name = azurerm_resource_group.dns_zones[0].name

  tags = {
    Purpose = each.value
    CreatedBy = "Terraform"
    DeploymentType = "standalone"
  }

  depends_on = [azurerm_resource_group.dns_zones]
}

# Output the DNS zones resource group ID for reference
output "dns_zones_resource_group_id" {
  description = "Resource group ID containing the private DNS zones"
  value = var.existing_dns_zones_rg_id != null ? var.existing_dns_zones_rg_id : azurerm_resource_group.dns_zones[0].id
}