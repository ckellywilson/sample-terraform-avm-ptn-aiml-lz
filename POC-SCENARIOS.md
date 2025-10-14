# Azure AI/ML Landing Zone - Deployment Scenarios

This repository demonstrates three distinct deployment patterns for Azure AI/ML Landing Zones, following Azure Verified Module (AVM) best practices and covering the full spectrum of organizational needs from enterprise-scale to standalone deployments.

## 🎯 Scenario Comparison Matrix

| Aspect | Default (Example Hub) | Standalone | With Existing Hub |
|--------|----------------------|------------|-------------------|
| **Complexity** | Medium | Low | High |
| **Enterprise Readiness** | 🟡 Dev/Test | ❌ Dev Only | ✅ Production Ready |
| **Cost Efficiency** | 🟡 Moderate | ✅ Optimized | ✅ Leverages existing |
| **Hub Dependency** | ✅ Creates example | ❌ None | ✅ Uses existing |
| **Private Endpoints** | ✅ Yes | ❌ Public access | ✅ Yes |
| **Setup Time** | 🟡 Moderate | ✅ Quick | ❌ Complex |
| **Prerequisites** | None | None | Existing hub network |

## Scenario 1: Default Example ⭐ **RECOMMENDED FOR LEARNING**
- **Location**: `examples/default/`
- **Description**: Complete hub-spoke deployment with example hub network
- **Use Case**: Development, learning, proof-of-concept, testing
- **Key Feature**: Creates both hub and AI/ML landing zone with automatic integration
- **Best For**: Learning Azure landing zone patterns, development environments, POCs

## Scenario 2: Standalone Example
- **Location**: `examples/standalone/`
- **Description**: Self-contained AI/ML environment with single VNet
- **Use Case**: Isolated workloads, rapid prototyping, edge deployments
- **Key Feature**: Complete independence with public service access
- **Best For**: Small teams, rapid prototyping, isolated workloads, cost optimization

## Scenario 3: With Existing Hub Example ⭐ **RECOMMENDED FOR ENTERPRISE**
- **Location**: `examples/with-existing-hub/`
- **Description**: Enterprise-grade integration with existing platform hub
- **Use Case**: Production enterprise deployments with existing platform landing zone
- **Key Feature**: Private endpoints and integration with existing hub infrastructure
- **Best For**: Large organizations, production workloads, regulated industries

## 🚀 Quick Start Guide

### For Learning and Development (Recommended)
```bash
# Complete hub-spoke setup with example hub
cd examples/default
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

### For Standalone Workloads
```bash
# Self-contained deployment
cd examples/standalone
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

### For Enterprise Production (Existing Hub)
```bash
# Integration with existing platform hub
cd examples/with-existing-hub
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with existing hub details
terraform init && terraform apply
```

## 📋 Decision Framework

Choose your scenario based on:

1. **Purpose and Environment**
   - Learning/Development → Default Example
   - Isolated workloads → Standalone Example
   - Enterprise production → With Existing Hub Example

2. **Infrastructure Context**
   - No existing hub → Default Example or Standalone Example
   - Have existing platform hub → With Existing Hub Example
   - Want complete independence → Standalone Example

3. **Complexity Tolerance**
   - Simple and quick → Standalone Example
   - Moderate learning curve → Default Example
   - Complex enterprise integration → With Existing Hub Example

4. **Security Requirements**
   - Basic/Development → Standalone Example (public access)
   - Enhanced → Default Example (private endpoints)
   - Enterprise-grade → With Existing Hub Example (full enterprise integration)

## 🔧 Configuration Patterns

### Default Example:
```hcl
# Creates example hub network
hub_vnet_address_space = "10.10.0.0/24"
ai_lz_vnet_address_space = "192.168.0.0/23"

# Automatic VNet peering and private endpoints
# Complete hub-spoke integration for learning
```

### Standalone Example:
```hcl
# Self-contained single VNet
ai_lz_vnet_address_space = "192.168.0.0/22"  # Larger address space

# Public access enabled for simplicity
# No hub dependencies or external integrations
```

### With Existing Hub Example:
```hcl
# References existing hub infrastructure
existing_hub_resource_group_name = "rg-connectivity-eastus2"
existing_hub_vnet_name = "vnet-hub-eastus2"

# Optional: Use existing private DNS zones
existing_private_dns_zones = {
  resource_group_name = "rg-connectivity-eastus2"
  blob_zone_name      = "privatelink.blob.core.windows.net"
  # ... other existing zones
}
```

## Implementation Status
- ✅ **Default Example**: Complete implementation with example hub and comprehensive documentation
- ✅ **Standalone Example**: Complete self-contained implementation for independent deployments
- ✅ **With Existing Hub Example**: Complete enterprise integration with existing platform infrastructure

All scenarios are production-ready and follow Azure Verified Module best practices.

## Architecture Overview

### Default Example Architecture
```
Example Hub (10.10.0.0/24) ←→ AI/ML LZ (192.168.0.0/23)
├── Hub subnet                 ├── Private endpoints subnet
└── Basic connectivity         ├── Compute subnet
                              └── Private AI services
```

### Standalone Example Architecture
```
AI/ML Landing Zone (192.168.0.0/22)
├── Private endpoints subnet
├── Compute subnet
├── Web subnet
└── Public AI services (dev-friendly)
```

### With Existing Hub Example Architecture
```
Existing Hub (10.0.0.0/16) ←→ AI/ML LZ (192.168.0.0/23)
├── Firewall/NVA              ├── Private endpoints subnet
├── DNS servers               ├── Compute subnet
├── Private DNS zones         └── Enterprise AI services
└── ExpressRoute/VPN
```
```