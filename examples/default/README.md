# Default AI/ML Landing Zone Deployment

This example demonstrates how to deploy the Azure AI/ML Landing Zone pattern with an example hub network configuration. This is ideal for development and testing scenarios where you need both the platform hub infrastructure and the AI/ML landing zone deployed together.

## Architecture

This deployment creates:

1. **Example Hub Network**: A simple hub virtual network with basic connectivity
2. **AI/ML Landing Zone**: Complete AI Foundry workspace with supporting services
3. **Network Peering**: Connects the AI/ML landing zone to the hub for platform integration

## Prerequisites

- Azure subscription with appropriate permissions
- Terraform >= 1.9
- Azure CLI installed and authenticated

## Quick Start

1. **Clone and Navigate**:
   ```bash
   git clone <repository-url>
   cd examples-new/default
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
| `hub_vnet_address_space` | Hub VNet CIDR | `"10.10.0.0/24"` |
| `ai_lz_vnet_address_space` | AI/ML LZ VNet CIDR | `"192.168.0.0/23"` |
| `enable_telemetry` | Enable Azure telemetry | `true` |
| `tags` | Resource tags | See variables.tf |

### AI Foundry Configuration

The `ai_foundry_definition` variable configures:
- **AI Foundry Workspace**: Central AI/ML workspace
- **AI Projects**: Project-level isolation and resource management  
- **Model Deployments**: Pre-configured AI model endpoints
- **Supporting Services**: Storage, Key Vault, AI Search, Cosmos DB

## Outputs

| Output | Description |
|--------|-------------|
| `resource_group_name` | AI/ML Landing Zone resource group |
| `virtual_network_name` | AI/ML Landing Zone VNet name |
| `ai_foundry_name` | AI Foundry workspace name |
| `storage_account_name` | Primary storage account name |
| `key_vault_name` | Key Vault name |
| `ai_search_service_name` | AI Search service name |
| `hub_resource_group_name` | Hub resource group name |
| `hub_virtual_network_name` | Hub VNet name |

## Network Design

```
Hub Network (10.10.0.0/24)
├── Default Subnet (10.10.0.0/26)
└── Peered to AI/ML LZ

AI/ML Landing Zone (192.168.0.0/23)
├── Private Endpoints Subnet
├── Compute Subnet  
├── AI Services Subnet
└── Peered to Hub
```

## Security Features

- **Private Endpoints**: All AI services use private connectivity
- **Network Isolation**: Dedicated subnets for different service tiers
- **Key Vault Integration**: Secure secret and key management
- **Diagnostic Logging**: Optional logging to Log Analytics (configurable)

## AI/ML Services Deployed

1. **AI Foundry**: Central workspace for AI/ML operations
2. **AI Search**: Vector and hybrid search capabilities
3. **Cosmos DB**: NoSQL database for AI applications
4. **Storage Account**: Blob storage for datasets and models
5. **Key Vault**: Secure credential and key management
6. **Container Registry**: Private container image storage

## Customization

### Adding AI Models

Modify the `ai_model_deployments` in your `terraform.tfvars`:

```hcl
ai_foundry_definition = {
  ai_model_deployments = {
    "gpt-4o" = {
      name = "gpt-4o"
      model = {
        format  = "OpenAI"
        name    = "gpt-4o"
        version = "2024-08-06"
      }
      scale = {
        type     = "Standard"
        capacity = 20
      }
    }
    "text-embedding-ada-002" = {
      name = "text-embedding-ada-002"
      model = {
        format  = "OpenAI"
        name    = "text-embedding-ada-002"
        version = "2"
      }
      scale = {
        type     = "Standard"
        capacity = 120
      }
    }
  }
}
```

### Adding AI Projects

Configure multiple projects in `ai_projects`:

```hcl
ai_projects = {
  development = {
    name                       = "development"
    description                = "Development environment for AI experiments"
    display_name               = "Development Project"
    create_project_connections = true
    # ... connection configurations
  }
  staging = {
    name                       = "staging"
    description                = "Staging environment for AI model testing"
    display_name               = "Staging Project"
    create_project_connections = true
    # ... connection configurations
  }
}
```

## Cost Optimization

- Use lower-tier AI model deployments for development
- Enable diagnostic settings only when needed
- Consider using consumption-based pricing for AI services
- Review and adjust model deployment capacity based on usage

## Cleanup

```bash
terraform destroy
```

## Next Steps

After deployment, you can:

1. Access AI Foundry workspace via Azure Portal
2. Create and train AI models in AI projects
3. Deploy models to endpoints for inference
4. Integrate with your applications using private endpoints

## Support

For issues or questions:
- Check the [main repository documentation](../../README.md)
- Review Azure AI Foundry documentation
- Open an issue in the repository