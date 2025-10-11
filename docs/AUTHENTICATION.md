# Authentication Strategy: Local Development vs CI/CD

This document explains how to set up authentication for Terraform that mimics your CI/CD pipeline process.

## Overview

This setup allows you to simulate your CI/CD pipeline authentication locally:

- **Local Development**: Uses **Service Principal** (you create this)
- **CI/CD Pipeline**: Uses **Managed Identity** (automatically provided by Azure DevOps/GitHub Actions)

Since Managed Identity only works on Azure resources (like CI/CD hosted agents), we use a Service Principal locally that behaves the same way.

## Authentication Methods Comparison

| Method | Use Case | Who Creates It | Where It Works |
|--------|----------|----------------|----------------|
| **Managed Identity** | Production CI/CD | Azure DevOps/GitHub automatically | Only on Azure resources (CI/CD agents) |
| **Service Principal** | Local development | You create it | Anywhere (local, CI/CD, etc.) |
| **Azure CLI** | Interactive development | You login interactively | Local development only |

**What you need to do**: Create a Service Principal for local development. Your CI/CD pipeline will automatically get a Managed Identity.

```
┌─────────────────────┐    ┌─────────────────────┐
│   Local Development │    │    CI/CD Pipeline   │
│                     │    │                     │
│  You create:        │    │  Platform provides: │
│  📝 Service         │    │  🤖 Managed         │
│     Principal       │    │     Identity        │
│                     │    │                     │
│  Stored in:         │    │  Automatic from:    │
│  📁 .env file       │    │  🔗 Service         │
│     (not committed) │    │     Connection      │
└─────────────────────┘    └─────────────────────┘
           │                           │
           └──────── Both use ─────────┘
                   Azure AD Auth
                (Same experience!)
```

## Setup Instructions

### Step 1: Create Service Principal (One-time setup)

**You create a Service Principal** (not a managed identity) for local development:

```bash
# Login to Azure first
az login

# Create service principal and save credentials to .env file
./scripts/create-service-principal.sh your-subscription-id

# This script will:
# 1. Create a service principal with proper permissions
# 2. Save credentials securely to .env file
# 3. Configure everything for you
```

### Step 2: Use Authentication

```bash
# Load authentication (reads from .env file created above)
source ./scripts/setup-local-auth.sh

# Now you're authenticated just like CI/CD pipeline would be
```

### 2. Using .env File

For convenience, you can create a `.env` file from the template:

```bash
# Copy the template and fill in your values
cp .env.template .env
# Edit .env with your actual credentials (never commit this file)

# The setup script will automatically load from .env
source ./scripts/setup-local-auth.sh
```

## CI/CD Pipeline Configuration

**Important**: Your CI/CD pipeline will automatically get a Managed Identity - you don't create this manually!

### Azure DevOps (YAML Pipeline)
```yaml
- task: AzureCLI@2
  displayName: 'Run Terraform'
  inputs:
    azureSubscription: 'your-service-connection'  # This provides Managed Identity automatically
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # No authentication setup needed - Managed Identity is automatic
      terraform init
      terraform plan
      terraform apply -auto-approve
```

### GitHub Actions
```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}  # This sets up Managed Identity

- name: Run Terraform
  run: |
    # No authentication setup needed - Managed Identity is automatic
    terraform init
    terraform plan
    terraform apply -auto-approve
```

**Key Point**: CI/CD platforms automatically provide Managed Identity. You just configure the service connection/secrets, and the platform handles the rest.

## Security Best Practices

### Local Development
1. **Never commit credentials** - `.env` file is in `.gitignore`
2. **Rotate service principal secrets regularly**
3. **Use least privilege** - Only grant necessary permissions
4. **Store secrets securely** - Consider using Azure Key Vault

### CI/CD Pipeline
1. **Use Managed Identity when possible**
2. **Store secrets in secure vaults** (Azure Key Vault, GitHub Secrets, etc.)
3. **Implement credential rotation**
4. **Monitor authentication attempts**

## Terraform Provider Configuration

The AzureRM provider automatically detects authentication method:

```hcl
provider "azurerm" {
  features {}
  # Authentication is automatic via environment variables or managed identity
}
```

## Testing Your Setup

1. **Test Service Principal Authentication:**
```bash
source ./scripts/setup-local-auth.sh
az account show
```

2. **Test Terraform Authentication:**
```bash
terraform init
terraform plan
```

## Troubleshooting

### Common Issues

1. **"No subscription found"**
   - Ensure `ARM_SUBSCRIPTION_ID` is set correctly
   - Verify service principal has access to subscription

2. **"Insufficient privileges"**
   - Check service principal role assignments
   - Ensure proper RBAC permissions

3. **"Authentication failed"**
   - Verify service principal credentials
   - Check if client secret has expired

### Debug Commands

```bash
# Check current authentication
az account show

# List available subscriptions
az account list

# Test service principal login
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
```

## Next Steps

1. Source the authentication script: `source ./scripts/setup-local-auth.sh`
2. Create the Terraform backend storage
3. Initialize and plan your Terraform configuration
4. Set up your CI/CD pipeline with managed identity