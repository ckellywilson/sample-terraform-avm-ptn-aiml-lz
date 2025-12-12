# Azure AI/ML Landing Zone

Example deployment of Azure AI/ML Landing Zone using [Azure Verified Modules (AVM)](https://aka.ms/avm).

## Quick Start

### Prerequisites
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0

### Setup (One-Time)

**Single Source of Truth: GitHub Environment**

This repository uses GitHub Environments as the single source of truth for configuration. Both local (azd) and CI/CD (GitHub Actions) reference the same values.

#### 1. Configure GitHub Environment

```
Repository Settings → Environments → Create "default"

Add Secrets:
- AZURE_SUBSCRIPTION_ID = "your-subscription-id"
- AZURE_TENANT_ID = "your-tenant-id"
- AZURE_CLIENT_ID = "your-client-id" (for OIDC)

Add Variables:
- AZURE_LOCATION = "eastus2"
```

#### 2. Create Remote State Storage

```bash
# Authenticate and set subscription
az login
export AZURE_SUBSCRIPTION_ID="your-subscription-id"  # From GitHub Environment
az account set --subscription $AZURE_SUBSCRIPTION_ID

# Create state storage (one-time per subscription)
cd examples/default
../../scripts/ensure-remote-state.sh
```

#### 3. Configure Local azd Environment

```bash
# Initialize azd
cd ../..
azd init --no-prompt
azd env new default

# Copy environment template and fill from GitHub Environment values
cp .azure/.env.sample .azure/default/.env
# Edit .azure/default/.env:
#   - Copy AZURE_SUBSCRIPTION_ID from GitHub Environment secrets
#   - Copy AZURE_LOCATION from GitHub Environment variables
```

### Deploy

```bash
azd provision
```

This runs a 2-phase deployment:
1. **Phase 1**: Creates hub VNet, spoke VNet, AI Foundry, and all infrastructure
2. **Phase 2**: Links hub DNS zones to spoke VNet for full connectivity

### Cleanup

```bash
azd down
```

## Repository Structure

- `examples/default/` - Hub-spoke deployment (default for `azd`)
- `examples/standalone/` - Standalone deployment without hub
- `examples/enterprise/` - Split platform/workload deployment
- `modules/example_hub_vnet/` - Supporting hub VNet module

## What Gets Deployed

**Hub VNet:**
- Azure Firewall
- Azure Bastion
- DNS Resolver
- Windows 11 Jump VM
- 21 Private DNS zones

**Spoke VNet (AI/ML Landing Zone):**
- AI Foundry workspace and project
- Container Registry (ACR)
- Storage Account
- Key Vault
- Cosmos DB
- AI Search
- Container Apps Environment
- Private endpoints for all services

## Common Issues

**Backend configuration not found**
```bash
cd examples/default && ../../scripts/ensure-remote-state.sh
```

**Subscription mismatch**
Ensure `.azure/default/.env` and `terraform.tfvars` use the same subscription ID.

**DNS not resolving after deployment**
The postprovision hook automatically runs Phase 2. If it fails, run manually:
```bash
cd examples/default
terraform plan
terraform apply
```

## Documentation

- [Detailed Deployment Guide](.github/copilot-instructions.md) - Step-by-step instructions
- [Implementation Guide](IMPLEMENTATION_GUIDE.md) - Technical architecture details
- [Contributing](CONTRIBUTING.md) - Contribution guidelines

## License

This project is licensed under the MIT License.
