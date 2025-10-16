# Sample Hub Infrastructure for AI/ML Landing Zone

This directory provides a complete sample hub infrastructure using the official Azure Landing Zone (ALZ) Terraform Azure Verified Modules. This hub can be used with the [with-existing-hub](../with-existing-hub/) AI/ML Landing Zone example.

## Overview

This sample hub creates a production-ready hub network infrastructure following Azure Landing Zone best practices, including:

- **Hub Virtual Network** using ALZ AVM
- **Azure Firewall** with rules optimized for AI/ML services
- **DNS Private Resolver** for hybrid name resolution
- **Private DNS Zones** for Azure AI/ML services
- **Route Tables** configured for hub-spoke topology

> **🏢 Enterprise Deployment Pattern**: This hub infrastructure is typically deployed in a separate **connectivity subscription**, while the AI/ML Landing Zone (from [with-existing-hub](../with-existing-hub/)) is deployed in an **application subscription**. This follows Azure Landing Zone best practices for subscription organization and governance.

## Architecture

```
┌─────────────────────────────────────────┐
│               Hub VNet                  │
│           10.0.0.0/16                  │
│                                         │
│ ┌─────────────────┐ ┌─────────────────┐ │
│ │ Azure Firewall  │ │ DNS Private     │ │
│ │ Subnet          │ │ Resolver        │ │
│ │ 10.0.0.0/24    │ │ 10.0.4.0/24    │ │
│ └─────────────────┘ └─────────────────┘ │
│                                         │
│ ┌─────────────────┐ ┌─────────────────┐ │
│ │ Gateway Subnet  │ │ Shared Services │ │
│ │ 10.0.1.0/24    │ │ 10.0.3.0/24    │ │
│ └─────────────────┘ └─────────────────┘ │
│                                         │
│ ┌─────────────────┐                     │
│ │ Bastion Subnet  │                     │
│ │ 10.0.2.0/24    │                     │
│ └─────────────────┘                     │
└─────────────────────────────────────────┘
```

## Quick Start

### 1. Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your specific values
vim terraform.tfvars
```

### 2. Deploy Hub Infrastructure

```bash
# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy infrastructure
terraform apply
```

### 3. Get Configuration for AI/ML Landing Zone

After deployment, get the configuration values needed for the AI/ML Landing Zone:

```bash
# Display configuration for with-existing-hub example
terraform output configuration_for_ai_ml_landing_zone
```

### 4. Deploy AI/ML Landing Zone (in Application Subscription)

Use the output values to configure the [with-existing-hub](../with-existing-hub/) example in your **application subscription**:

```bash
cd ../with-existing-hub

# Configure Terraform provider for application subscription
# Update provider configuration if using different subscription
export ARM_SUBSCRIPTION_ID="<application-subscription-id>"

# Create terraform.tfvars using the hub output values
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with values from hub output

terraform init
terraform plan
terraform apply
```

> **📋 Cross-Subscription Deployment**: Ensure your service principal or user account has appropriate permissions in both the connectivity subscription (for hub) and application subscription (for AI/ML LZ).

## Cross-Subscription Deployment

### Typical Enterprise Setup

```
┌─────────────────────────────────────┐  ┌─────────────────────────────────────┐
│    Connectivity Subscription        │  │     Application Subscription        │
│                                     │  │                                     │
│  ┌─────────────────────────────────┐ │  │  ┌─────────────────────────────────┐ │
│  │         Hub Network             │ │  │  │      AI/ML Landing Zone         │ │
│  │                                 │ │  │  │                                 │ │
│  │  • Azure Firewall              │ │  │  │  • AI/ML Services              │ │
│  │  • DNS Private Resolver        │ │  │  │  • Private Endpoints           │ │
│  │  • Private DNS Zones           │ │  │  │  • Compute Resources           │ │
│  │  • Route Tables                │ │  │  │  • Storage Accounts            │ │
│  └─────────────────────────────────┘ │  │  └─────────────────────────────────┘ │
│                                     │  │                                     │
│  Managed by Platform Team          │  │  Managed by Application Team       │
└─────────────────────────────────────┘  └─────────────────────────────────────┘
                    │                                        │
                    └──────── VNet Peering ─────────────────┘
```

### Deployment Steps for Cross-Subscription

1. **Deploy Hub (Connectivity Subscription)**:
   ```bash
   # Set connectivity subscription
   export ARM_SUBSCRIPTION_ID="<connectivity-subscription-id>"
   
   # Deploy hub infrastructure
   cd examples/sample-hub
   terraform init && terraform apply
   ```

2. **Deploy AI/ML LZ (Application Subscription)**:
   ```bash
   # Set application subscription  
   export ARM_SUBSCRIPTION_ID="<application-subscription-id>"
   
   # Deploy AI/ML landing zone
   cd ../with-existing-hub
   terraform init && terraform apply
   ```

## Configuration

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `location` | Azure region | `"East US 2"` |
| `hub_address_space` | Hub VNet CIDR | `"10.0.0.0/16"` |
| `ai_ml_address_space` | AI/ML spoke CIDR (for firewall rules) | `"192.168.0.0/22"` |
| `firewall_sku` | Azure Firewall tier | `"Standard"` |
| `create_private_dns_zones` | Create DNS zones in hub | `true` |

### Environment Examples

**Development:**
```hcl
firewall_sku = "Basic"              # ~$268/month
hub_address_space = "10.10.0.0/24"  # Smaller space
create_log_analytics = false        # Reduce costs
```

**Production:**
```hcl
firewall_sku = "Premium"            # ~$899/month
create_log_analytics = true         # Enhanced monitoring
custom_dns_servers = ["10.0.1.4"]  # Custom DNS
```

## Features

### Azure Firewall Rules

Pre-configured rules for AI/ML services:
- Azure AI Services (Cognitive Services, OpenAI)
- Azure Storage (blob, file, queue, table)
- Azure Key Vault
- Azure Search
- Azure Cosmos DB
- Package managers (PyPI, Conda, Ubuntu)

### Private DNS Zones

Centralized DNS zones for:
- `privatelink.blob.core.windows.net`
- `privatelink.vaultcore.azure.net`
- `privatelink.search.windows.net`
- `privatelink.documents.azure.com`
- `privatelink.cognitiveservices.azure.com`
- Additional zones for AI/ML services

### Network Infrastructure

- **DNS Private Resolver**: Hybrid DNS resolution
- **Route Tables**: Direct spoke traffic through firewall
- **Network Security**: Zone-redundant firewall deployment
- **Scalability**: Room for multiple AI/ML landing zones

## Costs

### Estimated Monthly Costs (East US 2)

| Component | Basic | Standard | Premium |
|-----------|-------|----------|---------|
| **Azure Firewall** | ~$268 | ~$693 | ~$899 |
| **DNS Private Resolver** | ~$36 | ~$36 | ~$36 |
| **Virtual Network** | Free | Free | Free |
| **Private DNS Zones** | ~$5 | ~$5 | ~$5 |
| **Public IP** | ~$4 | ~$4 | ~$4 |
| **Total** | **~$313** | **~$738** | **~$944** |

> **Cost Optimization:**
> - Use Basic tier for development/testing
> - Consider Azure Firewall PAYG model for non-production
> - Shared hub reduces overall infrastructure costs

## Integration with AI/ML Landing Zone

After deploying this hub, use the `configuration_for_ai_ml_landing_zone` output to configure the with-existing-hub example:

```bash
# Get the configuration
terraform output -json configuration_for_ai_ml_landing_zone

# Example output:
{
  "existing_hub_resource_group_name": "rg-hub-eus2-abc123",
  "existing_hub_vnet_name": "vnet-hub-eus2-abc123",
  "hub_dns_servers": ["10.0.4.4"],
  "firewall_ip_address": "10.0.0.4",
  "existing_private_dns_zones": {
    "resource_group_name": "rg-hub-eus2-abc123",
    "blob_zone_name": "privatelink.blob.core.windows.net",
    "vault_zone_name": "privatelink.vaultcore.azure.net",
    "search_zone_name": "privatelink.search.windows.net",
    "cosmos_zone_name": "privatelink.documents.azure.com",
    "cognitive_zone_name": "privatelink.cognitiveservices.azure.com"
  }
}
```

## Monitoring and Operations

### Built-in Monitoring
- Azure Firewall metrics and logs
- DNS Private Resolver metrics
- Virtual Network flow logs (when enabled)
- Cost Management integration

### Recommended Additions
```hcl
# Enable Log Analytics workspace
create_log_analytics = true

# Add monitoring for firewall
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "firewall-diagnostics"
  target_resource_id         = azurerm_firewall.hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub[0].id
  
  enabled_log {
    category = "AzureFirewallApplicationRule"
  }
  
  enabled_log {
    category = "AzureFirewallNetworkRule"
  }
  
  metric {
    category = "AllMetrics"
  }
}
```

## Security Considerations

### Network Security
- All traffic from spokes routed through firewall
- Private DNS zones prevent DNS exfiltration
- Zone-redundant deployment for high availability
- Network security groups on all subnets

### Access Control
- Firewall rules follow least-privilege principle
- Private DNS zones limit external resolution
- Route tables enforce traffic inspection
- Application rules for specific AI/ML FQDNs

### Compliance
- Diagnostic logging enabled for audit trails
- Resource tagging for governance
- Private endpoints support for data sovereignty
- Network segmentation for workload isolation

## Troubleshooting

### Common Issues

1. **Address Space Conflicts**
   ```
   Error: The CIDR overlaps with existing address space
   ```
   Solution: Update `hub_address_space` or `ai_ml_address_space`

2. **Firewall Deployment Timeout**
   ```
   Error: creating Azure Firewall: timeout waiting for completion
   ```
   Solution: Firewall deployment can take 10-15 minutes, increase timeout

3. **DNS Resolution Issues**
   ```
   Error: DNS queries not resolving properly
   ```
   Solution: Verify DNS private resolver configuration and VNet links

### Validation Commands

```bash
# Check hub resources
az network vnet show --name <hub-vnet-name> --resource-group <hub-rg>

# Verify firewall status
az network firewall show --name <firewall-name> --resource-group <hub-rg>

# Test DNS resolution
nslookup test.privatelink.blob.core.windows.net <dns-resolver-ip>
```

## Best Practices

### 🏗️ Infrastructure
- Use consistent naming conventions with location and environment
- Implement proper tagging for cost tracking and governance
- Plan address spaces carefully to avoid future conflicts
- Enable diagnostic logging for security and troubleshooting

### 🔒 Security
- Review and customize firewall rules for your specific requirements
- Implement least-privilege access principles
- Enable advanced threat protection (Premium firewall)
- Regular security assessments and rule reviews

### 💰 Cost Management
- Right-size firewall tier based on throughput requirements
- Use Basic tier for development environments
- Monitor firewall rule hit counts to optimize rules
- Implement cost alerts and budgets

### 📊 Operations
- Set up comprehensive monitoring and alerting
- Document network dependencies and configurations
- Plan for disaster recovery and backup procedures
- Establish change management processes

## Advanced Configuration

### Multiple AI/ML Landing Zones

To support multiple AI/ML landing zones, update the firewall rules:

```hcl
ai_ml_address_space = "192.168.0.0/20"  # Larger space for multiple spokes
```

### Cross-Region Connectivity

For multi-region deployments:

```hcl
# Regional hub configuration
location = "West Europe"
location_short = "weu"
hub_address_space = "10.1.0.0/16"  # Different region addressing
```

### Hybrid Connectivity

Add VPN Gateway or ExpressRoute:

```hcl
# Uncomment and configure in main.tf
# module "vpn_gateway" {
#   source = "Azure/avm-res-network-vpngateway/azurerm"
#   ...
# }
```

## Support

For issues or questions:
- Review the [main AI/ML Landing Zone documentation](../../README.md)
- Check Azure Firewall and networking documentation
- Consult Azure Landing Zone best practices
- Open an issue in the repository

---

This sample hub provides a solid foundation for enterprise AI/ML workloads while following Azure Landing Zone patterns and best practices.