# Azure AI/ML Landing Zone

A simplified example repository demonstrating the Azure AI/ML Landing Zone pattern using Azure Verified Modules (AVM).

## Structure

- `examples/standalone/` - True standalone deployment of AI/ML Landing Zone without hub dependencies
- `examples/default/` - Example deployment that integrates with an existing hub VNet
- `modules/example_hub_vnet/` - Supporting hub VNet module for the default example

## Getting Started

### Deploy with Azure Developer CLI (azd)

This repository can be provisioned using the Azure Developer CLI against the Terraform configuration in `examples/default`.

1. Install azd: https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd
2. Authenticate: `az login` (ensure the correct subscription is selected) and optionally `az account set --subscription <id>`.
3. Initialize the project (non-interactive): `azd init --no-prompt` (uses existing `azure.yaml`).
4. Create an environment: `azd env new default`.
5. Copy `.azure/.env.sample` to `.azure/env/default/.env` and set `AZURE_SUBSCRIPTION_ID` plus any optional values.
6. Provision infrastructure: `azd provision` (runs Terraform init/plan/apply under the hood).

To destroy resources later run: `azd down`.

Notes:
- Remote state is not yet configured; for team usage introduce an Azure Storage backend and update Terraform accordingly.
- The `services` section in `azure.yaml` is empty because this sample focuses on infrastructure only.
- Add additional `TF_VAR_` mappings in `.azure/.env` as new variables are introduced.
