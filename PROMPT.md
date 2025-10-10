# Azure AI/ML Landing Zone - Default Example Setup Prompt

## Project Overview

Create a comprehensive Terraform Azure AI/ML Landing Zone implementation based on the Azure Verified Module pattern. This setup deploys the **default example** configuration which does NOT use an existing Hub VNet (platform landing zone flag set to `false`), meaning all supporting services are included as part of the AI landing zone deployment.

## Architecture Description

This configuration creates a complete AI/ML landing zone that includes:
- A sample hub VNet to mimic an existing network landing zone configuration
- AI Foundry hub with project management capabilities
- Azure OpenAI model deployments (GPT-4o)
- Supporting services: Container Registry, Cosmos DB, Key Vault, Storage Account, AI Search
- Network infrastructure: VNet peering, DNS resolution, Bastion, Application Gateway
- Security: Firewall, private DNS zones, network ACLs

## Required File Structure

Create the following folder structure with environment-specific configurations:

```
/workspaces/sample-default-terraform-avm-ptn-aiml-lz/
├── modules/
│   └── ai-ml-landing-zone/
│       ├── terraform.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── main.tf
│       ├── outputs.tf
│       └── README.md
├── environments/
│   ├── dev/
│   │   ├── terraform.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── README.md
│   ├── staging/
│   │   ├── terraform.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── README.md
│   └── prod/
│       ├── terraform.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── README.md
├── shared/
│   ├── locals.tf
│   └── naming.tf
└── README.md
```

**Environment Folder Customization Options:**
- `dev` → Can be renamed to `development`, `sandbox`, `test`
- `staging` → Can be renamed to `stage`, `uat`, `pre-prod`, `integration`
- `prod` → Can be renamed to `production`, `live`, `main`

### 1. Shared Configuration Files

#### `shared/locals.tf`
```hcl
# Shared locals across all environments
locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = "AI-ML-Landing-Zone"
    ManagedBy   = "Terraform"
    Repository  = "sample-default-terraform-avm-ptn-aiml-lz"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Environment-specific configurations
  environment_configs = {
    dev = {
      location                = "East US 2"
      vnet_address_space     = "10.0.0.0/16"
      hub_address_space      = "10.1.0.0/24"
      sku_tier               = "Basic"
      enable_diagnostic_logs = false
      purge_on_destroy      = true
    }
    staging = {
      location                = "Central US"
      vnet_address_space     = "10.10.0.0/16"
      hub_address_space      = "10.11.0.0/24"
      sku_tier               = "Standard"
      enable_diagnostic_logs = true
      purge_on_destroy      = false
    }
    prod = {
      location                = "West US 2"
      vnet_address_space     = "10.20.0.0/16"
      hub_address_space      = "10.21.0.0/24"
      sku_tier               = "Premium"
      enable_diagnostic_logs = true
      purge_on_destroy      = false
    }
  }
}
```

#### `shared/naming.tf`
```hcl
# Consistent naming convention across environments
locals {
  naming_convention = {
    resource_group = "${var.project_name}-rg-${var.environment}-${random_string.suffix.result}"
    vnet          = "${var.project_name}-vnet-${var.environment}"
    hub_vnet      = "${var.project_name}-hub-vnet-${var.environment}"
    ai_foundry    = "${var.project_name}-aif-${var.environment}"
    key_vault     = "${var.project_name}kv${var.environment}${random_string.suffix.result}"
    storage       = "${var.project_name}st${var.environment}${random_string.suffix.result}"
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}
```

### 2. Module Configuration Files (modules/ai-ml-landing-zone/)

#### `modules/ai-ml-landing-zone/terraform.tf`
```hcl
terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
```

#### `modules/ai-ml-landing-zone/providers.tf`
```hcl
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = var.environment == "dev" ? false : true
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = var.purge_on_destroy
    }
  }
}
```

#### `modules/ai-ml-landing-zone/variables.tf`
```hcl
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  
  validation {
    condition = contains(["dev", "staging", "prod", "development", "stage", "uat", "pre-prod", "integration", "production", "live", "main", "sandbox", "test"], var.environment)
    error_message = "Environment must be one of the supported values."
  }
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
  default     = "aiml-lz"
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment"
}

variable "vnet_address_space" {
  type        = string
  description = "Address space for the AI/ML Landing Zone VNet"
}

variable "hub_address_space" {
  type        = string
  description = "Address space for the Hub VNet"
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "enable_diagnostic_logs" {
  type        = bool
  description = "Enable diagnostic logging for resources"
}

variable "purge_on_destroy" {
  type        = bool
  description = "Whether to purge soft-delete capable resources on destroy"
  default     = false
}

variable "sku_tier" {
  type        = string
  description = "SKU tier for resources (Basic, Standard, Premium)"
  default     = "Standard"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to resources"
  default     = {}
}
```

#### `modules/ai-ml-landing-zone/main.tf`
Create the main module configuration with the following key components:

```hcl
# Get current IP address for firewall rules
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

# Generate unique naming suffix
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Local values for resource naming and configuration
locals {
  environment_config = {
    location                = var.location
    vnet_address_space     = var.vnet_address_space
    hub_address_space      = var.hub_address_space
    enable_diagnostic_logs = var.enable_diagnostic_logs
    purge_on_destroy      = var.purge_on_destroy
    sku_tier               = var.sku_tier
  }
  
  resource_names = {
    resource_group = "${var.project_name}-rg-${var.environment}-${random_string.suffix.result}"
    vnet          = "${var.project_name}-vnet-${var.environment}"
    hub_vnet      = "${var.project_name}-hub-vnet-${var.environment}"
  }
  
  merged_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# Example Hub Module for network foundation
module "example_hub" {
  source  = "Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/azurerm//modules/example_hub_vnet"
  version = "~> 1.0"  # Use appropriate version
  
  deployer_ip_address = "${data.http.ip.response_body}/32"
  location            = local.environment_config.location
  resource_group_name = "${local.resource_names.resource_group}-hub"
  
  vnet_definition = {
    address_space = local.environment_config.hub_address_space
  }
  
  enable_telemetry = var.enable_telemetry
  name_prefix      = "${var.project_name}-${var.environment}-hub"
  tags             = local.merged_tags
}

# Main AI/ML Landing Zone Module
module "ai_ml_landing_zone" {
  source  = "Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/azurerm"
  version = "~> 1.0"  # Use appropriate version
  
  location            = local.environment_config.location
  resource_group_name = local.resource_names.resource_group
  
  vnet_definition = {
    name          = local.resource_names.vnet
    address_space = local.environment_config.vnet_address_space
    dns_servers   = [for key, value in module.example_hub.dns_resolver_inbound_ip_addresses : value]
    
    hub_vnet_peering_definition = {
      peer_vnet_resource_id = module.example_hub.virtual_network_resource_id
      firewall_ip_address   = module.example_hub.firewall_ip_address
    }
  }
  
  # Environment-specific configuration will be passed from environment folders
  # This is where the AI Foundry, App Gateway, and other service configurations go
  # (Configuration details moved to environment-specific sections below)
  
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = false  # Default example doesn't use existing hub
  tags                       = local.merged_tags
  
  depends_on = [module.example_hub]
}
```

### 3. Environment-Specific Configuration Files

#### Development Environment (`environments/dev/`)

**`environments/dev/terraform.tf`**
```hcl
terraform {
  required_version = ">= 1.9, < 2.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  
  backend "azurerm" {
    # Configure backend for dev environment
    resource_group_name  = "terraform-state-rg-dev"
    storage_account_name = "tfstatedevXXXXXX"  # Replace with actual storage account
    container_name       = "tfstate"
    key                  = "dev/aiml-lz.tfstate"
  }
}

provider "azurerm" {
  features {}
}
```

**`environments/dev/main.tf`**
```hcl
module "ai_ml_landing_zone" {
  source = "../../modules/ai-ml-landing-zone"
  
  environment         = "dev"
  project_name        = "aiml-lz"
  location           = "East US 2"
  vnet_address_space = "10.0.0.0/16"
  hub_address_space  = "10.1.0.0/24"
  
  enable_diagnostic_logs = false  # Disabled for dev to reduce costs
  purge_on_destroy      = true   # Allow purging in dev environment
  sku_tier              = "Basic"
  
  tags = {
    Environment = "Development"
    CostCenter  = "Engineering"
    Owner       = "DevOps Team"
  }
}
```

**`environments/dev/variables.tf`**
```hcl
# Environment-specific variable overrides
variable "ai_model_capacity" {
  type        = number
  description = "Capacity for AI model deployments in dev"
  default     = 1
}

variable "enable_advanced_features" {
  type        = bool
  description = "Enable advanced features in dev environment"
  default     = false
}
```

**`environments/dev/terraform.tfvars`**
```hcl
# Development environment specific values
ai_model_capacity = 1
enable_advanced_features = false

# Override default project settings for dev
project_specific_settings = {
  enable_monitoring = false
  backup_retention_days = 7
  auto_scaling_enabled = false
}
```

#### Staging Environment (`environments/staging/`)

**`environments/staging/terraform.tf`**
```hcl
terraform {
  required_version = ">= 1.9, < 2.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg-staging"
    storage_account_name = "tfstatestagingXXXXXX"
    container_name       = "tfstate"
    key                  = "staging/aiml-lz.tfstate"
  }
}

provider "azurerm" {
  features {}
}
```

**`environments/staging/main.tf`**
```hcl
module "ai_ml_landing_zone" {
  source = "../../modules/ai-ml-landing-zone"
  
  environment         = "staging"
  project_name        = "aiml-lz"
  location           = "Central US"
  vnet_address_space = "10.10.0.0/16"
  hub_address_space  = "10.11.0.0/24"
  
  enable_diagnostic_logs = true     # Enabled for staging testing
  purge_on_destroy      = false    # Prevent accidental purging
  sku_tier              = "Standard"
  
  tags = {
    Environment = "Staging"
    CostCenter  = "Engineering"
    Owner       = "QA Team"
  }
}
```

#### Production Environment (`environments/prod/`)

**`environments/prod/terraform.tf`**
```hcl
terraform {
  required_version = ">= 1.9, < 2.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg-prod"
    storage_account_name = "tfstateprodXXXXXX"
    container_name       = "tfstate"
    key                  = "prod/aiml-lz.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true  # Extra protection for prod
    }
  }
}
```

**`environments/prod/main.tf`**
```hcl
module "ai_ml_landing_zone" {
  source = "../../modules/ai-ml-landing-zone"
  
  environment         = "prod"
  project_name        = "aiml-lz"
  location           = "West US 2"
  vnet_address_space = "10.20.0.0/16"
  hub_address_space  = "10.21.0.0/24"
  
  enable_diagnostic_logs = true      # Full logging for production
  purge_on_destroy      = false     # Never purge in production
  sku_tier              = "Premium"
  
  tags = {
    Environment = "Production"
    CostCenter  = "Business"
    Owner       = "Platform Team"
    Compliance  = "Required"
  }
}
```

### 4. Key Configuration Parameters

#### AI Foundry Configuration:
```hcl
ai_foundry_definition = {
  purge_on_destroy = true
  ai_foundry = {
    create_ai_agent_service = true
  }
  ai_model_deployments = {
    "gpt-4o" = {
      name = "gpt-4.1"
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1"
        version = "2025-04-14"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 1
      }
    }
  }
  ai_projects = {
    project_1 = {
      name                       = "project-1"
      description                = "Project 1 description"
      display_name               = "Project 1 Display Name"
      create_project_connections = true
      cosmos_db_connection = {
        new_resource_map_key = "this"
      }
      ai_search_connection = {
        new_resource_map_key = "this"
      }
      storage_account_connection = {
        new_resource_map_key = "this"
      }
    }
  }
  # Additional service definitions for search, cosmos, keyvault, storage
}
```

#### Application Gateway Configuration:
```hcl
app_gateway_definition = {
  backend_address_pools = {
    example_pool = {
      name = "example-backend-pool"
    }
  }
  backend_http_settings = {
    example_http_settings = {
      name     = "example-http-settings"
      port     = 80
      protocol = "Http"
    }
  }
  frontend_ports = {
    example_frontend_port = {
      name = "example-frontend-port"
      port = 80
    }
  }
  http_listeners = {
    example_listener = {
      name               = "example-listener"
      frontend_port_name = "example-frontend-port"
    }
  }
  request_routing_rules = {
    example_rule = {
      name                       = "example-rule"
      rule_type                  = "Basic"
      http_listener_name         = "example-listener"
      backend_address_pool_name  = "example-backend-pool"
      backend_http_settings_name = "example-http-settings"
      priority                   = 100
    }
  }
}
```

### 3. Supporting Service Configurations

#### Container Registry, Cosmos DB, Key Vault, Storage:
```hcl
genai_container_registry_definition = {
  enable_diagnostic_settings = false
}
genai_cosmosdb_definition = {
  enable_diagnostic_settings = false
  consistency_level          = "Session"
}
genai_key_vault_definition = {
  public_network_access_enabled = true  # configured for testing
  network_acls = {
    bypass   = "AzureServices"
    ip_rules = ["${data.http.ip.response_body}/32"]
  }
}
genai_storage_account_definition = {
  enable_diagnostic_settings = false
}
```

### 4. Private DNS Zones
Configure private DNS zones for existing zones reuse:
```hcl
private_dns_zones = {
  existing_zones_resource_group_resource_id = module.example_hub.resource_group_resource_id
}
```

### 5. Platform Landing Zone Flag
Set to `false` for default example (no existing hub):
```hcl
flag_platform_landing_zone = false
```

## Important Notes

1. **Address Space**: The AI landing zone VNet must use address space outside of 192.168.0.0/16 for Foundry capability host injection compatibility.

2. **DNS Configuration**: The example uses DNS servers from the hub VNet for proper name resolution.

3. **Testing Configuration**: Some settings are configured for testing purposes (public access, diagnostic settings disabled).

4. **Telemetry**: Include telemetry variable passthrough to respect user preferences.

5. **Resource Naming**: Use consistent naming conventions with the naming module.

6. **Dependencies**: Ensure proper resource dependencies are configured.

### 5. Root-Level Files

#### `README.md`
```markdown
# Azure AI/ML Landing Zone - Multi-Environment Setup

## Overview
This repository contains Terraform configurations for deploying Azure AI/ML Landing Zone across multiple environments (dev, staging, prod).

## Structure
- `modules/ai-ml-landing-zone/` - Reusable module containing the main logic
- `environments/` - Environment-specific configurations
- `shared/` - Shared locals and naming conventions

## Usage

### Deploy to Development
```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### Deploy to Staging  
```bash
cd environments/staging
terraform init
terraform plan
terraform apply
```

### Deploy to Production
```bash
cd environments/prod
terraform init
terraform plan
terraform apply
```

## Environment Customization
To customize environment folder names, update the folder structure and references in:
- Backend configuration keys
- Module source paths
- Documentation references
```

## Environment Folder Customization Guide

### Renaming Environment Folders

**Option 1: Standard Development Lifecycle**
```
environments/
├── development/    # Instead of 'dev'
├── integration/    # Instead of 'staging'  
└── production/     # Instead of 'prod'
```

**Option 2: Enterprise Naming**
```
environments/
├── sandbox/        # Early development
├── dev/           # Development
├── test/          # Testing environment
├── uat/           # User acceptance testing
├── pre-prod/      # Pre-production
└── prod/          # Production
```

**Option 3: Geographic/Business Unit Based**
```
environments/
├── dev-eastus/
├── staging-westus/
├── prod-centralus/
└── prod-westeurope/
```

### Steps to Customize Environment Names:

1. **Rename the folders** in the `environments/` directory
2. **Update backend configuration keys** in each environment's `terraform.tf`
3. **Update environment validation** in `modules/ai-ml-landing-zone/variables.tf`
4. **Update documentation** and README files
5. **Update CI/CD pipelines** if using automated deployments

### Variable Validation Update Example:
```hcl
variable "environment" {
  type        = string
  description = "Environment name"
  
  validation {
    condition = contains([
      "sandbox", "development", "test", "uat", 
      "integration", "pre-prod", "production"
    ], var.environment)
    error_message = "Environment must be one of the supported values."
  }
}
```

## File Organization

- **Modular Structure**: Separate reusable module from environment-specific configurations
- **Environment Isolation**: Each environment has its own Terraform state and configuration
- **Shared Resources**: Common naming conventions and configurations in shared folder
- **Clear Separation**: Development, staging, and production configurations are completely isolated
- **Scalable**: Easy to add new environments by copying and modifying existing environment folders

## Deployment Considerations

### Multi-Environment Strategy
- **State Isolation**: Each environment maintains separate Terraform state files
- **Backend Configuration**: Use different storage accounts/containers for each environment
- **Environment-Specific Settings**: Different SKUs, logging levels, and security settings per environment
- **Progressive Deployment**: Deploy to dev → staging → production with validation gates

### Security and Compliance
- **Development**: Relaxed security for rapid iteration
- **Staging**: Production-like security for realistic testing
- **Production**: Full security controls, compliance monitoring, and audit logging

### Cost Management
- **Dev**: Basic SKUs, disabled diagnostics, shorter retention periods
- **Staging**: Standard SKUs, limited monitoring
- **Production**: Premium SKUs, full monitoring, extended retention

### Automation and CI/CD
- **Branch-based deployments**: dev branch → dev environment, main branch → staging/prod
- **Approval gates**: Require manual approval for staging and production deployments
- **Environment promotion**: Validate in lower environments before promoting to higher ones

### Disaster Recovery
- **Multi-region consideration**: Production can be deployed across multiple regions
- **Backup strategies**: Environment-specific backup and retention policies
- **Recovery testing**: Regular disaster recovery testing in staging environment

This prompt creates a complete, enterprise-ready Azure AI/ML Landing Zone with proper environment separation, following Azure Verified Module patterns and best practices for multi-environment deployments.