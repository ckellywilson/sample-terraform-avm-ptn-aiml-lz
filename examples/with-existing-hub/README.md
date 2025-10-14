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

You can either create new private DNS zones or use existing ones from your hub:

**Create New Zones** (default):
```hcl
existing_private_dns_zones = {
  resource_group_name = null
  blob_zone_name      = null
  # ... other zones null
}
```

**Use Existing Zones**:
```hcl
existing_private_dns_zones = {
  resource_group_name = "rg-connectivity-eastus2"
  blob_zone_name      = "privatelink.blob.core.windows.net"
  vault_zone_name     = "privatelink.vaultcore.azure.net"
  search_zone_name    = "privatelink.search.windows.net"
  cosmos_zone_name    = "privatelink.documents.azure.com"
  cognitive_zone_name = "privatelink.cognitiveservices.azure.com"
}
```

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

### Scenario 3: Cross-Subscription

- AI/ML LZ in different subscription from hub
- Uses service principal with cross-subscription permissions
- Leverages existing hub infrastructure

## Permissions Required

### Minimum Permissions (AI/ML LZ subscription):
- Contributor on AI/ML LZ resource group
- Network Contributor on hub VNet (for peering)

### Full Integration Permissions:
- Network Contributor on hub subscription
- DNS Zone Contributor on existing DNS zones
- Reader on hub resource groups

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