# Azure AI/ML Landing Zone

🚀 **Production-ready Azure AI/ML infrastructure following Azure Verified Module (AVM) patterns**

## 🎯 Quick Decision Guide

**Learning or Development?** → Start with [Default Example](examples/default/) (creates hub + AI/ML LZ)  
**Self-contained workload?** → Use [Standalone Example](examples/standalone/) (no hub needed)  
**Have existing platform hub?** → Use [With Existing Hub](examples/with-existing-hub/) (enterprise)  

📖 **Complete guidance**: [Examples Documentation](examples/README.md) | [Deployment Scenarios](POC-SCENARIOS.md)

## 📋 What This Repository Provides

- **Scenario-Based Examples**: Clear deployment patterns for different use cases
- **AVM Compliance**: Follows Azure Verified Module best practices
- **Production-Ready**: Complete configurations with security and monitoring
- **Comprehensive Documentation**: Step-by-step guides and troubleshooting
- **Enterprise Integration**: Support for existing platform landing zones

## 🏗️ Architecture

This implementation follows the Azure AI/ML Landing Zone pattern with multiple deployment scenarios:

### Core AI/ML Services
- **Storage Account**: Datasets, models, and artifacts storage
- **Key Vault**: Secure credential and key management
- **AI Services**: Cognitive Services for AI model hosting
- **AI Search**: Vector search and knowledge mining capabilities
- **Cosmos DB**: NoSQL database for AI applications
- **Application Insights**: Application performance monitoring

### Network Integration Options
- **Hub-Spoke with Example Hub**: Complete development environment
- **Standalone**: Self-contained single VNet deployment
- **Enterprise Hub Integration**: Connect to existing platform infrastructure

## 📁 Repository Structure

```
├── examples/              # Deployment scenarios (AVM pattern)
│   ├── default/          # Hub-spoke with example hub
│   ├── standalone/       # Self-contained deployment
│   └── with-existing-hub/ # Enterprise hub integration
├── modules/              # Reusable Terraform modules
│   └── ai-ml-landing-zone/
├── scripts/              # Automation and setup scripts
├── azure-pipelines/      # CI/CD pipeline examples
└── docs/                 # Additional documentation
```

---

## 🚀 Quick Start Guide

Choose your deployment scenario based on your needs:

## 📋 Deployment Scenarios

### �️ **Default Example** ⭐ **RECOMMENDED FOR LEARNING**
Complete deployment with example hub and AI/ML landing zone integrated via VNet peering.

**Architecture**: Example Hub + AI/ML Landing Zone with peering  
**Use Cases**: Development, learning, proof-of-concept, testing  
**Features**: Complete setup, private endpoints, automatic integration  

**Deployment Steps**:
```bash
cd examples/default
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
terraform init && terraform apply
```

### 🚀 **Standalone Example**
Self-contained AI/ML environment without hub network dependencies.

**Architecture**: Single VNet with all AI/ML services  
**Use Cases**: Isolated workloads, rapid prototyping, small teams  
**Features**: Simple setup, public access, cost-optimized  

**Deployment Steps**:
```bash
cd examples/standalone
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

### � **With Existing Hub Example** ⭐ **RECOMMENDED FOR ENTERPRISE**
Integrates AI/ML landing zone with existing platform hub infrastructure.

**Architecture**: AI/ML LZ peered to existing hub network  
**Use Cases**: Enterprise production, existing platform landing zones  
**Features**: Private endpoints, hub DNS integration, enterprise security  

**Deployment Steps**:
```bash
cd examples/with-existing-hub
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with existing hub details
terraform init && terraform apply
```

## 📊 Scenario Comparison

| Aspect | Default | Standalone | With Existing Hub |
|--------|---------|------------|-------------------|
| **Complexity** | Medium | Low | High |
| **Enterprise Readiness** | 🟡 Dev/Test | ❌ Dev Only | ✅ Production Ready |
| **Hub Dependency** | ✅ Creates Example | ❌ None | ✅ Uses Existing |
| **Private Endpoints** | ✅ Yes | ❌ Public Access | ✅ Yes |
| **Setup Time** | 🟡 Moderate | ✅ Quick | ❌ Complex |
| **Prerequisites** | None | None | Existing Hub Network |

## 🖥️ Multi-Environment Deployments

Each example can be deployed to different environments by customizing variables:

### Environment Configuration via Variables

```hcl
# Development Environment
location    = "East US 2"
name_prefix = "dev-aiml"
tags = {
  Environment = "development"
  Project     = "ai-ml-landing-zone"
}

# Production Environment  
location    = "West US 3"
name_prefix = "prod-aiml"
tags = {
  Environment = "production"
  Project     = "ai-ml-landing-zone"
}
```

### Prerequisites
```bash
# Ensure you have required tools
az --version          # Azure CLI >= 2.54
terraform --version   # Terraform >= 1.9
```

### Authentication Setup
```bash
# Login to Azure
az login

# Optional: Create Service Principal for automation
./scripts/create-service-principal.sh your-subscription-id
source ./scripts/setup-local-auth.sh
```

### Backend Storage Setup
```bash
# Create secure state storage for different environments
./scripts/setup-azure-backend.sh dev "East US 2" your-subscription-id
./scripts/setup-azure-backend.sh prod "West US 3" your-subscription-id
```

### Deploy to Different Environments
```bash
# Choose your example and configure for environment
cd examples/default  # or standalone, or with-existing-hub

# Create environment-specific variable files
cp terraform.tfvars.example terraform.tfvars.dev
cp terraform.tfvars.example terraform.tfvars.prod

# Deploy to development
terraform init
terraform apply -var-file="terraform.tfvars.dev"

# Deploy to production (in different workspace/backend)
terraform workspace new prod  # or use different backend
terraform apply -var-file="terraform.tfvars.prod"
```

---

## 🔄 CI/CD Pipeline Setup

### 🐙 GitHub Actions Setup

#### Step 1: Repository Setup
1. Fork or clone this repository to your GitHub account
2. Go to repository **Settings** → **Secrets and variables** → **Actions**

#### Step 2: Create Service Principal for GitHub Actions
```bash
# Create service principal with GitHub-specific name
az ad sp create-for-rbac \
  --name "github-actions-terraform" \
  --role "Contributor" \
  --scopes "/subscriptions/your-subscription-id" \
  --sdk-auth
```

#### Step 3: Add Repository Secrets
Add these secrets in GitHub:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AZURE_CREDENTIALS` | Full JSON output from above command | Service principal credentials |
| `ARM_SUBSCRIPTION_ID` | Your subscription ID | Azure subscription |
| `ARM_TENANT_ID` | Your tenant ID | Azure AD tenant |

#### Step 4: Configure Environments
1. Go to **Settings** → **Environments**
2. Create environments: `dev`, `staging`, `prod`
3. Add protection rules for `prod` (require reviews, etc.)

#### Step 5: Enable Workflows
The repository includes pre-configured workflows:
- `.github/workflows/terraform-dev.yml` - Deploys to dev on PR
- `.github/workflows/terraform-staging.yml` - Deploys to staging on merge to main
- `.github/workflows/terraform-prod.yml` - Deploys to prod on manual trigger

### 🔷 Azure DevOps Setup

#### Step 1: Project Setup
1. Create new Azure DevOps project
2. Import this repository

#### Step 2: Create Service Connection
1. Go to **Project Settings** → **Service connections**
2. Create **Azure Resource Manager** connection
3. Choose **Service principal (automatic)**
4. Select your subscription and resource group
5. Name it `azure-terraform-connection`

#### Step 3: Create Variable Groups
Create variable groups for each environment:

**Variable Group: `terraform-dev`**
- `ARM_SUBSCRIPTION_ID`: Your subscription ID
- `ENVIRONMENT`: dev
- `LOCATION`: East US 2

**Variable Group: `terraform-staging`**
- `ARM_SUBSCRIPTION_ID`: Your subscription ID  
- `ENVIRONMENT`: staging
- `LOCATION`: East US 2

**Variable Group: `terraform-prod`**
- `ARM_SUBSCRIPTION_ID`: Your subscription ID
- `ENVIRONMENT`: prod
- `LOCATION`: East US 2

#### Step 4: Create Pipelines
1. Go to **Pipelines** → **Create Pipeline**
2. Choose **Azure Repos Git** and select your repository
3. Use existing pipeline files:
   - `azure-pipelines/terraform-dev.yml`
   - `azure-pipelines/terraform-staging.yml`
   - `azure-pipelines/terraform-prod.yml`

---

## 🔧 Environment Customization

### Variable Configuration
Each environment has its own `terraform.tfvars` file:

```bash
# environments/dev/terraform.tfvars
location = "East US 2"
environment = "dev"
ai_model_name = "gpt-4o-mini"  # Cheaper for dev
ai_model_version = "2024-07-18"

# environments/prod/terraform.tfvars  
location = "East US 2"
environment = "prod"
ai_model_name = "gpt-4o"       # Full model for production
ai_model_version = "2024-07-18"
```

### Backend Configuration
State files are automatically managed:
- `dev/aiml-lz.tfstate` - Development state
- `staging/aiml-lz.tfstate` - Staging state  
- `prod/aiml-lz.tfstate` - Production state

---

## 🛡️ Security Features

- ✅ **No Storage Keys**: Azure AD authentication only
- ✅ **Encrypted State**: Terraform state encrypted in Azure Storage
- ✅ **Environment Isolation**: Separate storage accounts per environment
- ✅ **Least Privilege**: Minimal required permissions
- ✅ **Credential Management**: Secure handling of secrets
- ✅ **Network Security**: Private endpoints and VNet integration

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Examples Overview](examples/README.md) | Complete guide to all deployment scenarios |
| [Default Example](examples/default/README.md) | Hub-spoke with example hub deployment |
| [Standalone Example](examples/standalone/README.md) | Self-contained AI/ML environment |
| [With Existing Hub](examples/with-existing-hub/README.md) | Enterprise hub integration |
| [Deployment Scenarios](POC-SCENARIOS.md) | Decision framework and scenario comparison |
| [Authentication Guide](docs/AUTHENTICATION.md) | Detailed authentication setup |
| [Backend Configuration](docs/BACKEND_CONFIGURATION.md) | State management details |
| [Security Checklist](docs/SECURITY_CHECKLIST.md) | Security best practices |

---

## 🔍 Troubleshooting

### Common Issues

#### Authentication Errors
```bash
# Check current authentication
az account show

# Re-authenticate if needed
source ./scripts/setup-local-auth.sh
```

#### Backend Initialization Errors
```bash
# Verify storage account exists
az storage account show --name your-storage-account --resource-group terraform-state-rg-dev
```

#### Permission Issues
```bash
# Check service principal permissions
az role assignment list --assignee your-client-id --output table
```

### Getting Help

1. Check the [docs/](docs/) folder for detailed guides
2. Review Azure Activity Log for detailed error messages
3. Verify all prerequisites are installed and configured
4. Ensure you're using the correct subscription and resource group

---

## 🚦 Deployment Workflow

### Recommended Order
1. **Development**: Test changes and validate functionality
2. **Staging**: Integration testing and pre-production validation  
3. **Production**: Final deployment with change management

### Best Practices
- Always plan before applying (`terraform plan`)
- Use feature branches for development
- Require code reviews for production changes
- Monitor deployments and have rollback procedures
- Keep environments in sync with infrastructure changes

---

## 🎯 Choosing Your Deployment Scenario

### Decision Framework

**Choose Default Example if you:**
- Are learning Azure AI/ML landing zone patterns
- Need a complete development/test environment
- Want to understand hub-spoke integration
- Don't have existing platform infrastructure
- Are building proof-of-concepts

**Choose Standalone Example if you:**
- Have an isolated AI/ML workload
- Want the simplest deployment option
- Are doing rapid prototyping
- Work in a small team with limited infrastructure
- Need edge or remote deployments

**Choose With Existing Hub Example if you:**
- Have an existing platform landing zone
- Work in an enterprise environment
- Need production-ready integration
- Have multiple AI/ML workloads
- Require centralized governance and security

## 📈 Next Steps

After successful deployment:

1. **Verify Deployment**: Test AI Foundry connectivity and DNS resolution
2. **Configure Monitoring**: Set up alerts and dashboards
3. **Access Management**: Configure user access and permissions
4. **Model Deployment**: Deploy your AI/ML models to AI Foundry
5. **Integration**: Connect applications to the landing zone services
6. **Scaling**: Adjust resource sizing based on usage patterns

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in development environment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
