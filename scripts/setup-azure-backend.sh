#!/bin/bash

# Script to set up Azure Storage for Terraform backend
# Usage: ./scripts/setup-azure-backend.sh <environment> <location> <subscription-id>

set -e

ENVIRONMENT=$1
LOCATION=${2:-"East US 2"}
SUBSCRIPTION_ID=$3

if [ -z "$ENVIRONMENT" ] || [ -z "$SUBSCRIPTION_ID" ]; then
    echo "Usage: $0 <environment> [location] <subscription-id>"
    echo "Example: $0 dev 'East US 2' 12345678-1234-1234-1234-123456789012"
    exit 1
fi

# Set subscription
az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group for Terraform state
RG_NAME="terraform-state-rg-${ENVIRONMENT}"
az group create --name "$RG_NAME" --location "$LOCATION"

# Generate unique storage account name
STORAGE_NAME="tfstate${ENVIRONMENT}$(date +%s | tail -c 7)"
echo "Creating storage account: $STORAGE_NAME"

# Create storage account
az storage account create \
    --resource-group "$RG_NAME" \
    --name "$STORAGE_NAME" \
    --sku Standard_LRS \
    --encryption-services blob

# Create container
az storage container create \
    --name tfstate \
    --account-name "$STORAGE_NAME"

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "Update your environments/${ENVIRONMENT}/terraform.tf with:"
echo "  storage_account_name = \"$STORAGE_NAME\""
echo ""
echo "Storage account details:"
echo "  Resource Group: $RG_NAME"
echo "  Storage Account: $STORAGE_NAME"
echo "  Container: tfstate"
