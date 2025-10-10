#!/bin/bash

# Azure AI/ML Landing Zone - Folder Structure Builder
# This script creates the folder structure as defined in PROMPT.md

echo "Creating Azure AI/ML Landing Zone folder structure..."

# Create main directories
mkdir -p modules/ai-ml-landing-zone
mkdir -p environments/{dev,staging,prod}
mkdir -p shared
mkdir -p .github/workflows
mkdir -p scripts

echo "✅ Created main directory structure"

# Create module files
echo "Creating module files..."

# modules/ai-ml-landing-zone/terraform.tf
cat > modules/ai-ml-landing-zone/terraform.tf << 'EOF'
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
EOF

# modules/ai-ml-landing-zone/variables.tf
cat > modules/ai-ml-landing-zone/variables.tf << 'EOF'
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  
  validation {
    condition = contains(["dev", "staging", "prod", "development", "stage", "uat", "pre-prod", "integration", "production", "live", "main", "sandbox", "test"], var.environment)
    error_message = "Environment must be one of the supported values."
  }
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
  default     = "aiml-lz"
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment"
}

variable "vnet_address_space" {
  type        = string
  description = "Address space for the AI/ML Landing Zone VNet"
}

variable "hub_address_space" {
  type        = string
  description = "Address space for the Hub VNet"
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "enable_diagnostic_logs" {
  type        = bool
  description = "Enable diagnostic logging for resources"
}

variable "purge_on_destroy" {
  type        = bool
  description = "Whether to purge soft-delete capable resources on destroy"
  default     = false
}

variable "sku_tier" {
  type        = string
  description = "SKU tier for resources (Basic, Standard, Premium)"
  default     = "Standard"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to resources"
  default     = {}
}
EOF

# modules/ai-ml-landing-zone/main.tf
cat > modules/ai-ml-landing-zone/main.tf << 'EOF'
# Get current IP address for firewall rules
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

# Local values for resource naming and configuration
locals {
  environment_config = {
    location                = var.location
    vnet_address_space     = var.vnet_address_space
    hub_address_space      = var.hub_address_space
    enable_diagnostic_logs = var.enable_diagnostic_logs
    purge_on_destroy      = var.purge_on_destroy
    sku_tier               = var.sku_tier
  }
  
  resource_names = {
    resource_group = "${var.project_name}-rg-${var.environment}-${random_string.suffix.result}"
    vnet          = "${var.project_name}-vnet-${var.environment}"
    hub_vnet      = "${var.project_name}-hub-vnet-${var.environment}"
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

# Example Hub Module for network foundation
module "example_hub" {
  source  = "Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/azurerm//modules/example_hub_vnet"
  version = "~> 1.0"  # Use appropriate version
  
  deployer_ip_address = "${data.http.ip.response_body}/32"
  location            = local.environment_config.location
  resource_group_name = "${local.resource_names.resource_group}-hub"
  
  vnet_definition = {
    address_space = local.environment_config.hub_address_space
  }
  
  enable_telemetry = var.enable_telemetry
  name_prefix      = "${var.project_name}-${var.environment}-hub"
  tags             = local.merged_tags
}

# Main AI/ML Landing Zone Module
module "ai_ml_landing_zone" {
  source  = "Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/azurerm"
  version = "~> 1.0"  # Use appropriate version
  
  location            = local.environment_config.location
  resource_group_name = local.resource_names.resource_group
  
  vnet_definition = {
    name          = local.resource_names.vnet
    address_space = local.environment_config.vnet_address_space
    dns_servers   = [for key, value in module.example_hub.dns_resolver_inbound_ip_addresses : value]
    
    hub_vnet_peering_definition = {
      peer_vnet_resource_id = module.example_hub.virtual_network_resource_id
      firewall_ip_address   = module.example_hub.firewall_ip_address
    }
  }
  
  # AI Foundry Configuration
  ai_foundry_definition = {
    purge_on_destroy = var.purge_on_destroy
    ai_foundry = {
      create_ai_agent_service = true
    }
    ai_model_deployments = {
      "gpt-4o" = {
        name = "gpt-4.1"
        model = {
          format  = "OpenAI"
          name    = "gpt-4.1"
          version = "2025-04-14"
        }
        scale = {
          type     = "GlobalStandard"
          capacity = 1
        }
      }
    }
    ai_projects = {
      project_1 = {
        name                       = "project-1"
        description                = "Project 1 description"
        display_name               = "Project 1 Display Name"
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
    ai_search_definition = {
      this = {
        enable_diagnostic_settings = var.enable_diagnostic_logs
      }
    }
    cosmosdb_definition = {
      this = {
        enable_diagnostic_settings = var.enable_diagnostic_logs
        consistency_level          = "Session"
      }
    }
    key_vault_definition = {
      this = {
        enable_diagnostic_settings = var.enable_diagnostic_logs
      }
    }
    storage_account_definition = {
      this = {
        enable_diagnostic_settings = var.enable_diagnostic_logs
        shared_access_key_enabled  = var.environment == "dev" ? true : false
        endpoints = {
          blob = {
            type = "blob"
          }
        }
      }
    }
  }
  
  # Application Gateway Configuration
  app_gateway_definition = var.environment == "prod" ? {
    backend_address_pools = {
      example_pool = {
        name = "example-backend-pool"
      }
    }
    backend_http_settings = {
      example_http_settings = {
        name     = "example-http-settings"
        port     = 80
        protocol = "Http"
      }
    }
    frontend_ports = {
      example_frontend_port = {
        name = "example-frontend-port"
        port = 80
      }
    }
    http_listeners = {
      example_listener = {
        name               = "example-listener"
        frontend_port_name = "example-frontend-port"
      }
    }
    request_routing_rules = {
      example_rule = {
        name                       = "example-rule"
        rule_type                  = "Basic"
        http_listener_name         = "example-listener"
        backend_address_pool_name  = "example-backend-pool"
        backend_http_settings_name = "example-http-settings"
        priority                   = 100
      }
    }
  } : null
  
  # Supporting Services
  genai_container_registry_definition = {
    enable_diagnostic_settings = var.enable_diagnostic_logs
  }
  
  genai_cosmosdb_definition = {
    enable_diagnostic_settings = var.enable_diagnostic_logs
    consistency_level          = "Session"
  }
  
  genai_key_vault_definition = {
    public_network_access_enabled = var.environment == "dev" ? true : false
    network_acls = var.environment == "dev" ? {
      bypass   = "AzureServices"
      ip_rules = ["${data.http.ip.response_body}/32"]
    } : null
  }
  
  genai_storage_account_definition = {
    enable_diagnostic_settings = var.enable_diagnostic_logs
  }
  
  ks_ai_search_definition = {
    enable_diagnostic_settings = var.enable_diagnostic_logs
  }
  
  # Private DNS Zones
  private_dns_zones = {
    existing_zones_resource_group_resource_id = module.example_hub.resource_group_resource_id
  }
  
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = false  # Default example doesn't use existing hub
  tags                       = local.merged_tags
  
  depends_on = [module.example_hub]
}
EOF

# modules/ai-ml-landing-zone/outputs.tf
cat > modules/ai-ml-landing-zone/outputs.tf << 'EOF'
output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_names.resource_group
}

output "vnet_id" {
  description = "ID of the AI/ML Landing Zone VNet"
  value       = module.ai_ml_landing_zone.resource_id
}

output "hub_vnet_id" {
  description = "ID of the Hub VNet"
  value       = module.example_hub.virtual_network_resource_id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
EOF

# modules/ai-ml-landing-zone/README.md
cat > modules/ai-ml-landing-zone/README.md << 'EOF'
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
EOF

echo "✅ Created module files"

# Create environment files
for env in dev staging prod; do
    echo "Creating $env environment files..."
    
    # Environment-specific configurations
    case $env in
        "dev")
            location="East US 2"
            vnet_space="10.0.0.0/16"
            hub_space="10.1.0.0/24"
            sku_tier="Basic"
            diagnostic_logs="false"
            purge_destroy="true"
            cost_center="Engineering"
            owner="DevOps Team"
            ;;
        "staging")
            location="Central US"
            vnet_space="10.10.0.0/16"
            hub_space="10.11.0.0/24"
            sku_tier="Standard"
            diagnostic_logs="true"
            purge_destroy="false"
            cost_center="Engineering"
            owner="QA Team"
            ;;
        "prod")
            location="West US 2"
            vnet_space="10.20.0.0/16"
            hub_space="10.21.0.0/24"
            sku_tier="Premium"
            diagnostic_logs="true"
            purge_destroy="false"
            cost_center="Business"
            owner="Platform Team"
            ;;
    esac
    
    # terraform.tf
    cat > environments/$env/terraform.tf << EOF
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
  
  backend "azurerm" {
    # Configure backend for $env environment
    resource_group_name  = "terraform-state-rg-$env"
    storage_account_name = "tfstate${env}XXXXXX"  # Replace with actual storage account
    container_name       = "tfstate"
    key                  = "$env/aiml-lz.tfstate"
  }
}

provider "azurerm" {
  features {}
}
EOF

    # main.tf
    cat > environments/$env/main.tf << EOF
module "ai_ml_landing_zone" {
  source = "../../modules/ai-ml-landing-zone"
  
  environment         = "$env"
  project_name        = "aiml-lz"
  location           = "$location"
  vnet_address_space = "$vnet_space"
  hub_address_space  = "$hub_space"
  
  enable_diagnostic_logs = $diagnostic_logs
  purge_on_destroy      = $purge_destroy
  sku_tier              = "$sku_tier"
  
  tags = {
    Environment = "${env^}"
    CostCenter  = "$cost_center"
    Owner       = "$owner"
  }
}
EOF

    # variables.tf
    cat > environments/$env/variables.tf << 'EOF'
# Environment-specific variable overrides
variable "ai_model_capacity" {
  type        = number
  description = "Capacity for AI model deployments"
  default     = 1
}

variable "enable_advanced_features" {
  type        = bool
  description = "Enable advanced features"
  default     = false
}
EOF

    # terraform.tfvars
    cat > environments/$env/terraform.tfvars << EOF
# $env environment specific values
ai_model_capacity = 1
enable_advanced_features = false

# Override default project settings for $env
project_specific_settings = {
  enable_monitoring = $diagnostic_logs
  backup_retention_days = $([ "$env" = "dev" ] && echo "7" || echo "30")
  auto_scaling_enabled = $([ "$env" = "prod" ] && echo "true" || echo "false")
}
EOF

    # README.md
    cat > environments/$env/README.md << EOF
# ${env^} Environment

This directory contains the Terraform configuration for the ${env^} environment of the Azure AI/ML Landing Zone.

## Configuration

- **Location**: $location
- **VNet Address Space**: $vnet_space
- **Hub Address Space**: $hub_space
- **SKU Tier**: $sku_tier
- **Diagnostic Logs**: $diagnostic_logs
- **Purge on Destroy**: $purge_destroy

## Usage

\`\`\`bash
cd environments/$env
terraform init
terraform plan
terraform apply
\`\`\`

## Backend Configuration

Update the storage account name in \`terraform.tf\` before running \`terraform init\`.
EOF

done

echo "✅ Created environment files"

# Create shared files
cat > shared/locals.tf << 'EOF'
# Shared locals across all environments
locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = "AI-ML-Landing-Zone"
    ManagedBy   = "Terraform"
    Repository  = "sample-default-terraform-avm-ptn-aiml-lz"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Environment-specific configurations
  environment_configs = {
    dev = {
      location                = "East US 2"
      vnet_address_space     = "10.0.0.0/16"
      hub_address_space      = "10.1.0.0/24"
      sku_tier               = "Basic"
      enable_diagnostic_logs = false
      purge_on_destroy      = true
    }
    staging = {
      location                = "Central US"
      vnet_address_space     = "10.10.0.0/16"
      hub_address_space      = "10.11.0.0/24"
      sku_tier               = "Standard"
      enable_diagnostic_logs = true
      purge_on_destroy      = false
    }
    prod = {
      location                = "West US 2"
      vnet_address_space     = "10.20.0.0/16"
      hub_address_space      = "10.21.0.0/24"
      sku_tier               = "Premium"
      enable_diagnostic_logs = true
      purge_on_destroy      = false
    }
  }
}
EOF

cat > shared/naming.tf << 'EOF'
# Consistent naming convention across environments
locals {
  naming_convention = {
    resource_group = "${var.project_name}-rg-${var.environment}-${random_string.suffix.result}"
    vnet          = "${var.project_name}-vnet-${var.environment}"
    hub_vnet      = "${var.project_name}-hub-vnet-${var.environment}"
    ai_foundry    = "${var.project_name}-aif-${var.environment}"
    key_vault     = "${var.project_name}kv${var.environment}${random_string.suffix.result}"
    storage       = "${var.project_name}st${var.environment}${random_string.suffix.result}"
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}
EOF

echo "✅ Created shared files"

# Create root README.md
cat > README.md << 'EOF'
# Azure AI/ML Landing Zone - Multi-Environment Setup

## Overview
This repository contains Terraform configurations for deploying Azure AI/ML Landing Zone across multiple environments (dev, staging, prod).

## Structure
- `modules/ai-ml-landing-zone/` - Reusable module containing the main logic
- `environments/` - Environment-specific configurations
- `shared/` - Shared locals and naming conventions

## Usage

### Deploy to Development
```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### Deploy to Staging  
```bash
cd environments/staging
terraform init
terraform plan
terraform apply
```

### Deploy to Production
```bash
cd environments/prod
terraform init
terraform plan
terraform apply
```

## Environment Customization
To customize environment folder names, update the folder structure and references in:
- Backend configuration keys
- Module source paths
- Documentation references

## Architecture

This implementation follows the Azure AI/ML Landing Zone default example pattern:
- Creates a sample hub VNet for network foundation
- Deploys AI Foundry with GPT-4o model deployment
- Includes supporting services (Container Registry, Cosmos DB, Key Vault, Storage, AI Search)
- Implements hub-spoke network topology with VNet peering
- Configures private DNS zones and security controls

## Prerequisites

1. Azure subscription with appropriate permissions
2. Terraform >= 1.9
3. Azure CLI configured
4. Storage accounts for Terraform state (update backend configurations)

## Next Steps

1. Update storage account names in each environment's `terraform.tf`
2. Review and customize variables in each environment
3. Deploy environments in order: dev → staging → prod
4. Configure CI/CD pipelines for automated deployments
EOF

echo "✅ Created root README.md"

# Create GitHub Actions workflows
echo "Creating GitHub Actions workflows..."

# Main CI/CD workflow
cat > .github/workflows/terraform-ci-cd.yml << 'EOF'
name: 'Terraform CI/CD'

on:
  push:
    branches:
      - main
      - develop
    paths:
      - 'modules/**'
      - 'environments/**'
      - 'shared/**'
      - '.github/workflows/**'
  pull_request:
    branches:
      - main
      - develop
    paths:
      - 'modules/**'
      - 'environments/**'
      - 'shared/**'

env:
  TF_VERSION: '1.9.8'
  ARM_USE_OIDC: true
  ARM_USE_AZUREAD: true
  ARM_STORAGE_USE_AZUREAD: true

jobs:
  detect-changes:
    name: 'Detect Changes'
    runs-on: ubuntu-latest
    outputs:
      dev-changed: ${{ steps.changes.outputs.dev }}
      staging-changed: ${{ steps.changes.outputs.staging }}
      prod-changed: ${{ steps.changes.outputs.prod }}
      modules-changed: ${{ steps.changes.outputs.modules }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Detect changes
        uses: dorny/paths-filter@v3
        id: changes
        with:
          filters: |
            dev:
              - 'environments/dev/**'
              - 'modules/**'
              - 'shared/**'
            staging:
              - 'environments/staging/**'
              - 'modules/**'
              - 'shared/**'
            prod:
              - 'environments/prod/**'
              - 'modules/**'
              - 'shared/**'
            modules:
              - 'modules/**'
              - 'shared/**'

  validate-and-plan:
    name: 'Validate and Plan'
    runs-on: ubuntu-latest
    needs: detect-changes
    strategy:
      matrix:
        environment: [dev, staging, prod]
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Terraform Format Check
        working-directory: environments/${{ matrix.environment }}
        run: terraform fmt -check -recursive

      - name: Terraform Init
        working-directory: environments/${{ matrix.environment }}
        run: terraform init
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

      - name: Terraform Validate
        working-directory: environments/${{ matrix.environment }}
        run: terraform validate

      - name: Terraform Plan
        working-directory: environments/${{ matrix.environment }}
        run: terraform plan -out=tfplan
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: tfplan-${{ matrix.environment }}
          path: environments/${{ matrix.environment }}/tfplan
          retention-days: 5

  deploy-dev:
    name: 'Deploy to Dev'
    runs-on: ubuntu-latest
    needs: [detect-changes, validate-and-plan]
    if: |
      github.ref == 'refs/heads/develop' && 
      needs.detect-changes.outputs.dev-changed == 'true'
    environment: 
      name: dev
      url: https://portal.azure.com
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Download Plan Artifact
        uses: actions/download-artifact@v4
        with:
          name: tfplan-dev
          path: environments/dev/

      - name: Terraform Init
        working-directory: environments/dev
        run: terraform init
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

      - name: Terraform Apply
        working-directory: environments/dev
        run: terraform apply -auto-approve tfplan
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

  deploy-staging:
    name: 'Deploy to Staging'
    runs-on: ubuntu-latest
    needs: [detect-changes, validate-and-plan, deploy-dev]
    if: |
      github.ref == 'refs/heads/main' && 
      needs.detect-changes.outputs.staging-changed == 'true'
    environment: 
      name: staging
      url: https://portal.azure.com
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Download Plan Artifact
        uses: actions/download-artifact@v4
        with:
          name: tfplan-staging
          path: environments/staging/

      - name: Terraform Init
        working-directory: environments/staging
        run: terraform init
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

      - name: Terraform Apply
        working-directory: environments/staging
        run: terraform apply -auto-approve tfplan
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

  deploy-prod:
    name: 'Deploy to Production'
    runs-on: ubuntu-latest
    needs: [detect-changes, validate-and-plan, deploy-staging]
    if: |
      github.ref == 'refs/heads/main' && 
      needs.detect-changes.outputs.prod-changed == 'true'
    environment: 
      name: production
      url: https://portal.azure.com
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Download Plan Artifact
        uses: actions/download-artifact@v4
        with:
          name: tfplan-prod
          path: environments/prod/

      - name: Terraform Init
        working-directory: environments/prod
        run: terraform init
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

      - name: Terraform Apply
        working-directory: environments/prod
        run: terraform apply -auto-approve tfplan
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
EOF

# Pull Request workflow
cat > .github/workflows/pr-validation.yml << 'EOF'
name: 'PR Validation'

on:
  pull_request:
    branches:
      - main
      - develop
    paths:
      - 'modules/**'
      - 'environments/**'
      - 'shared/**'

env:
  TF_VERSION: '1.9.8'
  ARM_USE_OIDC: true
  ARM_USE_AZUREAD: true
  ARM_STORAGE_USE_AZUREAD: true

jobs:
  validate:
    name: 'Validate Terraform'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, prod]
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Format Check
        working-directory: environments/${{ matrix.environment }}
        run: terraform fmt -check -recursive

      - name: Terraform Init
        working-directory: environments/${{ matrix.environment }}
        run: terraform init -backend=false

      - name: Terraform Validate
        working-directory: environments/${{ matrix.environment }}
        run: terraform validate

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: environments/${{ matrix.environment }}
          framework: terraform
          output_format: cli,sarif
          output_file_path: reports/results.sarif
          download_external_modules: true
          quiet: true

  security-scan:
    name: 'Security Scan'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'config'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
EOF

# Destroy workflow for cleanup
cat > .github/workflows/destroy-environment.yml << 'EOF'
name: 'Destroy Environment'

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to destroy'
        required: true
        type: choice
        options:
        - dev
        - staging
        - prod
      confirm_destroy:
        description: 'Type "DESTROY" to confirm'
        required: true
        type: string

env:
  TF_VERSION: '1.9.8'
  ARM_USE_OIDC: true
  ARM_USE_AZUREAD: true
  ARM_STORAGE_USE_AZUREAD: true

jobs:
  destroy:
    name: 'Destroy Infrastructure'
    runs-on: ubuntu-latest
    if: github.event.inputs.confirm_destroy == 'DESTROY'
    environment: 
      name: ${{ github.event.inputs.environment }}-destroy
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Terraform Init
        working-directory: environments/${{ github.event.inputs.environment }}
        run: terraform init
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

      - name: Terraform Destroy
        working-directory: environments/${{ github.event.inputs.environment }}
        run: terraform destroy -auto-approve
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
EOF

echo "✅ Created GitHub Actions workflows"

# Create scripts for local development and CI/CD helpers
cat > scripts/setup-azure-backend.sh << 'EOF'
#!/bin/bash

# Script to set up Azure Storage for Terraform backend
# Usage: ./scripts/setup-azure-backend.sh <environment> <location> <subscription-id>

set -e

ENVIRONMENT=$1
LOCATION=${2:-"East US 2"}
SUBSCRIPTION_ID=$3

if [ -z "$ENVIRONMENT" ] || [ -z "$SUBSCRIPTION_ID" ]; then
    echo "Usage: $0 <environment> [location] <subscription-id>"
    echo "Example: $0 dev 'East US 2' 12345678-1234-1234-1234-123456789012"
    exit 1
fi

# Set subscription
az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group for Terraform state
RG_NAME="terraform-state-rg-${ENVIRONMENT}"
az group create --name "$RG_NAME" --location "$LOCATION"

# Generate unique storage account name
STORAGE_NAME="tfstate${ENVIRONMENT}$(date +%s | tail -c 7)"
echo "Creating storage account: $STORAGE_NAME"

# Create storage account
az storage account create \
    --resource-group "$RG_NAME" \
    --name "$STORAGE_NAME" \
    --sku Standard_LRS \
    --encryption-services blob

# Create container
az storage container create \
    --name tfstate \
    --account-name "$STORAGE_NAME"

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "Update your environments/${ENVIRONMENT}/terraform.tf with:"
echo "  storage_account_name = \"$STORAGE_NAME\""
echo ""
echo "Storage account details:"
echo "  Resource Group: $RG_NAME"
echo "  Storage Account: $STORAGE_NAME"
echo "  Container: tfstate"
EOF

cat > scripts/format-and-validate.sh << 'EOF'
#!/bin/bash

# Script to format and validate all Terraform configurations
set -e

echo "🔧 Formatting Terraform files..."
terraform fmt -recursive .

echo "🔍 Validating Terraform configurations..."
for env in dev staging prod; do
    echo "Validating $env environment..."
    cd "environments/$env"
    terraform init -backend=false
    terraform validate
    cd - > /dev/null
done

echo "✅ All validations passed!"
EOF

cat > scripts/plan-all-environments.sh << 'EOF'
#!/bin/bash

# Script to run terraform plan for all environments
set -e

for env in dev staging prod; do
    echo "📋 Planning $env environment..."
    cd "environments/$env"
    terraform init
    terraform plan -out="tfplan-$env"
    cd - > /dev/null
    echo "✅ Plan complete for $env"
    echo ""
done

echo "🎉 All environment plans complete!"
echo "Plans saved as tfplan-<environment> in each environment directory"
EOF

# Make scripts executable
chmod +x scripts/*.sh

echo "✅ Created helper scripts"

# Create .gitignore
cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
tfplan*
*.tfvars.backup
*.tfplan

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Environment specific
.env
.env.local
.env.*.local

# Temporary files
temp/
tmp/
EOF

echo "✅ Created .gitignore"

# Create CONTRIBUTING.md
cat > CONTRIBUTING.md << 'EOF'
# Contributing to Azure AI/ML Landing Zone

## Development Workflow

### Branch Strategy
- `main` - Production deployments
- `develop` - Development deployments
- Feature branches - Individual features/fixes

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Update Terraform configurations
   - Test locally when possible
   - Follow Terraform formatting standards

3. **Format and validate**
   ```bash
   ./scripts/format-and-validate.sh
   ```

4. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: your descriptive commit message"
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request**
   - Target `develop` for development changes
   - Target `main` for production-ready changes
   - Include description of changes
   - Wait for automated checks to pass

### Environment Deployment Flow

```
Feature Branch → develop → Dev Environment
       ↓
   Pull Request → main → Staging Environment
       ↓
   After approval → Production Environment
```

### Local Development

1. **Setup Azure backend storage**
   ```bash
   ./scripts/setup-azure-backend.sh dev "East US 2" <subscription-id>
   ```

2. **Plan changes locally**
   ```bash
   cd environments/dev
   terraform init
   terraform plan
   ```

3. **Apply changes (dev only)**
   ```bash
   terraform apply
   ```

### Security Guidelines

- Never commit sensitive information
- Use Azure Key Vault for secrets
- Follow principle of least privilege
- Enable diagnostic logging in staging/prod
- Review security scan results in PRs

### Code Standards

- Use consistent naming conventions
- Add comments for complex configurations
- Follow Terraform best practices
- Keep modules focused and reusable
- Document any environment-specific changes

### CI/CD Pipeline

The GitHub Actions workflows automatically:
- ✅ Validate Terraform syntax and formatting
- 🔒 Run security scans (Checkov, Trivy)
- 📋 Generate deployment plans
- 🚀 Deploy to appropriate environments based on branch
- 📊 Store plan artifacts for review

### Getting Help

- Check existing issues and discussions
- Review the main README.md
- Consult Azure AI/ML Landing Zone documentation
- Ask questions in pull request comments
EOF

echo "✅ Created CONTRIBUTING.md"

echo ""
echo "🎉 Folder structure with CI/CD created successfully!"
echo ""
echo "Next steps:"
echo "1. Update storage account names in environments/*/terraform.tf"
echo "2. Review configurations in each environment"
echo "3. Run terraform init in each environment directory"
echo ""
echo "Structure created:"
echo "📁 modules/ai-ml-landing-zone/ - Reusable module"
echo "📁 environments/dev/ - Development environment"
echo "📁 environments/staging/ - Staging environment"
echo "📁 environments/prod/ - Production environment"
echo "📁 shared/ - Shared configurations"
echo "� .github/workflows/ - GitHub Actions CI/CD"
echo "📁 scripts/ - Helper scripts"
echo "�📄 README.md - Main documentation"
echo "📄 CONTRIBUTING.md - Development guidelines"
echo ""
echo "🚀 CI/CD Features Added:"
echo "• Automated terraform validation and planning"
echo "• Security scanning with Checkov and Trivy"
echo "• Progressive deployment: develop→dev, main→staging→prod"
echo "• Manual destroy workflow for cleanup"
echo "• Pull request validation"
echo ""
echo "📋 Next Steps for CI/CD Setup:"
echo "1. Set up Azure Service Principal with OIDC"
echo "2. Configure GitHub repository secrets:"
echo "   - AZURE_CLIENT_ID"
echo "   - AZURE_TENANT_ID" 
echo "   - AZURE_SUBSCRIPTION_ID"
echo "3. Create GitHub environments: dev, staging, production"
echo "4. Set up Azure storage backends using: ./scripts/setup-azure-backend.sh"
echo ""
echo "💻 To deploy an environment locally:"
echo "cd environments/dev && terraform init && terraform plan"