# Scenario 1: Single Subscription Hub-Spoke

## Overview
This scenario deploys both Hub (platform) and Spoke (application) resources within the same Azure subscription but in separate VNets. This is the **simplest** deployment pattern suitable for:

- Small to medium organizations
- Development and testing environments  
- Single team management
- Simplified governance requirements

## Architecture
```
📦 Single Subscription
├── 🏢 Hub VNet (10.1.0.0/24)
│   ├── Private DNS Zones
│   ├── Azure Firewall
│   ├── Bastion Host
│   └── DNS Private Resolver
├── 🔗 VNet Peering
└── 🤖 Spoke VNet (10.0.0.0/16)
    ├── AI Foundry Hub
    ├── AI Projects
    ├── Supporting Services
    └── Private Endpoints
```

## Key Configuration
- `flag_platform_landing_zone = true`
- `deployment_pattern = "hub-spoke"`
- Uses `module.example_hub` for hub resources
- Single subscription context for all resources

## Deployment
```bash
cd examples/single-subscription-hub-spoke
terraform init
terraform plan
terraform apply
```

## Benefits
✅ **Simplicity**: Single subscription, single authentication context  
✅ **Cost**: No cross-subscription data transfer charges  
✅ **Management**: Unified billing and resource management  
✅ **RBAC**: Simplified permission model  

## Limitations
❌ **Governance**: Limited separation between platform and application teams  
❌ **Scaling**: Single subscription limits may be reached faster  
❌ **Blast Radius**: Issues affect both platform and application resources  
❌ **Chargeback**: Difficult to separate platform vs application costs  

## When to Use
- **POC/Development environments**
- **Single team organizations**
- **Simple governance requirements**
- **Cost-optimized scenarios**