#!/bin/bash

# Script to create and configure a service principal for Terraform
# This script creates the service principal and saves credentials securely

set -e

SUBSCRIPTION_ID=$1
SP_NAME=${2:-"terraform-aiml-lz-sp"}

if [ -z "$SUBSCRIPTION_ID" ]; then
    echo "Usage: $0 <subscription-id> [service-principal-name]"
    echo "Example: $0 12345678-1234-1234-1234-123456789012 terraform-aiml-lz-sp"
    exit 1
fi

echo "=== Creating Service Principal for Local Development ==="
echo ""
echo "📝 What this script does:"
echo "   • Creates a SERVICE PRINCIPAL (not managed identity)"
echo "   • Service Principal works for local development"
echo "   • Your CI/CD pipeline will get Managed Identity automatically"
echo ""
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Service Principal Name: $SP_NAME"
echo ""

# Ensure we're logged in
echo "Checking Azure CLI authentication..."
if ! az account show &>/dev/null; then
    echo "❌ Not logged into Azure CLI. Please run 'az login' first."
    exit 1
fi

# Set the subscription
az account set --subscription "$SUBSCRIPTION_ID"

# Create service principal
echo "Creating service principal..."
SP_OUTPUT=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role "Contributor" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --output json)

# Extract values
CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r '.appId')
CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r '.password')
TENANT_ID=$(echo "$SP_OUTPUT" | jq -r '.tenant')

echo "✅ Service principal created successfully!"
echo ""

# Add User Access Administrator role for managing storage permissions
echo "Adding User Access Administrator role..."
az role assignment create \
    --assignee "$CLIENT_ID" \
    --role "User Access Administrator" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" >/dev/null

echo "✅ Additional permissions granted!"
echo ""

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cat > .env << EOF
# Environment variables for local development that mimic CI/CD authentication
# DO NOT COMMIT THIS FILE - it contains sensitive credentials

# Service Principal Authentication (mimics CI/CD managed identity)
ARM_CLIENT_ID=$CLIENT_ID
ARM_CLIENT_SECRET=$CLIENT_SECRET
ARM_TENANT_ID=$TENANT_ID
ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID

# Terraform specific settings
ARM_USE_MSI=false
ARM_ENVIRONMENT=public

# Optional: Set default location
ARM_LOCATION=eastus2
EOF
    echo "✅ .env file created with credentials"
else
    echo "⚠️  .env file already exists. Service principal details:"
fi

echo ""
echo "🔒 Service Principal Details (save these securely):"
echo "  Client ID: $CLIENT_ID"
echo "  Tenant ID: $TENANT_ID"
echo "  Subscription ID: $SUBSCRIPTION_ID"
echo ""
echo "⚠️  IMPORTANT: The client secret has been saved to .env file"
echo "   Never commit the .env file to version control!"
echo ""
echo "✅ Setup complete! You can now run:"
echo "   source ./scripts/setup-local-auth.sh"
echo "   ./scripts/setup-azure-backend.sh dev 'East US 2' $SUBSCRIPTION_ID"
echo ""