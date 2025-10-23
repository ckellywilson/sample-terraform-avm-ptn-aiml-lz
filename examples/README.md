# AI/ML Landing Zone Examples

This directory contains practical deployment examples for the Azure AI/ML Landing Zone pattern following Azure Verified Module (AVM) best practices. Each example represents a different deployment scenario with complete, production-ready configurations.

## Available Examples

### 🏗️ [Default](./default/)
**Hub-Spoke with Example Hub**

Complete deployment including both a simple hub network and AI/ML landing zone with VNet peering. Ideal for development, testing, and learning scenarios.

- **Use Case**: Development, proof-of-concept, learning
- **Complexity**: Medium
- **Dependencies**: None (self-contained)
- **Network**: Creates example hub + AI/ML LZ with peering

### 🚀 [Standalone](./standalone/)
**Self-Contained AI/ML Environment**

Standalone AI/ML landing zone without any hub network dependencies. Perfect for isolated workloads or when enterprise hub integration isn't required.

- **Use Case**: Isolated workloads, small teams, rapid prototyping
- **Complexity**: Low
- **Dependencies**: None
- **Network**: Single VNet with public service access

## 🛠️ [Shared Scripts](./scripts/)
**Common Utilities for All Examples**

Centralized collection of deployment and operational scripts used across all example scenarios.

- **Prerequisites Validation**: Azure resource provider and feature checks
- **Resource Management**: Automated provider registration
- **Security Hardening**: Post-deployment storage account security
- **CI/CD Integration**: Cross-platform deployment scripts

### 🔗 [Sample Hub](./sample-hub/)
**ALZ-based Hub Infrastructure**

Creates a production-ready hub network using official Azure Landing Zone (ALZ) Terraform Azure Verified Modules. Use this to create a sample hub for testing the with-existing-hub scenario.

- **Use Case**: Hub creation for testing, development, or production
- **Complexity**: Medium
- **Dependencies**: None
- **Network**: Complete hub with firewall, DNS resolver, and private DNS zones

### 🏢 [With Existing Hub](./with-existing-hub/)
**Enterprise Hub Integration**

Integrates AI/ML landing zone with existing platform hub network infrastructure. Most common enterprise scenario with full private connectivity.

- **Use Case**: Enterprise production, existing platform LZ
- **Complexity**: High
- **Dependencies**: Existing hub network, proper permissions
- **Network**: Peering to existing hub, private endpoints

> **💡 Need a Hub Network?** Use the [Sample Hub](./sample-hub/) example to create a production-ready hub infrastructure using official Azure Landing Zone Terraform modules.

## Deployment Patterns Comparison

| Feature | Default | Standalone | Sample Hub | With Existing Hub |
|---------|---------|------------|------------|-------------------|
| **Hub Network** | ✅ Creates example | ❌ None | ✅ Creates ALZ hub | ✅ Uses existing |
| **VNet Peering** | ✅ Automatic | ❌ None | N/A (hub only) | ✅ Manual config |
| **Private Endpoints** | ✅ Yes | ❌ Public access | N/A (hub only) | ✅ Yes |
| **DNS Integration** | ✅ New zones | ❌ Public DNS | ✅ Creates zones | ✅ Existing zones |
| **Enterprise Ready** | ⚠️ Dev/Test | ❌ No | ✅ Yes | ✅ Yes |
| **Setup Complexity** | 🟡 Medium | 🟢 Low | � Medium | �🔴 High |
| **Prerequisites** | None | None | None | Hub network |

## Subscription Organization

Following Azure Landing Zone best practices, different components are typically deployed in separate subscriptions:

| Component | Subscription Type | Managed By | Examples |
|-----------|------------------|------------|----------|
| **Hub Infrastructure** | Connectivity | Platform Team | `sample-hub/` |
| **AI/ML Landing Zone** | Application | Application Team | `default/`, `standalone/`, `with-existing-hub/` |

> **🏢 Enterprise Pattern**: Deploy the hub in a connectivity subscription and AI/ML workloads in application subscriptions. This provides proper separation of concerns and governance boundaries.

## Quick Start Guide

### 1. Choose Your Pattern

```bash
# For learning and development
cd default/

# For isolated workloads
cd standalone/

# For creating a production hub (connectivity subscription)
cd sample-hub/

# For enterprise integration (application subscription)
cd with-existing-hub/
```

### 2. Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your specific values
vim terraform.tfvars
```

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

## Architecture Overview

### Default Pattern
```
┌─────────────────┐    ┌─────────────────────┐
│   Example Hub   │◄──►│   AI/ML Landing     │
│   10.10.0.0/24  │    │   Zone              │
│                 │    │   192.168.0.0/23    │
│ • Hub Subnet    │    │ • Private Endpoints │
│ • Basic NSG     │    │ • Compute Subnet    │
└─────────────────┘    │ • AI Services       │
                       └─────────────────────┘
```

### Standalone Pattern
```
┌─────────────────────────────────┐
│         AI/ML Landing Zone      │
│         192.168.0.0/22          │
│                                 │
│ • Private Endpoints Subnet      │
│ • Compute Subnet               │
│ • Web Subnet                   │
│ • AI Services (Public Access)  │
│ • Network Security Groups      │
└─────────────────────────────────┘
```

### With Existing Hub Pattern
```
┌─────────────────┐    ┌─────────────────────┐
│  Existing Hub   │◄──►│   AI/ML Landing     │
│  10.0.0.0/16    │    │   Zone              │
│                 │    │   192.168.0.0/23    │
│ • Firewall      │    │ • Private Endpoints │
│ • DNS Servers   │    │ • Compute Subnet    │
│ • Private Zones │    │ • AI Services       │
│ • ExpressRoute  │    │ • Hub Integration   │
└─────────────────┘    └─────────────────────┘
```

## Common Configuration

### Required Variables (All Examples)

```hcl
# Basic configuration required for all examples
location    = "East US 2"        # Azure region
name_prefix = "aiml"             # Resource naming prefix (≤10 chars)

# Tags applied to all resources
tags = {
  Environment = "dev"
  Project     = "ai-ml-landing-zone"  
  ManagedBy   = "terraform"
}
```

### Network Address Planning

Choose non-overlapping address spaces based on your pattern:

```hcl
# Default pattern
hub_vnet_address_space    = "10.10.0.0/24"    # Example hub
ai_lz_vnet_address_space = "192.168.0.0/23"   # AI/ML LZ

# Standalone pattern  
ai_lz_vnet_address_space = "192.168.0.0/22"   # Larger space

# With existing hub pattern
ai_lz_vnet_address_space = "192.168.0.0/23"   # Coordinate with hub team
```

## AI/ML Services Included

All examples deploy these core AI/ML services:

| Service | Purpose | SKU |
|---------|---------|-----|
| **Storage Account** | Datasets, models, artifacts | Standard LRS |
| **Key Vault** | Secrets, keys, certificates | Standard |
| **AI Services** | Cognitive APIs, model hosting | S0 |
| **AI Search** | Vector search, knowledge mining | Standard |
| **Cosmos DB** | NoSQL database for AI apps | Standard |
| **Application Insights** | Application monitoring | Web |

### Additional Services by Pattern

| Service | Default | Standalone | With Existing Hub |
|---------|---------|------------|-------------------|
| **Hub VNet** | ✅ Creates | ❌ None | ✅ Uses existing |
| **Private DNS Zones** | ✅ Creates | ❌ Not needed | ✅ Creates or uses existing |
| **Private Endpoints** | ✅ Yes | ❌ Public | ✅ Yes |
| **Log Analytics** | ❌ No | ✅ Yes | ❌ Use hub |
| **Network Security Groups** | ✅ Basic | ✅ Enhanced | ✅ Enterprise |

## Security Considerations

### Default & With Existing Hub
- ✅ Private endpoints for all services
- ✅ Network isolation with dedicated subnets
- ✅ Private DNS resolution
- ✅ VNet peering for secure connectivity
- ⚠️ Key Vault access policies need customization

### Standalone
- ⚠️ Public access enabled for simplicity
- ✅ Network security groups configured
- ✅ Subnet segmentation implemented
- ❌ No private endpoints (cost optimization)
- ⚠️ Suitable for dev/test only

## Cost Optimization

### Development/Testing
- Use **Standalone** pattern for lowest cost
- Scale down AI Services SKUs
- Use consumption-based pricing where available
- Implement auto-shutdown for compute resources

### Production
- Use **With Existing Hub** to leverage existing infrastructure
- Implement reserved instances for predictable workloads
- Monitor and optimize data transfer costs
- Use lifecycle policies for storage management

## Migration Paths

### Standalone → With Existing Hub
1. Create VNet peering to hub
2. Deploy private endpoints
3. Update DNS configuration  
4. Migrate workloads
5. Disable public access

### Default → With Existing Hub
1. Update peering to production hub
2. Migrate DNS zones to hub management
3. Update security policies
4. Remove example hub infrastructure

## Monitoring and Operations

### Built-in Monitoring
- Application Insights for application telemetry
- Log Analytics workspace (where applicable)
- Azure Monitor metrics for all services
- Cost Management integration

### Recommended Additions
```hcl
# Add to any example for enhanced monitoring
resource "azurerm_monitor_action_group" "alerts" {
  name                = "${local.prefix}-alerts"
  resource_group_name = azurerm_resource_group.ai_ml.name
  short_name          = "aiml-alerts"
  
  email_receiver {
    name          = "admin"
    email_address = "admin@yourcompany.com"
  }
}
```

## Troubleshooting

### Common Issues

1. **Address Space Conflicts**
   ```
   Error: overlapping CIDR ranges
   ```
   Solution: Update address spaces in variables

2. **Permission Errors** 
   ```
   Error: insufficient permissions
   ```
   Solution: Verify Azure RBAC assignments

3. **DNS Resolution**
   ```
   Error: cannot resolve private endpoints
   ```
   Solution: Check DNS zone configuration and VNet links

### Validation Commands

```bash
# Check Terraform state
terraform state list

# Validate configuration  
terraform validate

# Test connectivity (from deployed VM)
ping <private-endpoint-fqdn>

# Check DNS resolution
nslookup <storage-account>.blob.core.windows.net
```

## Best Practices

### 🏗️ Infrastructure
- Use consistent naming conventions
- Implement proper tagging strategy
- Plan network address spaces carefully
- Enable diagnostic logging where needed

### 🔒 Security  
- Follow principle of least privilege
- Use private endpoints in production
- Implement network segmentation
- Enable audit logging

### 💰 Cost Management
- Right-size resources for workload
- Use automation for start/stop schedules
- Monitor usage patterns
- Implement budget alerts

### 📊 Operations
- Set up comprehensive monitoring
- Implement automated backups
- Document network dependencies
- Plan for disaster recovery

## Contributing

When adding new examples:

1. Follow the established directory structure
2. Include complete README.md with architecture diagrams  
3. Provide terraform.tfvars.example with all options
4. Test deployment in clean environment
5. Update this main README.md

## Support

For help with these examples:

- 📚 Review individual example README files
- 🐛 Check [Issues](../../issues) for known problems
- 💬 Start a [Discussion](../../discussions) for questions
- 📧 Contact the platform team for enterprise support

---

**Note**: These examples are designed to be production-ready starting points. Always review and customize configurations for your specific requirements, security policies, and compliance needs.