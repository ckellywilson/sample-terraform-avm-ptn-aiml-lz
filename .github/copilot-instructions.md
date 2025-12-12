# AI/ML Landing Zone Deployment Instructions

## Overview
This repository implements the Azure AI/ML Landing Zone pattern using Azure Verified Modules (AVM) and Terraform. These instructions ensure consistent deployment procedures across all methods (azd, GitHub Actions, Azure DevOps).

> **🔧 For Technical Implementation Details**: See [IMPLEMENTATION_GUIDE.md](../IMPLEMENTATION_GUIDE.md) for deep-dive architecture, code changes, and technical rationale behind the 2-phase deployment approach.

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

### 3. One-Time Remote State Setup

**Before first deployment**, set up Terraform remote state storage:

```bash
# Set your target subscription
export AZURE_SUBSCRIPTION_ID="808c8f6e-4a1c-417e-9a77-db2619ce3d1a"
az account set --subscription $AZURE_SUBSCRIPTION_ID

# Create remote state storage (idempotent - safe to run multiple times)
cd examples/default
../../scripts/ensure-remote-state.sh

# Verify backend.tf was created
cat backend.tf
```

**What this does:**
- Creates `tfstate-rg-aiml-lz` resource group if needed
- Creates storage account with RBAC-only access (no shared keys)
- Generates `backend.tf` for Terraform to use
- Generates `backend.env` for CI/CD pipelines

**Important:** This step only needs to be run **once per subscription**. The script is idempotent, so it's safe to run multiple times.

### 4. Initialize Azure Developer CLI
```bash
# Initialize using existing azure.yaml configuration
azd init --no-prompt
```

**What this does:**
- Loads configuration from `azure.yaml`
- Sets Terraform as the infrastructure provider
- Points to `examples/default` as the infrastructure path
- Configures the preprovision hook to run prerequisites check

### 5. Create azd Environment
```bash
# Create a new environment (e.g., default, dev, staging, prod)
azd env new <environment-name>
```

Example environment names:
- `default` - Default development environment
- `dev` - Development environment
- `staging` - Staging environment
- `prod` - Production environment

### 6. Configure Environment Variables
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
- `TF_VAR_enable_spoke_dns_links` - Enable DNS zone links to spoke VNet (set to `false` for Phase 1, `true` for Phase 2)
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
TF_VAR_enable_spoke_dns_links="false"
```

### 7. Provision Infrastructure (2-Phase Deployment)

The default deployment uses a **2-phase approach** controlled by the `enable_spoke_dns_links` variable. This enables DNS resolution between hub and spoke VNets and works seamlessly in CI/CD pipelines.

#### Phase 1: Initial Infrastructure Deployment
```bash
# Set variable for Phase 1 (DNS zones linked to hub only)
azd env set TF_VAR_enable_spoke_dns_links false

# Deploy infrastructure
azd provision
```

**Or using Terraform directly:**
```bash
cd examples/default
terraform apply -var="enable_spoke_dns_links=false"
```

**What this does:**
1. Runs preprovision hook (`check-prerequisites.sh`)
2. Data source for spoke VNet has `count = 0` (not evaluated)
3. Hub DNS zones created and linked to hub VNet only
4. Spoke VNet and all AI/ML resources created

**Phase 1 Results:**
- ✅ Hub VNet with firewall, bastion, DNS resolver, jump VM created
- ✅ 21 private DNS zones created (linked to hub VNet only)
- ✅ Spoke VNet created (192.168.0.0/23)
- ✅ AI/ML Landing Zone resources deployed (ACR, Storage, Key Vault, AI Foundry, etc.)
- ✅ All private endpoints created
- ✅ VNet peering between hub and spoke established
- ❌ **DNS resolution from hub to spoke does NOT work yet**

**Expected Time:** 15-30 minutes

**DNS Status After Phase 1:**
- ❌ Jump VM **cannot** resolve ACR private endpoints
- ❌ Jump VM **cannot** resolve Storage private endpoints
- ❌ Jump VM **cannot** resolve Key Vault private endpoints

#### Phase 2: DNS Zone Linking
```bash
# Set variable for Phase 2 (add DNS zone links to spoke)
azd env set TF_VAR_enable_spoke_dns_links true

# Deploy DNS links
azd provision
```

**Or using Terraform directly:**
```bash
cd examples/default
terraform apply -var="enable_spoke_dns_links=true"
```

**What this does:**
1. Data source for spoke VNet now has `count = 1` (evaluated)
2. Spoke VNet ID is retrieved successfully
3. Hub DNS zones gain 21 new VNet links to spoke

**Phase 2 Results:**
- ✅ Hub private DNS zones gain spoke VNet links
- ✅ 21 new `azurerm_private_dns_zone_virtual_network_link` resources created
- ✅ **DNS resolution from hub to spoke now works!**

**Expected Time:** 2-5 minutes

**DNS Status After Phase 2:**
- ✅ Jump VM **can** resolve ACR private endpoints (e.g., `myacr.azurecr.io` → 192.168.0.x)
- ✅ Jump VM **can** resolve Storage private endpoints
- ✅ Jump VM **can** resolve all spoke private resources

**Important Notes:**
- **Remote state is automatically configured** in `tfstate-rg-aiml-lz` resource group
- State storage uses **Entra ID authentication only** (no shared access keys)
- State backend is reused across deployments (not recreated)
- **Two applies are required** due to Terraform's data source evaluation order
- **Variable-controlled approach** works seamlessly in CI/CD pipelines

### 8. Verify Deployment
```bash
# Show current azd environment
azd env list

# Show Terraform outputs
cd examples/default
terraform output

# Verify DNS zone links were created (after Phase 2)
HUB_RG=$(terraform output -raw hub_resource_group_name)
az network private-dns link vnet list \
  --resource-group $HUB_RG \
  --zone-name privatelink.azurecr.io \
  --output table

# Expected output: 2 links (hub VNet + spoke VNet)
```

**Test DNS Resolution from Jump VM (via Azure Bastion):**
```powershell
# Test ACR DNS resolution
nslookup <your-acr-name>.azurecr.io

# Should return private IP in range 192.168.0.0/23
# Example: 192.168.0.45
```

**Success Criteria:**
- ✅ RDP to Windows 11 jump VM via Azure Bastion works
- ✅ Resolve ACR private endpoint returns 192.168.0.x address
- ✅ Push Docker images to ACR from jump VM succeeds
- ✅ Deploy containers to ACA from jump VM succeeds

### 9. Cleanup / Destroy Resources
```bash
# Destroy all provisioned resources
azd down

# Note: State storage (tfstate-rg-aiml-lz) is preserved for recovery
# To manually delete state storage:
az group delete --name tfstate-rg-aiml-lz --yes

# Or use Terraform directly
cd examples/default
terraform destroy
```

**State Storage Preservation:**
- The `tfstate-rg-aiml-lz` resource group is **NOT** deleted by `azd down`
- This preserves state history for potential recovery or auditing
- State storage costs are minimal (typically < $1/month)
- Delete manually only if you're certain you won't need state history

## Repository Structure

- `examples/default/` - **Primary deployment** (integrates with hub VNet)
- `examples/standalone/` - Standalone deployment without hub dependencies
- `examples/enterprise/` - Enterprise split deployment (platform + workload)
- `modules/example_hub_vnet/` - Supporting hub VNet module
- `examples/scripts/check-prerequisites.sh` - Prerequisites validation script
- `examples/scripts/ensure-remote-state.sh` - Remote state backend automation script

## Deployment Paths

### Option 1: azd with Default Example (Recommended)
- Uses `azure.yaml` configuration
- Deploys `examples/default`
- Includes hub VNet creation
- **Requires 2-phase deployment** (see below)
- **Current azd configuration target**

### Option 2: Standalone Deployment
- Navigate to `examples/standalone`
- Use Terraform directly (not via azd)
- No hub VNet dependencies
- **Single-phase deployment** (no DNS zone linking required)

### Option 3: Enterprise Deployment
- Navigate to `examples/enterprise/01-platform` (deploy first)
- Navigate to `examples/enterprise/02-workload` (deploy second)
- Use Terraform directly (not via azd)
- Separated platform and workload concerns
- **Single-phase deployment** for each component

## Important Considerations

### Remote State Management
**Automatic Configuration:** Remote state is automatically set up by the `ensure-remote-state.sh` script during `azd provision`.

**State Storage Details:**
- **Resource Group**: `tfstate-rg-aiml-lz`
- **Storage Account**: Auto-generated name (e.g., `tfstate2857dabb`)
- **Container**: `tfstate`
- **Authentication**: Entra ID (RBAC) only - no shared access keys
- **Location**: Matches `AZURE_LOCATION` environment variable

**Key Features:**
- **Idempotent**: Safe to run multiple times, won't recreate if exists
- **RBAC-Only**: Complies with policies disabling shared access keys
- **Preserved on Destroy**: State storage is NOT deleted by `azd down`
- **Team-Ready**: State is automatically shared via Azure Storage
- **Hybrid Approach**: Supports both local/azd and CI/CD workflows

The backend configuration is automatically generated in **two files**:

#### 1. `backend.tf` (for local/azd - auto-detected by Terraform)
```hcl
# Auto-generated by ensure-remote-state.sh
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg-aiml-lz"
    storage_account_name = "tfstate<generated>"
    container_name       = "tfstate"
    key                  = "aiml-lz-default.tfstate"
    use_azuread_auth     = true
  }
}
```

#### 2. `backend.env` (for CI/CD - source in workflows)
```bash
# Auto-generated by ensure-remote-state.sh
export ARM_BACKEND_RESOURCE_GROUP_NAME="tfstate-rg-aiml-lz"
export ARM_BACKEND_STORAGE_ACCOUNT_NAME="tfstate<generated>"
export ARM_BACKEND_CONTAINER_NAME="tfstate"
export ARM_BACKEND_KEY="aiml-lz-default.tfstate"
export ARM_USE_AZUREAD_AUTH="true"
```

The `main.tf` does **NOT** contain a backend block:
```hcl
terraform {
  # Backend configuration is in backend.tf (auto-generated)
  # Do not add backend block here
}
```

To manually run the remote state setup:
```bash
./examples/scripts/ensure-remote-state.sh
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

### DNS Still Not Resolving After Phase 2
**Symptom:** Jump VM still cannot resolve private endpoints after second apply

**Checks:**
1. Verify VNet links exist:
   ```bash
   HUB_RG=$(cd examples/default && terraform output -raw hub_resource_group_name)
   az network private-dns link vnet list \
     --resource-group $HUB_RG \
     --zone-name privatelink.azurecr.io \
     --query "[].{Name:name, VNet:virtualNetwork.id}" -o table
   ```

2. Verify private endpoint IPs:
   ```bash
   SPOKE_RG=$(cd examples/default && terraform output -raw ai_lz_resource_group_name)
   az network private-endpoint show \
     --resource-group $SPOKE_RG \
     --name <pe-name> \
     --query "customDnsConfigs[].ipAddresses" -o table
   ```

3. Test from jump VM DNS server (hub DNS resolver):
   ```bash
   nslookup <your-acr-name>.azurecr.io <hub-dns-resolver-ip>
   ```

### Second Apply Shows No Changes
**Symptom:** `No changes. Your infrastructure matches the configuration.` after first apply

**Cause:** The data source might not be detecting the spoke VNet

**Solution:** Check the spoke VNet exists:
```bash
cd examples/default
SPOKE_VNET_NAME=$(terraform output -raw spoke_vnet_name)
SPOKE_RG=$(terraform output -raw ai_lz_resource_group_name)
az network vnet show \
  --resource-group $SPOKE_RG \
  --name $SPOKE_VNET_NAME \
  --query "id" -o tsv
```

### Data Source Fails on First Apply
**Symptom:** Error: "Virtual network not found" during first apply

**Solution:** This is expected! The conditional count prevents this:
```hcl
count = fileexists("${path.module}/terraform.tfstate") ? 1 : 0
```

If you see this error, it means the safeguard isn't working correctly. Check that `terraform.tfstate` doesn't exist yet.

### azd down Doesn't Remove All Resources
- Check for resources with delete locks
- Review resources in dependent resource groups
- Manual cleanup may be required for DNS zones or other protected resources

## CI/CD Integration

### GitHub Actions
Refer to [`.github/workflows/terraform-deploy.yml`](.github/workflows/terraform-deploy.yml) for a complete two-phase deployment workflow that:
1. Authenticates with Azure using OIDC or Service Principal
2. Runs prerequisites check
3. Sets up remote state storage
4. **Phase 1 Job**: Deploys infrastructure with `TF_VAR_enable_spoke_dns_links="false"`
5. **Phase 2 Job**: Adds DNS zone links with `TF_VAR_enable_spoke_dns_links="true"`

**Key environment variables:**
- `TF_VAR_subscription_id` - Azure subscription ID (from secrets)
- `TF_VAR_location` - Azure region
- `TF_VAR_enable_spoke_dns_links` - Controls deployment phase (`"false"` for Phase 1, `"true"` for Phase 2)

### Azure DevOps
Similar pattern using Azure DevOps service connections and variable groups:

```yaml
stages:
  - stage: Phase1
    jobs:
      - job: DeployInfrastructure
        steps:
          - task: TerraformCLI@0
            inputs:
              command: 'apply'
              workingDirectory: 'examples/default'
              environmentServiceName: 'Azure-Connection'
              commandOptions: '-var="enable_spoke_dns_links=false"'

  - stage: Phase2
    dependsOn: Phase1
    jobs:
      - job: ConfigureDNS
        steps:
          - task: TerraformCLI@0
            inputs:
              command: 'apply'
              workingDirectory: 'examples/default'
              environmentServiceName: 'Azure-Connection'
              commandOptions: '-var="enable_spoke_dns_links=true"'
```

## Best Practices

1. **Always run prerequisites check first** - Prevents mid-deployment failures
2. **Use environment-specific .env files** - Separate dev/staging/prod configurations
3. **Configure remote state for teams** - Avoid state conflicts
4. **Version lock Terraform** - Ensure consistent deployments (>=1.5.0 required)
5. **Review Terraform plan** - Understand changes before applying
6. **Enable diagnostic settings** - Configure Log Analytics for all resources
7. **Use Azure Private Endpoints** - Follow secure networking practices
8. **Document variable changes** - Update `.env.sample` when adding variables
9. **Run Phase 2 deployment** - Always run the second `terraform apply` to enable DNS resolution

## Understanding the 2-Phase Deployment

### Why Two Applies Are Necessary

**Terraform Constraint:** Data sources are evaluated during the plan phase, before resources are created. Even with `depends_on`, Terraform cannot:
1. Create the spoke VNet in the same apply
2. Read it back via data source in the same apply
3. Pass it to the hub module in the same apply

This is a fundamental Terraform limitation, not a configuration issue.

**How the Variable Approach Works:**
- Phase 1: Variable set to `false`, data source skipped entirely (`count = 0`)
- Phase 2: Variable set to `true`, data source evaluated and spoke VNet retrieved (`count = 1`)
- Both phases use the same remote state - no cleanup needed

### How It Works Internally

#### Phase 1 (First Apply - `enable_spoke_dns_links = false`)
```hcl
# Data source is not created (count = 0)
data "azurerm_virtual_network" "spoke" {
  count = var.enable_spoke_dns_links ? 1 : 0  # count = 0
  # Result: Data source not evaluated
}

# Hub module receives empty list
spoke_vnet_resource_ids = length(data.azurerm_virtual_network.spoke) > 0 ? 
  [data.azurerm_virtual_network.spoke[0].id] : []
# Result: [] (empty list)
```

**What happens:**
- Data source has `count = 0` (not created or evaluated)
- Hub DNS zones are created and linked to hub VNet only
- Spoke VNet is created with all resources
- No DNS zone links to spoke yet ❌

#### Phase 2 (Second Apply - `enable_spoke_dns_links = true`)
```hcl
# Data source is now created and evaluated
data "azurerm_virtual_network" "spoke" {
  count = var.enable_spoke_dns_links ? 1 : 0  # count = 1
  name  = "ai-lz-vnet-default"
  # Result: Successfully retrieves spoke VNet resource ID
}

# Hub module receives spoke VNet ID
spoke_vnet_resource_ids = ["/subscriptions/.../virtualNetworks/ai-lz-vnet-default"]
```

**What happens:**
- Data source successfully retrieves spoke VNet ID
- Hub module detects new spoke VNet in the list
- Terraform adds 21 new VNet links (one for each DNS zone)
- DNS resolution now works! ✅

### Benefits of This Approach

✅ **No manual steps** - fully automated  
✅ **Idempotent** - safe to run multiple times  
✅ **Self-documenting** - code explains the two-phase process  
✅ **Production-ready** - handles edge cases gracefully  
✅ **CI/CD friendly** - works with remote backends  
✅ **Repeatable** - works for multiple spoke VNets  

### Plan Statistics

When you run the first apply, expect:
- ✅ **~365 resources to add** (AI/ML Landing Zone infrastructure)
- 🔄 **~3 resources to change** (subnet updates)
- ❌ **0 resources to destroy**

Key infrastructure created includes:
- Hub VNet with Azure Firewall, Bastion, DNS Resolver, Windows 11 Jump VM
- 21 private DNS zones (initially linked to hub VNet only)
- Spoke VNet with AI/ML Landing Zone resources
- AI Foundry projects, ACR, Storage, Key Vault, Cosmos DB, AI Search
- Container Apps environment
- All private endpoints and VNet peering

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
