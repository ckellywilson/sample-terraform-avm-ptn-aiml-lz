# AI/ML Landing Zone Deployment Instructions

## Overview
This repository implements the Azure AI/ML Landing Zone pattern using Azure Verified Modules (AVM) and Terraform. These instructions ensure consistent deployment procedures across all methods (azd, GitHub Actions, Azure DevOps).

## Azure Developer CLI (azd) Deployment Workflow

When deploying this AI/ML Landing Zone using azd, **ALWAYS follow these steps in order**:

### 1. Prerequisites Check
**Before any deployment**, verify Azure resource providers are registered:

```bash
./examples/scripts/check-prerequisites.sh
```

**Required providers:**
- `Microsoft.CognitiveServices` (AI Foundry, AI Services)
- `Microsoft.MachineLearningServices` (AI Foundry workspace)
- `Microsoft.Storage` (Storage accounts)
- `Microsoft.KeyVault` (Key Vault)
- `Microsoft.DocumentDB` (Cosmos DB)
- `Microsoft.Search` (AI Search)
- `Microsoft.ContainerRegistry` (Container Registry)
- `Microsoft.App` (Container Apps)
- `Microsoft.Network` (VNet, Bastion, App Gateway)
- `Microsoft.Compute` (Build VM, Jump VM if enabled)
- `Microsoft.Web` (Application Gateway)
- `Microsoft.Insights` (Monitoring and diagnostics)
- `Microsoft.OperationalInsights` (Log Analytics)

If providers are not registered, the script will provide registration commands.

### 2. Azure Authentication
```bash
# Authenticate with Azure CLI
az login

# Set the target subscription
az account set --subscription <subscription-id>

# Verify current subscription
az account show
```

### 3. Initialize Azure Developer CLI
```bash
# Initialize using existing azure.yaml configuration
azd init --no-prompt
```

**What this does:**
- Loads configuration from `azure.yaml`
- Sets Terraform as the infrastructure provider
- Points to `examples/default` as the infrastructure path
- Configures the preprovision hook to run prerequisites check

### 4. Create azd Environment
```bash
# Create a new environment (e.g., default, dev, staging, prod)
azd env new <environment-name>
```

Example environment names:
- `default` - Default development environment
- `dev` - Development environment
- `staging` - Staging environment
- `prod` - Production environment

### 5. Configure Environment Variables
```bash
# Copy the sample environment file
cp .azure/.env.sample .azure/<environment-name>/.env

# Edit the .env file with required values
```

**Required variables:**
- `AZURE_SUBSCRIPTION_ID` - Your Azure subscription ID
- `AZURE_LOCATION` - Azure region (e.g., `eastus2`)

**Common optional variables:**
- `TF_VAR_enable_telemetry` - Enable/disable telemetry (default: `true`)
- `TF_VAR_existing_dns_zones_rg_id` - Existing DNS zones resource group ID
- `TF_VAR_storage_shared_access_key_enabled` - Enable storage shared access key (default: `false`)
- `TF_VAR_storage_use_azuread_authentication` - Use Entra ID authentication (default: `true`)
- `TF_VAR_use_internet_routing` - Use internet routing vs Microsoft routing (default: `false`)

**Example `.azure/<environment-name>/.env`:**
```bash
AZURE_ENV_NAME="default"
AZURE_LOCATION="eastus2"
AZURE_SUBSCRIPTION_ID="your-subscription-id"
TF_VAR_location="eastus2"
TF_VAR_subscription_id="your-subscription-id"
TF_VAR_enable_telemetry="true"
TF_VAR_storage_use_azuread_authentication="true"
TF_VAR_storage_shared_access_key_enabled="false"
```

### 6. Provision Infrastructure
```bash
# Run Terraform provision through azd
azd provision
```

**What this does:**
1. Runs preprovision hook (`check-prerequisites.sh`)
2. Executes `terraform init` in `examples/default`
3. Executes `terraform plan`
4. Executes `terraform apply` with auto-approve
5. Outputs Terraform outputs as azd outputs

**Important Notes:**
- First provision can take 15-30 minutes
- Remote state is NOT configured by default (local state only)
- For team usage, configure Azure Storage backend for Terraform state

### 7. Verify Deployment
```bash
# Show current azd environment
azd env list

# Show Terraform outputs
cd examples/default
terraform output
```

### 8. Cleanup / Destroy Resources
```bash
# Destroy all provisioned resources
azd down

# Or use Terraform directly
cd examples/default
terraform destroy
```

## Repository Structure

- `examples/default/` - **Primary deployment** (integrates with hub VNet)
- `examples/standalone/` - Standalone deployment without hub dependencies
- `examples/enterprise/` - Enterprise split deployment (platform + workload)
- `modules/example_hub_vnet/` - Supporting hub VNet module
- `examples/scripts/check-prerequisites.sh` - Prerequisites validation script

## Deployment Paths

### Option 1: azd with Default Example (Recommended)
- Uses `azure.yaml` configuration
- Deploys `examples/default`
- Includes hub VNet creation
- **Current azd configuration target**

### Option 2: Standalone Deployment
- Navigate to `examples/standalone`
- Use Terraform directly (not via azd)
- No hub VNet dependencies

### Option 3: Enterprise Deployment
- Navigate to `examples/enterprise/01-platform` (deploy first)
- Navigate to `examples/enterprise/02-workload` (deploy second)
- Use Terraform directly (not via azd)
- Separated platform and workload concerns

## Important Considerations

### Remote State Management
**Default:** Local Terraform state (`.tfstate` files)

**For team/production use:**
1. Create Azure Storage Account for state
2. Add backend configuration to `examples/default/main.tf`:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate<unique>"
    container_name       = "tfstate"
    key                  = "aiml-lz.tfstate"
  }
}
```

### Service Deployment
The `azure.yaml` has an empty `services` section because this sample focuses on **infrastructure provisioning only**. Application deployment is separate.

For application deployment (e.g., the chat app in `examples/src`):
- Use separate deployment pipeline
- Or extend `azure.yaml` with service definitions

### Variable Management
Add new Terraform variables to `.azure/.env` using `TF_VAR_` prefix:
```bash
TF_VAR_custom_variable="value"
```

These are automatically passed to Terraform during `azd provision`.

## Troubleshooting

### Prerequisites Check Fails
- Run provider registration manually: `az provider register --namespace <provider>`
- Wait for registration: `az provider show --namespace <provider> --query registrationState`
- Re-run: `./examples/scripts/check-prerequisites.sh`

### Terraform Init Fails
- Check Azure CLI authentication: `az account show`
- Verify subscription access: `az account set --subscription <id>`
- Check network connectivity to Terraform registry

### Terraform Apply Fails
- Review error messages for resource-specific issues
- Check quota limits: `az vm list-usage --location <region>`
- Verify resource naming conflicts
- Check RBAC permissions on subscription

### azd down Doesn't Remove All Resources
- Check for resources with delete locks
- Review resources in dependent resource groups
- Manual cleanup may be required for DNS zones or other protected resources

## CI/CD Integration

### GitHub Actions
Refer to deployment workflows that:
1. Authenticate with Azure using OIDC or Service Principal
2. Run prerequisites check
3. Set environment variables from secrets
4. Execute `azd provision` or Terraform directly

### Azure DevOps
Similar pattern using Azure DevOps service connections and variable groups.

## Best Practices

1. **Always run prerequisites check first** - Prevents mid-deployment failures
2. **Use environment-specific .env files** - Separate dev/staging/prod configurations
3. **Configure remote state for teams** - Avoid state conflicts
4. **Version lock Terraform** - Ensure consistent deployments (>=1.5.0 required)
5. **Review Terraform plan** - Understand changes before applying
6. **Enable diagnostic settings** - Configure Log Analytics for all resources
7. **Use Azure Private Endpoints** - Follow secure networking practices
8. **Document variable changes** - Update `.env.sample` when adding variables

## Security Considerations

- **Storage authentication**: Default uses Entra ID (not shared access keys)
- **Network routing**: Default uses Microsoft routing (not internet routing)
- **Private endpoints**: Enabled for AI Foundry, Storage, Key Vault
- **Diagnostic logging**: Enable for all AI/ML resources
- **Telemetry**: Enabled by default for Microsoft product improvement

## Support Resources

- [Azure AI/ML Landing Zone Documentation](https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Verified Modules](https://aka.ms/avm)
