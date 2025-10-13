# Scenario 3: Standalone Application Landing Zone

## Overview
This scenario deploys a completely self-contained AI/ML workload with no external dependencies. All networking, DNS, and platform services are contained within a single subscription and managed independently.

## Architecture
```
📦 Standalone Subscription
└── 🤖 AI/ML VNet (10.50.0.0/16)
    ├── AI Foundry Hub & Projects
    ├── Supporting Services (Storage, CosmosDB, etc.)
    ├── Private DNS Zones (local)
    ├── Private Endpoints
    └── Network Security Groups
```

## Key Configuration
- `flag_platform_landing_zone = false`
- `deployment_pattern = "standalone"`
- No hub module dependency
- Creates own private DNS zones locally

## Deployment
```bash
cd examples/standalone-application
terraform init
terraform plan
terraform apply
```

## Benefits
✅ **Independence**: No external dependencies or shared services  
✅ **Portability**: Can be deployed anywhere without hub requirements  
✅ **Isolation**: Complete blast radius containment  
✅ **Simplicity**: Single subscription, single team ownership  
✅ **Speed**: No coordination with platform teams required  

## Use Cases
🎯 **Edge Deployments**: Remote locations without hub connectivity  
🎯 **Pilot Projects**: Proof of concepts and experimentation  
🎯 **Isolated Workloads**: High-security or compliance requirements  
🎯 **Partner/Vendor**: Third-party managed environments  
🎯 **Disaster Recovery**: Independent backup environments  

## Trade-offs
❌ **Resource Duplication**: Each workload has its own platform services  
❌ **Management Overhead**: No centralized platform management  
❌ **Cost**: Higher per-workload infrastructure costs  
❌ **Governance**: No centralized policy enforcement  
❌ **Connectivity**: No shared hybrid connectivity  

## When to Use
- **Independent workloads** with no shared service requirements
- **Edge/remote deployments** without hub connectivity
- **High-security scenarios** requiring complete isolation
- **Pilot projects** and experimentation
- **Third-party managed** environments

## Networking Details
- **VNet**: Self-contained with all required subnets
- **DNS**: Local private DNS zones for each service type
- **Security**: Network Security Groups with workload-specific rules
- **Endpoints**: Private endpoints for all PaaS services
- **No VNet Peering**: Completely isolated network

## Cost Considerations
This pattern has higher per-workload costs due to:
- Dedicated private DNS zones per workload
- No shared platform services amortization
- Potential resource over-provisioning for single workloads