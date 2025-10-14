# Standalone Example - Azure AI/ML Landing Zone

This example demonstrates a configuration when the platform landing zone flag is set to true. In this case, all supporting services are included as part of AI landing zone deployment without requiring an existing hub VNet.

This is the **standalone** deployment pattern that includes:
- AI Foundry hub with project management capabilities
- Azure OpenAI model deployments (GPT-4o)
- Supporting services: Container Registry, Cosmos DB, Key Vault, Storage Account, AI Search
- Network infrastructure: VNet, Bastion, Application Gateway
- Security: Network ACLs and firewall rules

## Usage

1. Clone this repository
2. Navigate to the standalone folder: `cd standalone`
3. Initialize Terraform: `terraform init`
4. Review and customize the configuration in `main.tf` as needed
5. Plan the deployment: `terraform plan`
6. Apply the configuration: `terraform apply`

## Configuration

The example uses the latest version of the Azure AI/ML Landing Zone pattern module from the Terraform Registry. You can customize the configuration by modifying the variables in `main.tf`.

Key configuration points:
- **Location**: Set to `australiaeast` (can be changed to your preferred region)
- **Address Space**: Uses `192.168.0.0/23` for the AI/ML LZ VNet
- **Platform Landing Zone Flag**: Set to `true` (no existing hub VNet required)
- **Diagnostic Settings**: Disabled for cost optimization in testing
- **AI Model**: Deploys GPT-4o model with GlobalStandard scaling

## Prerequisites

- Azure subscription with appropriate permissions
- Terraform >= 1.9
- Azure CLI (for authentication)

## Key Features

- **Self-contained**: No dependency on existing hub infrastructure
- **Complete AI/ML stack**: Includes all necessary services for AI/ML workloads
- **Secure by default**: Network isolation and private endpoints
- **Scalable**: Supports multiple AI projects and models

## Clean Up

To destroy the resources when no longer needed:
```bash
terraform destroy
```

## Next Steps

After deployment, you can:
- Access the AI Foundry hub through the Azure portal
- Create AI projects and experiments
- Deploy additional AI models as needed
- Configure additional security and compliance settings