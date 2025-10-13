# Azure AI/ML Landing Zone - POC Scenarios

This repository demonstrates three distinct deployment patterns for Azure AI/ML Landing Zones, covering the full spectrum of organizational needs from enterprise-scale to standalone deployments.

## 🎯 Scenario Comparison Matrix

| Aspect | Cross-Subscription Hub-Spoke | Single-Subscription Hub-Spoke | Standalone Application |
|--------|------------------------------|-------------------------------|------------------------|
| **Complexity** | High | Medium | Low |
| **Enterprise Readiness** | ✅ Production Ready | 🟡 Limited Scale | ❌ POC Only |
| **Cost Efficiency** | ✅ Optimized | 🟡 Moderate | ❌ Higher per workload |
| **Governance** | ✅ Centralized | 🟡 Subscription-level | ❌ Workload-level |
| **Isolation** | 🟡 Network segmentation | 🟡 Subnet segmentation | ✅ Complete |
| **Setup Time** | ❌ Complex | 🟡 Moderate | ✅ Quick |

## Scenario 1: Cross-Subscription Hub-Spoke ⭐ **RECOMMENDED**
- **Location**: `examples/cross-subscription-hub-spoke/`
- **Description**: Enterprise-grade hub-spoke architecture with centralized networking
- **Use Case**: Production enterprise deployments
- **Key Feature**: Shared platform services across subscriptions
- **Best For**: Large organizations, regulated industries, multi-tenant platforms

## Scenario 2: Single Subscription Hub-Spoke
- **Location**: `examples/single-subscription-hub-spoke/`
- **Description**: Hub-spoke architecture within a single subscription
- **Use Case**: Mid-size organizations or testing environments
- **Key Feature**: Simplified management with hub benefits
- **Best For**: Organizations testing hub-spoke patterns, limited scope deployments

## Scenario 3: Standalone Application
- **Location**: `examples/standalone-application/`
- **Description**: Self-contained deployment with no external dependencies
- **Use Case**: Independent workloads or edge deployments
- **Key Feature**: Complete isolation and independence
- **Best For**: Edge deployments, pilot projects, isolated workloads

## 🚀 Quick Start Guide

### For Enterprise Production (Recommended)
```bash
# Step 1: Deploy Hub Infrastructure (if needed)
cd examples/hub-connectivity-deployment
terraform init && terraform apply

# Step 2: Deploy AI/ML Spoke
cd ../cross-subscription-hub-spoke
terraform init && terraform apply
```

### For Testing Hub-Spoke Concepts
```bash
cd examples/single-subscription-hub-spoke
terraform init && terraform apply
```

### For Standalone/Edge Deployments
```bash
cd examples/standalone-application
terraform init && terraform apply
```

## 📋 Decision Framework

Choose your scenario based on:

1. **Organizational Size**
   - Enterprise (1000+ users) → Cross-Subscription Hub-Spoke
   - Mid-size (100-1000 users) → Single Subscription Hub-Spoke
   - Small/Edge (<100 users) → Standalone

2. **Compliance Requirements**
   - High (Banking, Healthcare) → Cross-Subscription Hub-Spoke
   - Medium → Single Subscription Hub-Spoke
   - Low → Standalone

3. **Number of AI/ML Workloads**
   - Multiple (>5) → Cross-Subscription Hub-Spoke
   - Few (2-5) → Single Subscription Hub-Spoke
   - Single → Standalone

4. **Operational Maturity**
   - Advanced Platform Teams → Cross-Subscription Hub-Spoke
   - Growing DevOps → Single Subscription Hub-Spoke
   - Application Teams → Standalone

## 🔧 Configuration Patterns

### Cross-Subscription Hub-Spoke:
```hcl
flag_platform_landing_zone = true
# Hub resources in connectivity subscription
# Application resources in workload subscription
# Enterprise-grade separation
```

### Single Subscription Hub-Spoke:
```hcl
flag_platform_landing_zone = true
# Both hub and spoke in same subscription
# Simpler RBAC and billing model
```

### Standalone Application:
```hcl
flag_platform_landing_zone = false
# All resources self-contained in one subscription
# No external dependencies
```

## Implementation Status
- ✅ **Hub Connectivity Deployment**: Separate Azure Verified Module deployment for hub infrastructure
- ✅ **Cross-Subscription Hub-Spoke**: Complete implementation with comprehensive documentation
- ✅ **Single-Subscription Hub-Spoke**: Complete implementation with architectural guidance
- ✅ **Standalone Application**: Complete implementation for independent deployments

All scenarios are ready for POC deployment and testing.

## Hub Infrastructure
For customers without existing hub infrastructure, use the **separate hub deployment**:
- **Location**: `examples/hub-connectivity-deployment/`
- **Purpose**: Deploy Azure Landing Zone connectivity hub using Azure Verified Modules
- **Deploy First**: Always deploy hub before spoke workloads
- **Features**: Azure Firewall, Private DNS Zones, Hub VNet, Network Security
```