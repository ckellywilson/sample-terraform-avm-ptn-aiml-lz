# Staging Environment

This directory contains the Terraform configuration for the Staging environment of the Azure AI/ML Landing Zone.

## Configuration

- **Location**: Central US
- **VNet Address Space**: 10.10.0.0/16
- **Hub Address Space**: 10.11.0.0/24
- **SKU Tier**: Standard
- **Diagnostic Logs**: true
- **Purge on Destroy**: false

## Usage

```bash
cd environments/staging
terraform init
terraform plan
terraform apply
```

## Backend Configuration

Update the storage account name in `terraform.tf` before running `terraform init`.
