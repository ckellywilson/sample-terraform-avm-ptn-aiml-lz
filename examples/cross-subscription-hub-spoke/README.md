# Scenario 1: Cross-Subscription Hub-Spoke Landing Zone

## Overview
This scenario demonstrates the enterprise-grade hub-spoke architecture where the hub (connectivity subscription) provides shared services including private DNS zones, while the AI/ML workload is deployed in a separate application landing zone subscription.

## Architecture
```
📦 Hub Subscription (Connectivity)          📦 Spoke Subscription (Application)
├── 🌐 Hub VNet (10.0.0.0/16)             └── 🤖 AI/ML VNet (10.10.0.0/16)
│   ├── Azure Firewall                         ├── AI Foundry Hub & Projects
│   ├── VPN/ExpressRoute Gateway               ├── Supporting Services
│   ├── Bastion Host                           ├── Private Endpoints
│   └── Shared Services                        └── NSGs & Route Tables
└── 🔗 Private DNS Zones
    ├── privatelink.api.azureml.ms          🔗 VNet Peering
    ├── privatelink.notebooks.azure.net        └── Cross-subscription connectivity
    └── Other privatelink zones
```

## Key Configuration
- `flag_platform_landing_zone = true`
- `deployment_pattern = "cross-subscription-hub-spoke"`
- Cross-subscription provider configuration
- VNet peering to hub subscription
- DNS zone linking from hub

## Deployment
```bash
cd examples/cross-subscription-hub-spoke
terraform init
terraform plan
terraform apply
```

## Benefits
✅ **Enterprise Scale**: Supports large-scale, multi-workload deployments  
✅ **Centralized Governance**: Hub provides consistent security and compliance  
✅ **Cost Optimization**: Shared infrastructure reduces per-workload costs  
✅ **Hybrid Connectivity**: Centralized on-premises integration  
✅ **Security**: Network segmentation with centralized monitoring  
✅ **DNS Management**: Unified private DNS resolution across workloads  

## Use Cases
🎯 **Enterprise Production**: Large organizations with multiple AI/ML teams  
🎯 **Regulated Industries**: Banking, healthcare, government requiring centralized control  
🎯 **Multi-Tenant Platforms**: ISVs providing AI services to multiple customers  
🎯 **Hybrid Scenarios**: Integration with on-premises data and systems  
🎯 **DevOps at Scale**: Multiple environments (dev/staging/prod) across teams  

## Prerequisites
- Hub subscription with connectivity landing zone deployed
- Cross-subscription RBAC permissions configured
- Network connectivity between subscriptions established
- Private DNS zones deployed in hub subscription

## Security Considerations
- Cross-subscription service principals require specific RBAC roles
- Network security groups control traffic between hub and spoke
- Private endpoints ensure all traffic stays within Azure backbone
- Azure Firewall in hub can control outbound internet access

## Networking Details
- **VNet Peering**: Bidirectional peering between hub and spoke VNets
- **Route Tables**: Custom routes for traffic inspection via hub
- **DNS Resolution**: Automatic forwarding to hub-hosted private DNS zones
- **Private Endpoints**: Created in spoke, registered in hub DNS zones

## This is the Recommended Pattern for Enterprise Deployments
This cross-subscription hub-spoke pattern represents Azure best practices for enterprise AI/ML deployments, providing the optimal balance of governance, security, cost optimization, and operational efficiency.

## Deployment Order
1. Deploy Hub infrastructure (if not existing)
2. Deploy Spoke Azure AI Foundry infrastructure
3. Configure VNet peering and DNS zone links
4. Validate connectivity and DNS resolution