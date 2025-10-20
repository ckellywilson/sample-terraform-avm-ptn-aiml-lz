# AI/ML Landing Zone with Existing Hub

This example demonstrates how to deploy the Azure AI/ML Landing Zone integrated with an existing platform hub network. This is the most common enterprise scenario where you have an existing platform landing zone with hub network infrastructure.

## Architecture

This deployment creates:

1. **AI/ML Landing Zone VNet**: Dedicated virtual network for AI/ML workloads
2. **VNet Peering**: Connects AI/ML LZ to existing hub network
3. **Private Endpoints**: Secure connectivity for all AI/ML services
4. **Private DNS Integration**: Uses existing or creates new private DNS zones
5. **Enterprise Integration**: Leverages existing hub DNS, firewall, and connectivity

## Prerequisites

- Existing platform hub network with proper addressing
- Permissions to create VNet peering (both directions if reverse peering needed)
- Access to existing private DNS zones (if using existing ones)
- Azure subscription with appropriate permissions
- Terraform >= 1.9
- Azure CLI installed and authenticated

### Cross-Subscription Prerequisites (Enterprise Pattern)

For **cross-subscription deployments** (hub in one subscription, spoke in another):

1. **Service Principal Requirements**:
   - Create service principal in spoke subscription using `scripts/create-service-principal.sh`
   - Configure cross-subscription permissions using `scripts/configure-cross-subscription-permissions.sh`

2. **Required Permissions in Hub Subscription**:
   - `Reader` role on hub subscription (to read hub resources)
   - `Network Contributor` role on hub VNet (for VNet peering)
   - `Private DNS Zone Contributor` role on hub resource group (for DNS zone links)

3. **Setup Commands**:
   ```bash
   # 1. Create service principal in spoke subscription
   ./scripts/create-service-principal.sh <spoke-subscription-id> terraform-aiml-lz-sp
   
   # 2. Get service principal object ID
   SP_OBJECT_ID=$(az ad sp show --id <CLIENT_ID> --query id -o tsv)
   
   # 3. Configure cross-subscription permissions
   ./scripts/configure-cross-subscription-permissions.sh \
     <hub-subscription-id> \
     <spoke-subscription-id> \
     $SP_OBJECT_ID \
     <hub-resource-group> \
     <hub-vnet-name>
   ```

   **Example**:
   ```bash
   ./scripts/configure-cross-subscription-permissions.sh \
     808c8f6e-4a1c-417e-9a77-db2619ce3d1a \
     f8a5f387-2f0b-42f5-b71f-5ee02b8967cf \
     2b808f3b-42ea-4d62-beae-6731c227c59c \
     rg-hub-eus2-byx4af \
     vnet-hub-eus2-byx4af
   ```

### Creating a Sample Hub with ALZ AVM

If you don't have an existing platform hub network, you can create one using the official Azure Landing Zone (ALZ) Terraform Azure Verified Modules. 

> **💡 Recommended Approach**: Use the dedicated [Sample Hub](../sample-hub/) example which provides a complete, production-ready hub infrastructure using ALZ AVM modules.

**Quick Hub Creation:**

```bash
# Navigate to the sample hub directory
cd ../sample-hub

# Configure and deploy the hub
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

terraform init
terraform plan
terraform apply

## Integration with Example Hub VNet Module

If you're using the `modules/example_hub_vnet` to create a sample hub for testing, follow these steps:

### Step 1: Deploy the Example Hub
```bash
# Navigate to a directory for hub deployment
cd /tmp/hub-deployment
mkdir -p hub && cd hub

# Create main.tf for hub
cat > main.tf << 'EOF'
module "example_hub" {
  source = "path/to/sample-terraform-avm-ptn-aiml-lz/modules/example_hub_vnet"
  
  location            = "East US 2"
  resource_group_name = "rg-aiml-hub-example"
  deployer_ip_address = "YOUR_PUBLIC_IP"  # Get from curl ifconfig.me
  
  vnet_definition = {
    name          = "vnet-aiml-hub"
    address_space = "10.0.0.0/16"
  }
  
  tags = {
    Environment = "development"
    Purpose     = "aiml-hub-example"
  }
}

output "ai_ml_config" {
  value = module.example_hub.configuration_for_ai_ml_with_existing_hub
}
EOF

terraform init && terraform apply
```

### Step 2: Get Hub Configuration
```bash
# Extract configuration for AI/ML Landing Zone
terraform output -json ai_ml_config > hub-config.json

# View the configuration
cat hub-config.json | jq '.'
```

### Step 3: Configure AI/ML Landing Zone
Use the output values in your `terraform.tfvars`:

```hcl
# Generated from hub deployment output
existing_hub_resource_group_name = "rg-aiml-hub-example"
existing_hub_vnet_name           = "vnet-aiml-hub" 
hub_dns_servers                  = ["10.0.4.4"]  # From hub DNS resolver
hub_firewall_ip_address          = "10.0.2.4"   # From hub firewall

existing_private_dns_zones = {
  resource_group_name          = "rg-aiml-hub-example"
  blob_zone_name               = "privatelink.blob.core.windows.net"
  vault_zone_name              = "privatelink.vaultcore.azure.net"
  search_zone_name             = "privatelink.search.windows.net"
  cosmos_zone_name             = "privatelink.documents.azure.com"
  cognitive_zone_name          = "privatelink.cognitiveservices.azure.com"
  # Add other zones as needed
}
```

### Step 4: Deploy AI/ML Landing Zone
```bash
cd /path/to/examples/with-existing-hub
terraform init && terraform plan && terraform apply
```

> **💡 Tip**: The example hub module creates all necessary infrastructure including firewall rules, DNS resolver, and private DNS zones specifically designed for AI/ML workloads.
```

The sample hub includes:
- **Azure Firewall** with AI/ML service rules
- **DNS Private Resolver** for hybrid connectivity  
- **Private DNS Zones** for Azure AI/ML services
- **Route Tables** configured for hub-spoke topology
- **Complete ALZ compliance** following Microsoft best practices

For detailed information, see the [Sample Hub README](../sample-hub/README.md).

## Quick Start

1. **Clone and Navigate**:
   ```bash
   git clone <repository-url>
   cd examples-new/with-existing-hub
   ```

2. **Configure Variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your hub network details
   ```

3. **Initialize and Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `existing_hub_resource_group_name` | Hub VNet resource group | `"rg-connectivity-eastus2"` |
| `existing_hub_vnet_name` | Hub VNet name | `"vnet-hub-eastus2"` |
| `location` | Azure region | `"East US 2"` |
| `name_prefix` | Resource name prefix | `"aiml"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ai_lz_vnet_address_space` | AI/ML LZ VNet CIDR | `"192.168.0.0/23"` |
| `hub_dns_servers` | Hub DNS servers | `[]` (Azure default) |
| `create_reverse_peering` | Create hub-to-AI/ML peering | `false` |
| `existing_private_dns_zones` | Use existing DNS zones | `null` (create new) |

### Hub Integration Settings

The `enable_hub_peering_settings` variable controls VNet peering behavior:

```hcl
enable_hub_peering_settings = {
  allow_forwarded_traffic       = true   # Allow traffic forwarding through hub
  use_remote_gateways          = false  # Use hub's VPN/ExpressRoute gateways
  allow_gateway_transit_on_hub = true   # Allow future gateway usage
}
```

### Private DNS Zones

You can either create new private DNS zones or use existing ones from your hub. **Using existing zones from the hub is the recommended enterprise pattern** as it provides centralized DNS management.

**Use Existing Zones from Hub** (recommended):
```hcl
existing_private_dns_zones = {
  resource_group_name = "rg-connectivity-eastus2"  # Hub resource group
  blob_zone_name      = "privatelink.blob.core.windows.net"
  file_zone_name      = "privatelink.file.core.windows.net"
  queue_zone_name     = "privatelink.queue.core.windows.net"
  table_zone_name     = "privatelink.table.core.windows.net"
  vault_zone_name     = "privatelink.vaultcore.azure.net"
  search_zone_name    = "privatelink.search.windows.net"
  cosmos_zone_name    = "privatelink.documents.azure.com"
  cognitive_zone_name = "privatelink.cognitiveservices.azure.com"
  openai_zone_name    = "privatelink.openai.azure.com"
  container_registry_zone_name = "privatelink.azurecr.io"
}
```

**Create New Zones** (for isolated deployments):
```hcl
existing_private_dns_zones = {
  resource_group_name = null  # Creates new zones in AI/ML LZ resource group
  # All other zone names can be null
}
```

> **⚠️ Important**: If using existing zones from the hub, ensure:
> 1. The zones exist in the hub resource group
> 2. Your service principal has `Private DNS Zone Contributor` role on the hub resource group
> 3. The hub VNet is already linked to these zones
> 4. The AI/ML Landing Zone VNet will be automatically linked to these zones

## Network Design

```
Hub Network (10.0.0.0/16)
├── Hub Subnets
├── Firewall/NVA
├── DNS Servers
└── Peered to AI/ML LZ

AI/ML Landing Zone (192.168.0.0/23)
├── Private Endpoints Subnet (192.168.0.0/25)
├── Compute Subnet (192.168.0.128/25)
└── Peered to Hub
```

## Security Features

- **Private Endpoints**: All AI services use private connectivity
- **Network Isolation**: Dedicated subnets with proper segmentation
- **Hub Integration**: Leverages existing firewall and security policies
- **DNS Resolution**: Proper private DNS integration for service discovery
- **Access Control**: Inherits hub network access controls

## Enterprise Security Model

### **Conditional Access Controls**
This deployment implements **enterprise-grade conditional access** that limits the spoke service principal's ability to modify hub infrastructure:

### **Custom Roles with Minimal Privileges**
- **AI-ML-Hub-Spoke-Integration**: VNet peering operations only (cannot modify hub VNet)
- **AI-ML-Private-DNS-Integration**: DNS zone linking only (cannot create/delete DNS zones)
- **Reader**: Hub resource discovery only (no modification rights)

### **What the Spoke Service Principal CAN Do**
✅ Create VNet peering from spoke to hub  
✅ Link spoke VNet to existing private DNS zones  
✅ Read hub VNet and DNS zone properties  
✅ Discover hub resources for integration  

### **What the Spoke Service Principal CANNOT Do**  
❌ Modify hub VNet configuration  
❌ Create, delete, or modify private DNS zones  
❌ Access hub compute, storage, or other resources  
❌ Change hub security settings or policies  
❌ Modify hub routing or firewall rules  

### **Configure Enterprise Permissions**
```bash
# Run with minimal privileges (recommended)
./scripts/configure-cross-subscription-permissions.sh \
  808c8f6e-4a1c-417e-9a77-db2619ce3d1a \
  f8a5f387-2f0b-42f5-b71f-5ee02b8967cf \
  2b808f3b-42ea-4d62-beae-6731c227c59c \
  rg-hub-eus2-byx4af \
  vnet-hub-eus2-byx4af \
  minimal
```

### **Enterprise Documentation**
- **Complete Workflow**: [../../docs/ENTERPRISE-HUB-SPOKE-WORKFLOW.md](../../docs/ENTERPRISE-HUB-SPOKE-WORKFLOW.md)
- **Platform Team Guide**: [../../docs/PLATFORM-TEAM-QUICK-REFERENCE.md](../../docs/PLATFORM-TEAM-QUICK-REFERENCE.md)

## Deployment Scenarios

### Scenario 1: Basic Integration (Default)

- Creates AI/ML LZ with peering to existing hub
- Creates new private DNS zones in AI/ML LZ resource group
- Uses Azure default DNS servers
- Requires minimal permissions on hub

### Scenario 2: Full Integration

- Uses existing private DNS zones from hub
- Configures hub DNS servers
- Creates bidirectional VNet peering
- Requires broader permissions on hub

### Scenario 3: Cross-Subscription (Enterprise Pattern)

- **Hub**: Deployed in connectivity subscription (platform team managed)
- **AI/ML LZ**: Deployed in application subscription (application team managed)  
- Uses service principal with cross-subscription permissions
- Leverages existing hub infrastructure
- Follows Azure Landing Zone subscription organization patterns

## Permissions Required

### Cross-Subscription Permissions (Enterprise Pattern):

**In Connectivity Subscription (Hub):**
- Network Contributor on hub VNet (for VNet peering)
- Private DNS Zone Contributor on existing DNS zones (if using existing zones)
- Reader on hub resource groups

**In Application Subscription (AI/ML LZ):**
- Contributor on AI/ML LZ resource group
- Network Contributor for VNet creation and peering

### Single Subscription Permissions:
- Contributor on both hub and AI/ML LZ resource groups
- Network Contributor for VNet peering

## Outputs

| Output | Description |
|--------|-------------|
| `ai_ml_resource_group_name` | AI/ML LZ resource group |
| `ai_ml_virtual_network_id` | AI/ML LZ VNet resource ID |
| `hub_virtual_network_id` | Hub VNet resource ID |
| `vnet_peering_id` | VNet peering resource ID |
| `reverse_vnet_peering_id` | Reverse peering ID (if created) |
| `private_dns_zones` | DNS zone information |

## Troubleshooting

### Common Issues

1. **Peering Permission Errors**:
   ```
   Error: insufficient permissions on hub VNet
   ```
   Solution: Ensure service principal has Network Contributor on hub VNet

2. **Address Space Conflicts**:
   ```
   Error: overlapping address spaces
   ```
   Solution: Adjust `ai_lz_vnet_address_space` to avoid conflicts

3. **DNS Resolution Issues**:
   ```
   Error: cannot resolve private endpoints
   ```
   Solution: Verify DNS zone linking and hub DNS configuration

### Validation Steps

1. **Verify Connectivity**:
   ```bash
   # From a VM in AI/ML LZ, test connectivity to hub
   ping <hub_internal_resource>
   ```

2. **Test DNS Resolution**:
   ```bash
   # Test private endpoint DNS resolution
   nslookup <storage_account>.blob.core.windows.net
   ```

3. **Validate Peering**:
   ```bash
   # Check peering status
   az network vnet peering show --resource-group <rg> --vnet-name <vnet> --name <peering>
   ```

## Cost Considerations

- VNet peering incurs ingress/egress charges
- Private endpoints have hourly charges
- Consider data transfer costs between regions
- Leverage existing hub infrastructure to reduce costs

## Best Practices

1. **Address Planning**: Coordinate with network team for address space allocation
2. **DNS Strategy**: Use existing private DNS zones when possible
3. **Security**: Implement least-privilege access principles
4. **Monitoring**: Set up network monitoring and alerting
5. **Documentation**: Document network integration for operations team

## Migration from Standalone

If migrating from standalone to hub integration:

1. Create hub peering
2. Update DNS configuration
3. Migrate to private endpoints
4. Update security groups and policies
5. Test connectivity thoroughly

## Next Steps

After deployment:

1. Configure AI model deployments
2. Set up development environments
3. Implement CI/CD pipelines
4. Configure monitoring and alerting
5. Train teams on enterprise integration patterns

## Support

For issues or questions:
- Check the [main repository documentation](../../README.md)
- Review Azure networking documentation
- Consult with platform team for hub-specific configurations
- Open an issue in the repository