# Standalone AI/ML Landing Zone Deployment

This example demonstrates how to deploy the Azure AI/ML Landing Zone in standalone mode without any hub network dependency. This is ideal for self-contained AI/ML workloads that don't need integration with existing platform landing zones.

## Architecture

This deployment creates:

1. **Standalone AI/ML Network**: Complete virtual network with all necessary subnets
2. **AI/ML Services**: Full complement of AI services with public access enabled
3. **Security**: Network security groups and proper access controls
4. **Monitoring**: Log Analytics workspace and Application Insights

## Features

- **Self-Contained**: No dependencies on external hub networks
- **Public Access**: Services configured with public access for simplicity
- **Complete Suite**: All AI/ML services included (Storage, Key Vault, AI Services, Search, Cosmos DB)
- **Security**: Network security groups and proper subnet segmentation
- **Monitoring**: Built-in monitoring and logging capabilities

## Prerequisites

- Azure subscription with appropriate permissions
- Terraform >= 1.9
- Azure CLI installed and authenticated

## Quick Start

1. **Clone and Navigate**:
   ```bash
   git clone <repository-url>
   cd examples-new/standalone
   ```

2. **Configure Variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
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
| `location` | Azure region for deployment | `"East US 2"` |
| `name_prefix` | Prefix for resource names (≤10 chars) | `"aiml"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ai_lz_vnet_address_space` | AI/ML VNet CIDR | `"192.168.0.0/22"` |
| `enable_telemetry` | Enable Azure telemetry | `true` |
| `tags` | Resource tags | See variables.tf |

## Network Design

```
AI/ML Landing Zone (192.168.0.0/22)
├── Private Endpoints Subnet (192.168.0.0/25)
├── Compute Subnet (192.168.0.128/25)
└── Web Subnet (192.168.1.0/25)
```

The standalone deployment uses a larger address space (/22) to accommodate all necessary subnets without external dependencies.

## Security Features

- **Network Security Groups**: Applied to compute subnet with HTTPS rules
- **Public Access**: Enabled for all services (suitable for dev/test)
- **Key Vault Access**: Configured with full permissions for deployment user
- **Subnet Segmentation**: Separate subnets for different service tiers

## AI/ML Services Deployed

1. **Storage Account**: Blob storage for datasets and models
2. **Key Vault**: Secure credential and key management  
3. **AI Services**: Cognitive Services account for AI capabilities
4. **AI Search**: Vector and hybrid search capabilities
5. **Cosmos DB**: NoSQL database for AI applications
6. **Application Insights**: Application performance monitoring
7. **Log Analytics**: Centralized logging and monitoring

## Outputs

| Output | Description |
|--------|-------------|
| `ai_ml_resource_group_name` | AI/ML Landing Zone resource group |
| `ai_ml_virtual_network_name` | AI/ML Landing Zone VNet name |
| `storage_account_name` | Primary storage account name |
| `key_vault_name` | Key Vault name |
| `cognitive_services_name` | AI Services account name |
| `ai_search_service_name` | AI Search service name |
| `cosmos_db_account_name` | Cosmos DB account name |
| `application_insights_name` | Application Insights component name |
| `log_analytics_workspace_name` | Log Analytics workspace name |

## Use Cases

This standalone deployment is ideal for:

- **Development and Testing**: Quick AI/ML environment setup
- **Proof of Concepts**: Isolated environments for experimentation
- **Small Teams**: Self-contained workloads without enterprise networking
- **Learning**: Understanding AI/ML service integration
- **Rapid Prototyping**: Fast deployment for AI/ML experiments

## Security Considerations

⚠️ **Note**: This example enables public access to services for simplicity. For production deployments:

1. Consider using private endpoints
2. Implement network access restrictions
3. Configure firewalls and access policies
4. Enable advanced threat protection
5. Implement proper RBAC controls

## Customization

### Adding Private Endpoints

To enhance security, you can add private endpoints:

```hcl
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "${local.prefix}-storage-blob-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_ml.name
  subnet_id           = azurerm_subnet.ai_ml_private_endpoints.id
  
  private_service_connection {
    name                           = "storage-blob-psc"
    private_connection_resource_id = azurerm_storage_account.ai_foundry.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
```

### Adding Network Restrictions

Restrict access by IP ranges:

```hcl
resource "azurerm_storage_account_network_rules" "ai_foundry" {
  storage_account_id = azurerm_storage_account.ai_foundry.id
  
  default_action = "Deny"
  ip_rules       = ["YOUR_IP_RANGE"]
  
  depends_on = [azurerm_storage_account.ai_foundry]
}
```

## Cost Optimization

- Services are configured with minimal SKUs suitable for development
- Consider scaling down for cost savings in non-production environments
- Use consumption-based pricing where available
- Monitor usage through Application Insights and Log Analytics

## Migration Path

This standalone deployment can be migrated to a hub-spoke model by:

1. Creating VNet peering to a hub network
2. Configuring private endpoints
3. Updating DNS resolution
4. Implementing network security policies

## Cleanup

```bash
terraform destroy
```

## Next Steps

After deployment, you can:

1. Access services through Azure Portal
2. Configure AI model deployments
3. Set up development environments
4. Integrate with CI/CD pipelines
5. Implement monitoring and alerting

## Support

For issues or questions:
- Check the [main repository documentation](../../README.md)
- Review Azure AI services documentation
- Open an issue in the repository