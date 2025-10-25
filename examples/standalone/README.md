# Azure AI Landing Zone - Standalone Example

This example demonstrates a **self-contained** AI/ML Landing Zone deployment with `flag_platform_landing_zone = false`. This creates all necessary AI/ML workload resources and supporting infrastructure without platform-level components like firewalls or bastion hosts.

## What is "Standalone"?

**Standalone** means **self-contained** - all the resources needed for the AI/ML workload are created as part of this deployment, but without platform infrastructure components.

### Deployed Resources (~150-200 resources):
- ✅ **AI/ML Workload Resources**: AI Foundry hub, AI projects, AI models, storage accounts, key vault, cosmos DB, AI search
- ✅ **Virtual Network**: Workload subnets for AI/ML services
- ✅ **Private DNS Zones**: For private endpoints (created automatically if not provided)
- ✅ **Private Endpoints**: Secure connectivity to Azure services
- ❌ **No Platform Infrastructure**: No Azure Firewall, Bastion, or route tables

### Key Configuration:
```hcl
flag_platform_landing_zone = false  # Self-contained deployment
```

## Usage

```bash
# 1. Copy and customize the configuration template
cp terraform.tfvars.example terraform.tfvars

# 2. Edit terraform.tfvars with your subscription ID
vim terraform.tfvars

# 3. Deploy the standalone AI/ML landing zone
terraform init
terraform plan
terraform apply
```

## Configuration Files

- **`main.tf`**: Main Terraform configuration with AI/ML landing zone resources
- **`variables.tf`**: Input variables for the deployment
- **`dns-zones.tf`**: Automatic DNS zones creation (if not provided)
- **`outputs.tf`**: Output values from the deployment
- **`terraform.tfvars.example`**: Configuration template (copy to terraform.tfvars)

## Key Variables

- **`subscription_id`**: Azure subscription ID for deployment (required)
- **`location`**: Azure region for resource deployment (default: "australiaeast")
- **`existing_dns_zones_rg_id`**: Resource group ID for existing DNS zones (optional)
- **`storage_shared_access_key_enabled`**: Enable storage shared access keys (default: false)

## Understanding `flag_platform_landing_zone = false`

This example sets `flag_platform_landing_zone = false`, which means:

### ✅ **What Gets Deployed** (Self-Contained AI/ML Resources):
- AI Foundry hub and projects
- AI model deployments (GPT-4.0)
- Storage accounts, Key Vault, Cosmos DB
- AI Search, Container Registry
- Virtual network with workload subnets
- Private endpoints and DNS zones
- Container App Environment

### ❌ **What Doesn't Get Deployed** (Platform Infrastructure):
- Azure Firewall and firewall policies
- Azure Bastion
- Jump VMs or build VMs
- Firewall route tables
- Platform management subnets

### **DNS Zones Behavior**:
- **If you provide `existing_dns_zones_rg_id`**: Uses your existing DNS zones
- **If not provided**: Automatically creates all necessary private DNS zones
- **Required zones**: Key Vault, Storage, Cosmos DB, AI Services, OpenAI, etc.

## Example Customization

To use your own existing DNS zones:

```hcl
# In terraform.tfvars
subscription_id = "your-actual-subscription-id"
existing_dns_zones_rg_id = "/subscriptions/your-subscription-id/resourceGroups/your-dns-rg"
```

## Security Best Practices

- ✅ Never commit `.tfvars` files to source control (they contain sensitive subscription IDs)
- ✅ The example uses `storage_shared_access_key_enabled = false` for better security
- ✅ AI Foundry uses managed identity for storage access when shared keys are disabled