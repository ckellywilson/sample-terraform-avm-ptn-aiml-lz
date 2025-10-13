# Cross-Subscription Hub-Spoke Deployment Guide

## Prerequisites

### 1. Azure Subscriptions and Access
- **Hub Subscription**: Contains connectivity and shared DNS services
- **Spoke Subscription**: Will contain Azure AI Foundry workload
- Service Principal or User Account with:
  - `Contributor` role on both subscriptions
  - `Private DNS Zone Contributor` role on hub subscription
  - `Network Contributor` role on both subscriptions

### 2. Existing Hub Infrastructure
Your hub subscription should already have:
- Hub Virtual Network with appropriate address space
- Private DNS Zones for Azure AI services (see required zones below)
- DNS Private Resolver (optional but recommended)
- Network Security Groups and firewall rules

### 3. Required Private DNS Zones in Hub
Ensure these zones exist in your hub subscription:

```bash
# Azure AI Foundry & Machine Learning
privatelink.api.azureml.ms
privatelink.cert.api.azureml.ms
privatelink.notebooks.azure.net
privatelink.instances.azureml.ms
privatelink.inference.ml.azure.com

# Azure AI Services
privatelink.services.ai.azure.com
privatelink.cognitiveservices.azure.com
privatelink.openai.azure.com

# Supporting Services
privatelink.blob.core.windows.net
privatelink.file.core.windows.net
privatelink.queue.core.windows.net
privatelink.table.core.windows.net
privatelink.vaultcore.azure.net
privatelink.azurecr.io
privatelink.documents.azure.com
privatelink.search.windows.net
```

## Deployment Steps

### Step 1: Configure Variables
1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Update the following values:
   ```hcl
   # Hub subscription details
   hub_subscription_id     = "your-hub-subscription-id"
   hub_resource_group_name = "your-hub-dns-resource-group"
   hub_vnet_id            = "your-hub-vnet-resource-id"
   
   # Spoke subscription details
   spoke_subscription_id   = "your-spoke-subscription-id"
   
   # Update DNS zone resource IDs
   hub_private_dns_zones = {
     "privatelink.api.azureml.ms" = "/subscriptions/hub-sub-id/resourceGroups/hub-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms"
     # ... add all other zones
   }
   ```

### Step 2: Authentication Setup
Ensure your Terraform can authenticate to both subscriptions:

```bash
# Login to Azure
az login

# Verify access to both subscriptions
az account set --subscription "hub-subscription-id"
az account show

az account set --subscription "spoke-subscription-id" 
az account show
```

### Step 3: Initialize and Deploy
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Deploy (after reviewing plan)
terraform apply -var-file="terraform.tfvars"
```

### Step 4: Verify Deployment
After deployment, verify:

1. **VNet Peering Status**:
   ```bash
   # Check hub to spoke peering
   az network vnet peering show \
     --subscription "hub-subscription-id" \
     --resource-group "hub-network-rg" \
     --vnet-name "hub-vnet-name" \
     --name "hub-to-spoke-peering"
   
   # Check spoke to hub peering
   az network vnet peering show \
     --subscription "spoke-subscription-id" \
     --resource-group "spoke-rg-name" \
     --vnet-name "spoke-vnet-name" \
     --name "spoke-to-hub-peering"
   ```

2. **DNS Zone Links**:
   ```bash
   # Verify DNS zone links
   az network private-dns link vnet list \
     --subscription "hub-subscription-id" \
     --resource-group "hub-dns-rg" \
     --zone-name "privatelink.api.azureml.ms"
   ```

3. **AI Foundry Connectivity**:
   ```bash
   # Test DNS resolution from spoke VNet (requires VM in spoke)
   nslookup your-ai-foundry-endpoint.api.azureml.ms
   ```

## Architecture Benefits

### ✅ Advantages of This Approach
1. **Centralized DNS Management**: All private DNS zones managed in hub subscription
2. **Cost Optimization**: No duplicate DNS zones across spoke subscriptions  
3. **Governance**: Platform team controls networking and DNS infrastructure
4. **Scalability**: Easy to add more spoke subscriptions using same DNS zones
5. **Security**: Network isolation with controlled connectivity through hub

### ✅ Compliance with Azure Landing Zones
- Follows hub-spoke network topology pattern
- Separates platform and application concerns
- Enables centralized governance and policy application
- Supports hybrid connectivity patterns

### ✅ Well-Architected Framework Alignment
- **Security**: Private connectivity, centralized DNS control
- **Reliability**: Redundant network paths, managed DNS resolution
- **Cost Optimization**: Shared infrastructure, no resource duplication
- **Operational Excellence**: Clear separation of concerns, standardized deployment
- **Performance**: Optimized network routing, proper DNS resolution

## Troubleshooting

### Common Issues and Solutions

1. **Private Endpoint DNS Resolution Fails**
   - Verify DNS zone links exist for spoke VNet
   - Check DNS servers configuration on spoke VNet
   - Ensure proper RBAC permissions for DNS zone management

2. **VNet Peering Connection Issues**
   - Verify address spaces don't overlap
   - Check Network Security Group rules
   - Ensure proper routing configuration

3. **Cross-Subscription Permission Errors**
   - Verify service principal has required roles on both subscriptions
   - Check Azure Policy compliance for resource deployment

4. **AI Foundry Private Endpoint Creation Fails**
   - Ensure subnet has proper delegation settings
   - Verify network policies are properly configured
   - Check private DNS zone group configuration

## Best Practices

1. **Network Planning**:
   - Plan address spaces carefully to avoid conflicts
   - Reserve address ranges for future growth
   - Document network topology and dependencies

2. **Security**:
   - Implement Network Security Groups with least privilege
   - Use Azure Firewall for centralized network security
   - Enable Azure Monitor for network monitoring

3. **Governance**:
   - Use Azure Policy to enforce networking standards
   - Implement naming conventions across subscriptions
   - Document hub-spoke relationships and dependencies

4. **Monitoring**:
   - Enable VNet flow logs for traffic analysis
   - Monitor DNS query patterns and resolution
   - Set up alerts for network connectivity issues