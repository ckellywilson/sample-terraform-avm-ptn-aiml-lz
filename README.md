# Azure AI/ML Landing Zone - Multi-Environment Setup

🚀 **Production-ready Azure AI/ML infrastructure with automated CI/CD pipelines**

## 🎯 Quick Decision Guide

**New to Azure Landing Zones?** → Start with [Standalone Application](examples/standalone-application/)  
**Have existing hub infrastructure?** → Use [Cross-Subscription Hub-Spoke](examples/cross-subscription-hub-spoke/)  
**Need to deploy hub first?** → Deploy [Hub Connectivity](examples/hub-connectivity-deployment/) then spoke  
**Want simple hub-spoke?** → Use [Single-Subscription Hub-Spoke](examples/single-subscription-hub-spoke/)  

📖 **Full scenario guidance**: [POC-SCENARIOS.md](POC-SCENARIOS.md)

## 📋 What This Repository Provides

- **Multi-Environment Setup**: Separate dev, staging, and prod configurations
- **Secure Authentication**: Service Principal for local dev, Managed Identity for CI/CD
- **State Management**: Secure Azure Storage backend with Azure AD authentication
- **CI/CD Ready**: Pre-configured pipelines for Azure DevOps and GitHub Actions
- **Best Practices**: Security, naming conventions, and infrastructure as code

## 🏗️ Architecture

This implementation follows the Azure AI/ML Landing Zone pattern:

- **AI Foundry Hub**: Central AI/ML workspace with GPT-4o model deployment
- **Network Foundation**: Hub-spoke topology with private endpoints
- **Supporting Services**: Container Registry, Cosmos DB, Key Vault, Storage, AI Search
- **Security**: Private DNS zones, VNet integration, Azure AD authentication
- **Monitoring**: Application Insights and Log Analytics integration

## 📁 Repository Structure

```
├── environments/          # Environment-specific configurations
│   ├── dev/              # Development environment
│   ├── staging/          # Staging environment
│   └── prod/             # Production environment
├── modules/              # Reusable Terraform modules
│   └── ai-ml-landing-zone/
├── scripts/              # Automation scripts
├── .github/workflows/    # GitHub Actions pipelines
├── azure-pipelines/      # Azure DevOps pipelines
└── docs/                 # Documentation
```

---

## 🚀 Quick Start Guide

Choose your deployment scenario based on your organizational needs:

## 📋 Deployment Scenarios

### 🏢 **Scenario 1: Cross-Subscription Hub-Spoke** ⭐ **RECOMMENDED FOR ENTERPRISE**
Perfect for large organizations following Azure Landing Zone best practices.

**Architecture**: Hub (Connectivity) + Spoke (Application) subscriptions  
**Use Cases**: Enterprise production, regulated industries, multi-tenant platforms  
**Features**: Centralized governance, cost optimization, hybrid connectivity  

**Deployment Steps**:
```bash
# Step 1: Deploy Hub Infrastructure (Platform Team)
cd examples/hub-connectivity-deployment
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your hub subscription ID
terraform init && terraform apply

# Step 2: Deploy AI/ML Spoke (Application Team)  
cd ../cross-subscription-hub-spoke
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with spoke subscription ID and hub outputs
terraform init && terraform apply
```

### 🏬 **Scenario 2: Single-Subscription Hub-Spoke**
Good for mid-size organizations testing hub-spoke concepts.

**Architecture**: Hub and spoke within same subscription  
**Use Cases**: Testing hub-spoke patterns, limited scope deployments  
**Features**: Simplified RBAC, reduced complexity  

**Deployment Steps**:
```bash
cd examples/single-subscription-hub-spoke
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

### 🏪 **Scenario 3: Standalone Application**  
Ideal for independent workloads or edge deployments.

**Architecture**: Self-contained deployment  
**Use Cases**: Edge deployments, pilot projects, isolated workloads  
**Features**: Complete independence, quick setup  

**Deployment Steps**:
```bash
cd examples/standalone-application
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

## 📊 Scenario Comparison

| Aspect | Cross-Subscription Hub-Spoke | Single-Subscription Hub-Spoke | Standalone Application |
|--------|------------------------------|-------------------------------|------------------------|
| **Complexity** | High | Medium | Low |
| **Enterprise Readiness** | ✅ Production Ready | 🟡 Limited Scale | ❌ POC Only |
| **Cost Efficiency** | ✅ Optimized | 🟡 Moderate | ❌ Higher per workload |
| **Governance** | ✅ Centralized | 🟡 Subscription-level | ❌ Workload-level |
| **Setup Time** | ❌ Complex | 🟡 Moderate | ✅ Quick |

### 🖥️ Multi-Environment Setup (Optional)

For organizations wanting full DevOps lifecycle management:

#### Step 1: Prerequisites
```bash
# Ensure you have required tools
az --version          # Azure CLI >= 2.0
terraform --version   # Terraform >= 1.9
```

#### Step 2: Authentication Setup
```bash
# 1. Login to Azure
az login

# 2. Create Service Principal for local development
# Replace 'your-subscription-id' with your actual subscription ID
./scripts/create-service-principal.sh your-subscription-id

# 3. Load authentication environment
source ./scripts/setup-local-auth.sh
```

#### Step 3: Backend Storage Setup
```bash
# Create secure state storage for all environments
./scripts/setup-azure-backend.sh dev "East US 2" your-subscription-id
./scripts/setup-azure-backend.sh staging "East US 2" your-subscription-id
./scripts/setup-azure-backend.sh prod "East US 2" your-subscription-id
```

#### Step 4: Deploy Infrastructure
```bash
# Choose your deployment scenario first (see scenarios above)
# Then deploy to development environment
cd environments/dev
terraform init
terraform plan
terraform apply

# Repeat for other environments as needed
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
| [POC Scenarios](POC-SCENARIOS.md) | Complete deployment scenarios guide |
| [Hub Connectivity](examples/hub-connectivity-deployment/README.md) | Azure Verified Module hub deployment |
| [Cross-Subscription Hub-Spoke](examples/cross-subscription-hub-spoke/README.md) | Enterprise hub-spoke pattern |
| [Single-Subscription Hub-Spoke](examples/single-subscription-hub-spoke/README.md) | Simplified hub-spoke pattern |
| [Standalone Application](examples/standalone-application/README.md) | Independent deployment pattern |
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

**Choose Cross-Subscription Hub-Spoke if you have:**
- Enterprise organization (1000+ users)
- High compliance requirements (Banking, Healthcare)
- Multiple AI/ML workloads (>5)
- Advanced platform teams
- Need for centralized governance

**Choose Single-Subscription Hub-Spoke if you have:**
- Mid-size organization (100-1000 users)  
- Medium compliance requirements
- Few AI/ML workloads (2-5)
- Growing DevOps capabilities
- Want to test hub-spoke concepts

**Choose Standalone Application if you have:**
- Small organization (<100 users)
- Low compliance requirements
- Single AI/ML workload
- Application team ownership
- Edge/remote deployment needs

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
