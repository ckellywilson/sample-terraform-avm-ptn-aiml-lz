# Default Example - Azure AI/ML Landing Zone

This example deploys the version of the module with the platform landing zone flag set to false. In this configuration, a sample hub VNet hosting DNS is created to mimic an existing network landing zone configuration, and the landing zone will attach to this hub VNet for all the standard network services (DNS, Hybrid Connectivity, Firewalls, etc.).

This is the **default** deployment pattern that includes:
- A sample hub VNet to mimic an existing network landing zone configuration
- AI Foundry hub with project management capabilities
- Azure OpenAI model deployments (GPT-4o)
- Supporting services: Container Registry, Cosmos DB, Key Vault, Storage Account, AI Search
- Network infrastructure: VNet peering, DNS resolution, Bastion, Application Gateway
- Security: Firewall, private DNS zones, network ACLs

## Usage

1. Clone this repository
2. Navigate to the default folder: `cd default`
3. Initialize Terraform: `terraform init`
4. Review and customize the configuration in `main.tf` as needed
5. Plan the deployment: `terraform plan`
6. Apply the configuration: `terraform apply`

## Configuration

The example uses the latest version of the Azure AI/ML Landing Zone pattern module from the Terraform Registry. You can customize the configuration by modifying the variables in `main.tf`.

Key configuration points:
- **Location**: Set to `australiaeast` (can be changed to your preferred region)
- **Address Space**: Uses `192.168.0.0/23` for the AI/ML LZ VNet and `10.10.0.0/24` for the hub VNet
- **Platform Landing Zone Flag**: Set to `false` (creates supporting services as part of the AI landing zone)
- **Diagnostic Settings**: Disabled for cost optimization in testing
- **AI Model**: Deploys GPT-4o model with GlobalStandard scaling

## Prerequisites

- Azure subscription with appropriate permissions
- Terraform >= 1.9
- Azure CLI (for authentication)

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