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
