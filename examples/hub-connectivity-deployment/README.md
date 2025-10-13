# Hub Connectivity Landing Zone Deployment

## Overview
This deployment creates a complete Azure Landing Zone connectivity hub using Azure Verified Modules. It's designed to be deployed **first** and **separately** before deploying any spoke workloads like Azure AI Foundry.

## What Gets Deployed
- 🌐 **Hub Virtual Network** with enterprise-grade networking
- 🔥 **Azure Firewall** with firewall policy for centralized security
- 🔗 **Private DNS Zones** for all Azure AI/ML services
- 🛡️ **Network Security** with proper routing and segmentation
- 📋 **Azure Policies** for governance and compliance

## Architecture
```
📦 Hub Subscription (Connectivity)
└── 🌐 Hub VNet (10.0.0.0/16)
    ├── AzureFirewallSubnet (10.0.1.0/24)
    ├── Shared Services Subnet (10.0.2.0/24)
    ├── GatewaySubnet (10.0.3.0/24)
    └── 🔗 Private DNS Zones
        ├── privatelink.api.azureml.ms
        ├── privatelink.notebooks.azure.net
        ├── privatelink.blob.core.windows.net
        └── ...other Azure service zones
```

## Prerequisites
1. **Azure Subscription** with Owner or Contributor + User Access Administrator permissions
2. **Terraform** >= 1.9 installed
3. **Azure CLI** logged in with appropriate permissions

## Deployment Steps

### 1. Configure Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your subscription ID and preferences
```

### 2. Deploy Hub Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### 3. Capture Outputs
After deployment, save these outputs for spoke deployments:
```bash
# Get hub VNet resource ID
terraform output hub_virtual_network_id

# Get hub resource group name  
terraform output hub_resource_group_name
```

## Deployment Time
- **Initial deployment**: ~15-20 minutes
- **Azure Firewall**: Takes the longest (~10 minutes)
- **Private DNS Zones**: ~2-3 minutes

## Cost Considerations
This hub infrastructure has ongoing costs:
- **Azure Firewall**: ~$1.25/hour + data processing charges
- **VNet**: Minimal cost for IP address usage
- **Private DNS Zones**: $0.50/zone/month + query charges

For POC environments, consider:
- Using **Basic** firewall tier instead of Standard
- Shutting down during non-business hours (requires recreation)

## Next Steps
After successful deployment:
1. ✅ **Verify** Azure Firewall is running
2. ✅ **Confirm** Private DNS zones are created
3. ✅ **Test** hub connectivity
4. 🚀 **Deploy spoke workloads** using the output values

## Troubleshooting
- **Firewall deployment fails**: Check subscription quotas
- **DNS zone conflicts**: Ensure zones don't already exist
- **Permission errors**: Verify RBAC assignments

## Clean Up
```bash
terraform destroy
```
⚠️ **Warning**: This will delete all hub infrastructure and break spoke connectivity!