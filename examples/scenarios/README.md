# Shared Deployment Scenarios

This directory contains shared scenario configuration files used across all AI/ML Landing Zone example deployments. Each `.tfvars` file defines a specific deployment scenario with different cost, complexity, and feature profiles.

## Available Scenarios

### 🔧 **minimal.tfvars**
- **Purpose**: Basic AI Foundry environment
- **Components**: AI Foundry + required services (Cosmos DB, AI Search, Storage, Key Vault)
- **Cost**: ~$300-350/month (AI Foundry pattern enforces core services)
- **Use Cases**: Learning AI Foundry, basic AI development

### 💬 **internal-chat.tfvars**  
- **Purpose**: AI-enabled internal applications
- **Components**: AI models + chat app + monitoring
- **Cost**: ~$200-400/month
- **Use Cases**: Internal team tools, development, POCs

### 🌐 **external-chat.tfvars**
- **Purpose**: Production-ready external applications
- **Components**: Full deployment + APIM + security
- **Cost**: ~$500-800/month  
- **Use Cases**: Customer-facing apps, production systems

## Usage Across Examples

These scenario files are referenced by:
- `/examples/standalone/` - Standalone AI/ML Landing Zone
- `/examples/default/` - Hub-spoke with example hub (future)
- `/examples/enterprise/` - Enterprise deployment patterns (future)

## Extending Scenarios

To add new scenarios:
1. Create a new `.tfvars` file in this directory
2. Define the scenario variables following the existing pattern
3. Update deployment documentation in each example
4. Test with the target deployment example

## Variable Structure

Each scenario file should include:
```hcl
# Environment Configuration
environment_suffix = "scenario-name"
azure_location = "eastus2"

# Feature Flags
enable_telemetry = true
enable_diagnostic_settings = true/false
storage_shared_access_key_enabled = false

# Deployment Controls (these actually work)
deploy_ai_models = true/false
deploy_ai_projects = true/false
enable_apim = true/false
enable_app_gateway = true/false
enable_bastion = true/false
enable_build_vm = true/false
enable_jump_vm = true/false

# Settings
ai_model_capacity = 1/2

# Note: Cosmos DB, AI Search, and Container Registry are always deployed by AI Foundry pattern
```

## Maintenance

- Keep scenarios synchronized across different infrastructure patterns
- Test scenario files with multiple deployment examples
- Update cost estimates quarterly based on Azure pricing
- Document breaking changes in scenario file comments