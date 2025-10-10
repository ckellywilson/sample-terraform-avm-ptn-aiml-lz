# Prod Environment

This directory contains the Terraform configuration for the Prod environment of the Azure AI/ML Landing Zone.

## Configuration

- **Location**: West US 2
- **VNet Address Space**: 10.20.0.0/16
- **Hub Address Space**: 10.21.0.0/24
- **SKU Tier**: Premium
- **Diagnostic Logs**: true
- **Purge on Destroy**: false

## Usage

```bash
cd environments/prod
terraform init
terraform plan
terraform apply
```

## Backend Configuration

Update the storage account name in `terraform.tf` before running `terraform init`.
