# AI/ML Landing Zone Module

This module creates an Azure AI/ML Landing Zone based on the Azure Verified Module pattern.

## Features

- AI Foundry hub with project management
- Azure OpenAI model deployments
- Supporting services (Container Registry, Cosmos DB, Key Vault, Storage Account, AI Search)
- Network infrastructure with hub-spoke topology
- Environment-specific configurations

## Usage

```hcl
module "ai_ml_landing_zone" {
  source = "./modules/ai-ml-landing-zone"
  
  environment         = "dev"
  project_name        = "aiml-lz"
  location           = "East US 2"
  vnet_address_space = "10.0.0.0/16"
  hub_address_space  = "10.1.0.0/24"
  
  enable_diagnostic_logs = false
  purge_on_destroy      = true
  sku_tier              = "Basic"
}
```

## Requirements

- Terraform >= 1.9
- AzureRM Provider ~> 4.21
- HTTP Provider ~> 3.4
- Random Provider ~> 3.5
