# Azure AI/ML Landing Zone - Terraform Implementation

This repository provides a complete Azure AI/ML Landing Zone implementation based on the Azure Verified Module (AVM) pattern, enabling secure and scalable AI/ML workloads in Azure.

## Related Repositories

This implementation is based on the following foundational repositories:

- **[Azure AI Landing Zones](https://github.com/Azure/AI-Landing-Zones)**: The base Azure AI Landing Zone reference architecture and design patterns
- **[Terraform Azure AI/ML Landing Zone Module](https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone)**: The official Azure Verified Module for AI/ML Landing Zone implementation

## Project Overview

This pattern module creates a comprehensive AI/ML Landing Zone infrastructure that supports multiple AI project scenarios. The module follows Azure Well-Architected Framework principles and provides two deployment configurations:

- **Default (Hub-and-Spoke)**: Connects to existing platform landing zone infrastructure with centralized DNS, firewall, and hybrid connectivity services
- **Standalone**: Self-contained deployment with all supporting infrastructure included

## Architecture Description  

The AI/ML Landing Zone provides a secure, governed foundation for AI/ML workloads with the following core capabilities:

### Core AI/ML Services
- **Azure AI Foundry**: Centralized AI hub for model management and deployment
- **Azure OpenAI Service**: GPT-4 and other large language model deployments  
- **Azure AI Search**: Vector search and retrieval capabilities
- **Azure Cosmos DB**: NoSQL database for AI application data
- **Azure Container Registry**: Secure container image storage
- **Azure Storage Account**: Data lake and blob storage for AI assets

### Security & Governance
- **Azure Key Vault**: Secrets and certificate management
- **Private DNS Zones**: Secure name resolution for private endpoints
- **Network Security Groups**: Granular network access controls  
- **Private Endpoints**: Secure connectivity to Azure services
- **Azure Monitor**: Comprehensive logging and monitoring

### Networking Foundation
- **Virtual Network**: Isolated network environment with subnets for different tiers
- **Azure Firewall**: Centralized network security (default example)
- **Azure Bastion**: Secure administrative access to VMs
- **DNS Resolver**: Private DNS resolution (default example)

## Repository Structure

This repository follows the Azure Verified Module pattern with comprehensive examples:

```
├── README.md                    # Main documentation
├── PROMPT.md                   # This implementation guide
├── examples/                   # Deployment examples
│   ├── README.md               # Examples overview
│   ├── default/                # Default (hub-spoke) deployment
│   │   ├── main.tf             # Primary configuration
│   │   ├── variables.tf        # Input variables
│   │   ├── outputs.tf          # Output values
│   │   ├── README.md           # Deployment guide
│   │   └── terraform.tfvars.example # Sample configuration
│   ├── standalone/             # Standalone deployment
│   │   ├── main.tf             # Primary configuration  
│   │   ├── variables.tf        # Input variables
│   │   ├── outputs.tf          # Output values
│   │   ├── README.md           # Deployment guide
│   │   └── terraform.tfvars.example # Sample configuration
│   ├── sample-hub/             # ALZ-based hub infrastructure
│   │   ├── main.tf             # Hub infrastructure using ALZ AVM
│   │   ├── variables.tf        # Hub configuration variables
│   │   ├── outputs.tf          # Hub output values
│   │   ├── README.md           # Hub deployment guide
│   │   └── terraform.tfvars.example # Hub configuration examples
│   └── with-existing-hub/      # Existing hub integration
│       ├── main.tf             # AI/ML LZ with hub integration
│       ├── variables.tf        # Integration variables
│       ├── outputs.tf          # Integration outputs
│       ├── README.md           # Integration guide
│       └── terraform.tfvars.example # Integration configuration
├── modules/                    # Supporting modules
│   └── example_hub_vnet/       # Sample hub infrastructure
└── shared/                     # Shared resources
    ├── locals.tf               # Common locals
    └── naming.tf               # Naming conventions
```

## Deployment Patterns

### Default Pattern (Platform Landing Zone Integration)
Designed for organizations with existing Azure landing zone infrastructure:

- Connects to existing hub VNet for centralized services
- Uses existing DNS infrastructure via private resolver
- Integrates with centralized firewall for outbound connectivity  
- Leverages existing private DNS zones in the platform

**Use when**: You have an existing Azure landing zone with hub-and-spoke networking

### Standalone Pattern  
Complete self-contained deployment for organizations without existing platform infrastructure:

- Creates all networking and security infrastructure
- Deploys dedicated firewall and DNS services
- Includes comprehensive monitoring and governance
- Fully isolated AI/ML environment

**Use when**: You need a complete AI/ML environment without dependencies on existing infrastructure

## Available Examples

This repository includes four example configurations in the `examples/` folder:

- **`examples/default/`** - Hub-and-spoke integration pattern with sample hub infrastructure
- **`examples/standalone/`** - Self-contained deployment with all services included  
- **`examples/sample-hub/`** - Production-ready hub infrastructure using ALZ AVM modules
- **`examples/with-existing-hub/`** - Integration with existing hub VNet (enterprise scenario)

Each example includes complete Terraform configurations with documentation and sample variable files.

## Prerequisites

### Required Tools
- **Terraform**: >= 1.9, < 2.0
- **Azure CLI**: Latest version for authentication
- **Azure PowerShell**: (Optional) Alternative authentication method

### Azure Requirements  
- **Subscription**: Azure subscription with Owner or Contributor permissions
- **Resource Providers**: Register required providers (Microsoft.MachineLearningServices, Microsoft.CognitiveServices, etc.)
- **Quotas**: Sufficient quotas for compute, storage, and AI services
- **Regions**: Choose regions that support all required AI services

### Networking Prerequisites (Hub-Spoke Pattern Only)
- **Hub VNet**: Existing hub virtual network with DNS services
- **Private DNS**: Existing private DNS zones or resource group for zone creation  
- **Firewall**: Hub firewall with appropriate rules for AI/ML traffic
- **Connectivity**: Express Route or VPN connectivity if hybrid access required

### Creating a Hub Network for Testing

If you don't have an existing platform hub network but want to test the hub-spoke integration pattern, you can create a sample hub using the official Azure Landing Zone (ALZ) Terraform Azure Verified Modules:

**Option 1: Sample Hub (Recommended)**
- **Location**: `examples/sample-hub/` - Complete ALZ-based hub infrastructure
- **Features**: Azure Firewall, DNS Private Resolver, Private DNS Zones
- **Use Case**: Production-ready hub for testing or actual deployment
- **Deployment**: Typically in a separate connectivity subscription (enterprise pattern)

**Option 2: Simple Hub for Development**
- **Location**: `examples/default/` - Basic hub infrastructure included with AI/ML LZ
- **Features**: Simple VNet with basic networking
- **Use Case**: Development and learning scenarios

**Option 3: Custom ALZ Modules**
- **Modules**: Use individual ALZ modules for specific requirements
- **Advanced**: [terraform-azurerm-avm-ptn-hub-and-spoke](https://registry.terraform.io/modules/Azure/avm-ptn-hub-and-spoke/azurerm/latest)
- **Use Case**: Complex enterprise scenarios with specific requirements

For detailed guidance, see the [Sample Hub example](examples/sample-hub/README.md) for production-ready hub creation or the [with-existing-hub example](examples/with-existing-hub/README.md) for integration guidance.

## Quick Start

### 1. Choose Deployment Pattern
Select the appropriate pattern based on your organization's infrastructure:

```bash
# For hub-spoke integration
cd examples/default/

# For standalone deployment  
cd examples/standalone/
```

### 2. Configure Variables
Copy and customize the example configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

### 3. Initialize and Deploy
```bash
# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Apply configuration
terraform apply
```

## Configuration Examples

### Default Pattern Configuration
```hcl
# Default pattern connecting to existing hub
location            = "East US 2"
resource_group_name = "rg-ai-lz-prod"

vnet_definition = {
  name          = "vnet-ai-lz-prod"
  address_space = "10.100.0.0/22"
  dns_servers   = ["10.0.1.4", "10.0.1.5"]  # Hub DNS resolvers
  vnet_peering_configuration = {
    peer_vnet_resource_id = "/subscriptions/.../virtualNetworks/vnet-hub-prod"
    firewall_ip_address   = "10.0.2.4"
  }
}

ai_foundry_definition = {
  ai_foundry = {
    create_ai_agent_service = true
  }
  ai_model_deployments = {
    "gpt-4o" = {
      name = "gpt-4o-prod"
      model = {
        format  = "OpenAI"
        name    = "gpt-4o"
        version = "2024-05-13"
      }
      scale = {
        type     = "Standard"
        capacity = 10
      }
    }
  }
}
```

### Standalone Pattern Configuration
```hcl
# Standalone pattern with all infrastructure
location            = "East US 2" 
resource_group_name = "rg-ai-lz-standalone"

vnet_definition = {
  name          = "vnet-ai-lz-standalone"
  address_space = "192.168.0.0/23"
}

flag_platform_landing_zone = false

ai_foundry_definition = {
  ai_foundry = {
    create_ai_agent_service = true
  }
  ai_model_deployments = {
    "gpt-4o" = {
      name = "gpt-4o"
      model = {
        format  = "OpenAI"  
        name    = "gpt-4o"
        version = "2024-05-13"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 1
      }
    }
  }
}
```

## Key Features

### AI/ML Capabilities
- **Multi-Model Support**: Deploy multiple AI models simultaneously
- **Private Connectivity**: All AI services accessible via private endpoints
- **GPU Compute**: Optional GPU-enabled virtual machines for training
- **MLOps Ready**: Integration with Azure DevOps and GitHub Actions
- **Data Pipeline**: Built-in data processing and storage capabilities

### Security Features  
- **Zero Trust**: All network traffic secured with private endpoints
- **Identity Integration**: Azure AD integration with RBAC
- **Secrets Management**: Centralized secret storage in Key Vault
- **Audit Logging**: Comprehensive activity logging and monitoring
- **Compliance**: Built-in compliance controls and policies

### Operational Excellence
- **Infrastructure as Code**: Full Terraform automation
- **Monitoring**: Integrated Azure Monitor and Log Analytics
- **Backup**: Automated backup for critical AI assets
- **Disaster Recovery**: Cross-region replication capabilities
- **Cost Optimization**: Resource tagging and cost monitoring

## Support and Maintenance

### Documentation
- **Architecture Diagrams**: Available in `/docs` directory
- **API References**: Links to relevant Azure service documentation  
- **Troubleshooting**: Common issues and resolution steps
- **Best Practices**: Azure AI/ML implementation guidelines

### Updates and Versioning
- **Module Updates**: Regular updates to support new Azure AI services
- **Version Pinning**: All modules use specific versions for stability
- **Breaking Changes**: Documented upgrade paths for major versions
- **Security Patches**: Timely updates for security vulnerabilities

This implementation provides a production-ready, secure, and scalable foundation for AI/ML workloads in Azure while following Microsoft's recommended patterns and best practices.
