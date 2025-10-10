# Dev Environment

This directory contains the Terraform configuration for the Dev environment of the Azure AI/ML Landing Zone.

## Configuration

- **Location**: East US 2
- **VNet Address Space**: 10.0.0.0/16
- **Hub Address Space**: 10.1.0.0/24
- **SKU Tier**: Basic
- **Diagnostic Logs**: false
- **Purge on Destroy**: true

## Usage

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

## Backend Configuration

Update the storage account name in `terraform.tf` before running `terraform init`.
