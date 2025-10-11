#!/bin/bash

# Script to set up local authentication that mimics CI/CD managed identity process
# This uses a service principal with environment variables, similar to how CI/CD pipelines work

echo "=== Azure Authentication Setup for Local Development ==="
echo ""
echo "This script sets up authentication that mimics your CI/CD pipeline process."
echo "It uses a service principal with environment variables instead of Azure CLI login."
echo ""

# Load Service Principal credentials from .env file or environment variables
if [ -f ".env" ]; then
    echo "Loading credentials from .env file..."
    set -a
    source .env
    set +a
elif [ -z "$ARM_CLIENT_ID" ] || [ -z "$ARM_CLIENT_SECRET" ] || [ -z "$ARM_TENANT_ID" ] || [ -z "$ARM_SUBSCRIPTION_ID" ]; then
    echo "❌ Error: Missing required environment variables"
    echo ""
    echo "Please set the following environment variables or create a .env file:"
    echo "  ARM_CLIENT_ID=your-service-principal-client-id"
    echo "  ARM_CLIENT_SECRET=your-service-principal-client-secret"
    echo "  ARM_TENANT_ID=your-tenant-id"
    echo "  ARM_SUBSCRIPTION_ID=your-subscription-id"
    echo ""
    echo "Example .env file:"
    echo "  ARM_CLIENT_ID=12345678-1234-1234-1234-123456789012"
    echo "  ARM_CLIENT_SECRET=your-secret-here"
    echo "  ARM_TENANT_ID=87654321-4321-4321-4321-210987654321"
    echo "  ARM_SUBSCRIPTION_ID=11111111-2222-3333-4444-555555555555"
    return 1
fi

# Additional Terraform environment variables
export ARM_USE_MSI=false
export ARM_ENVIRONMENT=public

echo "✅ Environment variables set for Service Principal authentication"
echo ""
echo "Active Configuration:"
echo "  Client ID: $ARM_CLIENT_ID"
echo "  Tenant ID: $ARM_TENANT_ID"
echo "  Subscription ID: $ARM_SUBSCRIPTION_ID"
echo ""
echo "🔒 This mimics how your CI/CD pipeline will authenticate using managed identity"
echo "   (but uses service principal since managed identity isn't available locally)"
echo ""
echo "Usage:"
echo "  source ./scripts/setup-local-auth.sh"
echo "  terraform init"
echo "  terraform plan"
echo ""

# Test the authentication
echo "Testing authentication..."
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
echo ""
echo "✅ Authentication test successful!"