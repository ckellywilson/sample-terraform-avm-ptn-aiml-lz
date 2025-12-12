# Hub-Spoke DNS Zone Links: Implementation Guide (Default Configuration Only)

## Branch: `feature/hub-spoke-dns-zone-links`

> **📘 For Deployment Instructions**: See [.github/copilot-instructions.md](.github/copilot-instructions.md) for step-by-step deployment guidance.
> 
> This document focuses on **technical implementation details** for the **`examples/default` configuration** which integrates with a hub VNet.

> **⚠️ Note**: This 2-phase deployment approach applies **only to the `examples/default` configuration**. The `examples/standalone` and `examples/enterprise` configurations do not require this approach.

## Problem Statement

In the **`examples/default`** hub-spoke network topology, the jump VM in the hub VNet cannot resolve private DNS names (e.g., ACR, Storage, Key Vault) for resources in the spoke VNet. This happens because the hub's private DNS zones are only linked to the hub VNet, not the spoke VNet.

## Solution Overview (Default Configuration)

This implementation adds the capability for hub private DNS zones to be automatically linked to spoke VNets using a **variable-controlled data source** in the `examples/default` configuration. The solution requires two Terraform applies controlled by the `enable_spoke_dns_links` variable.

### Deployment Control Variable

A new variable `enable_spoke_dns_links` controls whether the spoke VNet data source is evaluated:

```hcl
variable "enable_spoke_dns_links" {
  type        = bool
  default     = false
  description = "Enable DNS zone links to spoke VNet. Set to false for Phase 1, true for Phase 2."
}
```

This approach is **CI/CD friendly** and works with remote backends, unlike file existence checks.

## How It Works

### Phase 1 (First Apply - `enable_spoke_dns_links = false`)
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

**Deployment command:**
```bash
terraform apply -var="enable_spoke_dns_links=false"
# Or in CI/CD: TF_VAR_enable_spoke_dns_links="false"
```

### Phase 2 (Second Apply - `enable_spoke_dns_links = true`)
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

**Deployment command:**
```bash
terraform apply -var="enable_spoke_dns_links=true"
# Or in CI/CD: TF_VAR_enable_spoke_dns_links="true"
```

**What happens:**
- Data source successfully retrieves spoke VNet ID
- Hub module detects new spoke VNet in the list
- Terraform adds 21 new VNet links (one for each DNS zone)
- DNS resolution now works! ✅

## Implementation Steps

### Step 1: Apply Phase 1
```bash
cd /workspaces/sample-terraform-avm-ptn-aiml-lz/examples/default

# Generate and review the plan
terraform plan -out=tfplan

# Apply (creates all infrastructure, DNS zones linked to hub only)
terraform apply tfplan
```

**Expected Time:** 15-30 minutes

**What's Created:**
- Hub VNet with firewall, bastion, DNS resolver, jump VM
- 21 private DNS zones (linked to hub VNet only)
- Spoke VNet (192.168.0.0/23)
- AI/ML Landing Zone resources (ACR, Storage, Key Vault, AI Foundry, etc.)
- All private endpoints
- VNet peering between hub and spoke

**DNS Status After Phase 1:**
- ❌ Jump VM **cannot** resolve ACR private endpoints
- ❌ Jump VM **cannot** resolve Storage private endpoints
- ❌ Jump VM **cannot** resolve Key Vault private endpoints

### Step 2: Apply Phase 2 (Automatic DNS Zone Linking)
```bash
# Generate plan - Terraform will detect the spoke VNet and plan to add DNS links
terraform plan

# Review the plan output - should show ~21 new VNet links
# Look for: module.example_hub.module.private_dns_zones[...].virtual_network_links

# Apply to add DNS zone links
terraform apply
```

**Expected Time:** 2-5 minutes

**What's Changed:**
- Hub private DNS zones gain spoke VNet links
- 21 new `azurerm_private_dns_zone_virtual_network_link` resources created

**DNS Status After Phase 2:**
- ✅ Jump VM **can** resolve ACR private endpoints (e.g., `myacr.azurecr.io` → 192.168.0.x)
- ✅ Jump VM **can** resolve Storage private endpoints
- ✅ Jump VM **can** resolve all spoke private resources

### Step 3: Verify DNS Resolution
```bash
# Check DNS zone links were created
HUB_RG="default-example-rg-jz88"
az network private-dns link vnet list \
  --resource-group $HUB_RG \
  --zone-name privatelink.azurecr.io \
  --output table

# Expected output: 2 links (hub VNet + spoke VNet)
```

**Test from Jump VM (via Azure Bastion):**
```powershell
# Test ACR DNS resolution
nslookup <your-acr-name>.azurecr.io

# Should return private IP in range 192.168.0.0/23
# Example: 192.168.0.45
```

## CI/CD Deployment Approaches

### GitHub Actions (Recommended)

See [`.github/workflows/terraform-deploy.yml`](.github/workflows/terraform-deploy.yml) for a complete two-phase workflow:

**Phase 1 Job:**
```yaml
- name: Terraform Apply - Phase 1
  env:
    TF_VAR_enable_spoke_dns_links: "false"
  run: terraform apply -auto-approve
```

**Phase 2 Job:**
```yaml
- name: Terraform Apply - Phase 2
  needs: phase1-deploy
  env:
    TF_VAR_enable_spoke_dns_links: "true"
  run: terraform apply -auto-approve
```

### Azure DevOps Pipeline

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

### azd Deployment

```bash
# Phase 1
azd env set TF_VAR_enable_spoke_dns_links false
azd provision

# Phase 2  
azd env set TF_VAR_enable_spoke_dns_links true
azd provision
```

## Why Two Applies Are Necessary

**Terraform Constraint:** Data sources are evaluated during the plan phase, before resources are created. Even with `depends_on`, Terraform cannot:
1. Create the spoke VNet in the same apply
2. Read it back via data source in the same apply
3. Pass it to the hub module in the same apply

This is a fundamental Terraform limitation, not a configuration issue.

**Why the Variable Approach Works:**
- Phase 1: Variable set to `false`, data source skipped entirely (`count = 0`)
- Phase 2: Variable set to `true`, data source evaluated and spoke VNet retrieved (`count = 1`)
- Both phases use the same remote state - no cleanup needed

## Troubleshooting

### Issue: Spoke VNet not found in Phase 2
**Symptom:** Error: "Virtual network not found" during Phase 2

**Solution:** Verify the spoke VNet was created in Phase 1:
```bash
SPOKE_RG=$(terraform output -raw ai_lz_resource_group_name)
SPOKE_VNET=$(terraform output -raw spoke_vnet_name)
az network vnet show \
  --resource-group $SPOKE_RG \
  --name $SPOKE_VNET \
  --query "id" -o tsv
```

### Issue: Second apply shows no changes
**Symptom:** `No changes. Your infrastructure matches the configuration.`

**Cause:** The `enable_spoke_dns_links` variable is still set to `false`

**Solution:** Ensure you set the variable to `true` for Phase 2:
```bash
terraform apply -var="enable_spoke_dns_links=true"
```
  --name ai-lz-vnet-default \
  --query "id" -o tsv
```

### Issue: DNS still not resolving after Phase 2
**Symptom:** Jump VM still cannot resolve private endpoints

**Checks:**
1. Verify VNet links exist:
   ```bash
   az network private-dns link vnet list \
     --resource-group default-example-rg-jz88 \
     --zone-name privatelink.azurecr.io \
     --query "[].{Name:name, VNet:virtualNetwork.id}" -o table
   ```

2. Verify private endpoint IPs:
   ```bash
   az network private-endpoint show \
     --resource-group ai-lz-rg-default-kki61 \
     --name <pe-name> \
     --query "customDnsConfigs[].ipAddresses" -o table
   ```

3. Test from jump VM DNS server (hub DNS resolver):
   ```bash
   nslookup <your-acr-name>.azurecr.io <hub-dns-resolver-ip>
   ```

## Benefits of This Approach

✅ **No manual steps** - fully automated  
✅ **Idempotent** - safe to run multiple times  
✅ **Self-documenting** - code explains the two-phase process  
✅ **Production-ready** - handles edge cases gracefully  
✅ **Repeatable** - works for multiple spoke VNets  

## Adding More Spoke VNets

To add additional spoke VNets to the DNS zones:

```hcl
# Add more data sources
data "azurerm_virtual_network" "spoke2" {
  count = fileexists("${path.module}/terraform.tfstate") ? 1 : 0
  
  name                = "second-spoke-vnet"
  resource_group_name = "second-spoke-rg"
}

# Update the list
spoke_vnet_resource_ids = compact([
  length(data.azurerm_virtual_network.spoke) > 0 ? data.azurerm_virtual_network.spoke[0].id : "",
  length(data.azurerm_virtual_network.spoke2) > 0 ? data.azurerm_virtual_network.spoke2[0].id : "",
])
```

## Plan Statistics

When you run the first apply, expect:
- ✅ **365 resources to add** (AI/ML Landing Zone infrastructure)
- 🔄 **3 resources to change** (subnet updates)
- ❌ **0 resources to destroy**

Key infrastructure created includes:
- Hub VNet with Azure Firewall, Bastion, DNS Resolver, Windows 11 Jump VM
- 21 private DNS zones (initially linked to hub VNet only)
- Spoke VNet with AI/ML Landing Zone resources
- AI Foundry projects, ACR, Storage, Key Vault, Cosmos DB, AI Search
- Container Apps environment
- All private endpoints and VNet peering

## Code Changes Summary

### Files Modified
- ✅ `modules/example_hub_vnet/variables.tf` - Added `spoke_vnet_resource_ids` variable
- ✅ `modules/example_hub_vnet/main.tf` - Updated DNS zones to support spoke VNet links
- ✅ `examples/default/main.tf` - Added data source and conditional logic
- ✅ `examples/default/outputs.tf` - Updated outputs

### Key Implementation Details

**Hub Module Enhancement:**
```hcl
# New variable accepts list of spoke VNet resource IDs
variable "spoke_vnet_resource_ids" {
  type        = list(string)
  default     = []
  description = "List of spoke VNet resource IDs to link to private DNS zones"
}

# DNS zones now support multiple VNet links (hub + spokes)
virtual_network_links = merge(
  { hub_vnet_link = {...} },
  { for idx, spoke_vnet_id in var.spoke_vnet_resource_ids : 
    "spoke_vnet_link_${idx}" => {...} 
  }
)
```

**Automated Spoke Detection:**
```hcl
# Data source looks up spoke VNet after it's created
data "azurerm_virtual_network" "spoke" {
  count = fileexists("${path.module}/terraform.tfstate") ? 1 : 0
  name  = "ai-lz-vnet-default"
  # ...
}

# Conditional logic automatically populates spoke VNet ID
spoke_vnet_resource_ids = length(data.azurerm_virtual_network.spoke) > 0 ? 
  [data.azurerm_virtual_network.spoke[0].id] : []
```

## Summary

The **automated 2-phase approach** eliminates manual intervention while working within Terraform's constraints. Simply run `terraform apply` twice, and DNS resolution across hub-spoke topology will work automatically.

### Success Criteria
After both applies complete, you should be able to:
- ✅ RDP to Windows 11 jump VM via Azure Bastion
- ✅ Resolve ACR private endpoint: `nslookup <acr-name>.azurecr.io` → returns 192.168.0.x
- ✅ Push Docker images to ACR from jump VM
- ✅ Deploy containers to ACA from jump VM
