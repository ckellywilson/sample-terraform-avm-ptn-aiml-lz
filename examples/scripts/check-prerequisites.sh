#!/bin/bash

# AI/ML Landing Zone Prerequisites Check Script
# This script validates that all required Azure resource providers are registered
# before deploying the AI/ML Landing Zone infrastructure.

set -e  # Exit on any error

echo "🔍 AI/ML Landing Zone Prerequisites Check"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Required resource providers for AI/ML Landing Zone
REQUIRED_PROVIDERS=(
    "Microsoft.CognitiveServices"    # AI Foundry, AI Services
    "Microsoft.MachineLearningServices" # AI Foundry workspace
    "Microsoft.Storage"              # Storage accounts
    "Microsoft.KeyVault"             # Key Vault
    "Microsoft.DocumentDB"           # Cosmos DB
    "Microsoft.Search"               # AI Search
    "Microsoft.ContainerRegistry"    # Container Registry
    "Microsoft.App"                  # Container Apps
    "Microsoft.Network"              # VNet, Bastion, App Gateway
    "Microsoft.Compute"              # Build VM, Jump VM (if enabled)
    "Microsoft.Web"                  # Application Gateway
    "Microsoft.Insights"             # Monitoring and diagnostics
    "Microsoft.OperationalInsights"  # Log Analytics
)

# Optional providers (for enhanced features)
OPTIONAL_PROVIDERS=(
    "Microsoft.EventHub"             # Event streaming (optional)
    "Microsoft.ServiceBus"           # Messaging (optional)
    "Microsoft.DataFactory"          # Data integration (optional)
)

# Special features that require registration
SPECIAL_FEATURES=(
    "Microsoft.Compute/EncryptionAtHost"  # For Build VM and Jump VM encryption
)

echo "🔧 Checking Azure CLI authentication..."
if ! az account show >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not authenticated with Azure CLI${NC}"
    echo "   Please run: az login"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo -e "${GREEN}✅ Authenticated${NC}"
echo "   Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo ""

echo "🔍 Checking required resource providers..."
MISSING_PROVIDERS=()
UNREGISTERED_PROVIDERS=()

for provider in "${REQUIRED_PROVIDERS[@]}"; do
    echo -n "   Checking $provider... "
    
    # Check if provider is registered
    status=$(az provider show --namespace "$provider" --query registrationState -o tsv 2>/dev/null || echo "NotFound")
    
    case $status in
        "Registered")
            echo -e "${GREEN}✅ Registered${NC}"
            ;;
        "Registering")
            echo -e "${YELLOW}⏳ Registering (in progress)${NC}"
            UNREGISTERED_PROVIDERS+=("$provider")
            ;;
        "NotRegistered")
            echo -e "${RED}❌ Not Registered${NC}"
            MISSING_PROVIDERS+=("$provider")
            ;;
        "NotFound")
            echo -e "${RED}❌ Provider not found${NC}"
            MISSING_PROVIDERS+=("$provider")
            ;;
        *)
            echo -e "${YELLOW}⚠️  Unknown status: $status${NC}"
            UNREGISTERED_PROVIDERS+=("$provider")
            ;;
    esac
done

echo ""
echo "🔍 Checking optional resource providers..."
MISSING_OPTIONAL=()

for provider in "${OPTIONAL_PROVIDERS[@]}"; do
    echo -n "   Checking $provider... "
    
    status=$(az provider show --namespace "$provider" --query registrationState -o tsv 2>/dev/null || echo "NotFound")
    
    case $status in
        "Registered")
            echo -e "${GREEN}✅ Registered${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️  Not registered (optional)${NC}"
            MISSING_OPTIONAL+=("$provider")
            ;;
    esac
done

echo ""
echo "🔍 Checking special features..."

# Check EncryptionAtHost feature
echo -n "   Checking EncryptionAtHost feature... "
encryption_status=$(az feature show --namespace Microsoft.Compute --name EncryptionAtHost --query properties.state -o tsv 2>/dev/null || echo "NotFound")
encryption_feature_missing=false

case $encryption_status in
    "Registered")
        echo -e "${GREEN}✅ Registered${NC}"
        # Verify Microsoft.Compute provider is re-registered after feature registration
        echo -n "   Verifying Microsoft.Compute provider propagation... "
        compute_provider_state=$(az provider show --namespace Microsoft.Compute --query registrationState -o tsv 2>/dev/null || echo "NotFound")
        if [ "$compute_provider_state" == "Registered" ]; then
            echo -e "${GREEN}✅ Propagated${NC}"
        else
            echo -e "${YELLOW}⚠️  Provider needs re-registration${NC}"
            echo -e "${YELLOW}   Run: az provider register --namespace Microsoft.Compute --wait${NC}"
        fi
        ;;
    "Registering")
        echo -e "${YELLOW}⏳ Registering (in progress)${NC}"
        encryption_feature_missing=true
        ;;
    "NotRegistered"|"NotFound")
        echo -e "${RED}❌ Not registered (REQUIRED for Build/Jump VMs)${NC}"
        encryption_feature_missing=true
        ;;
    *)
        echo -e "${YELLOW}⚠️  Unknown status: $encryption_status${NC}"
        encryption_feature_missing=true
        ;;
esac

echo ""
echo "📊 Summary"
echo "=========="

if [ ${#MISSING_PROVIDERS[@]} -eq 0 ] && [ ${#UNREGISTERED_PROVIDERS[@]} -eq 0 ] && [ "$encryption_feature_missing" == "false" ]; then
    echo -e "${GREEN}✅ All required resource providers and features are registered!${NC}"
    echo "   Your subscription is ready for AI/ML Landing Zone deployment."
else
    echo -e "${RED}❌ Missing or unregistered resource providers/features found${NC}"
    
    if [ ${#MISSING_PROVIDERS[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Missing required providers:${NC}"
        for provider in "${MISSING_PROVIDERS[@]}"; do
            echo "   - $provider"
        done
    fi
    
    if [ ${#UNREGISTERED_PROVIDERS[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Providers currently registering:${NC}"
        for provider in "${UNREGISTERED_PROVIDERS[@]}"; do
            echo "   - $provider"
        done
    fi
fi

if [ ${#MISSING_OPTIONAL[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Optional providers not registered:${NC}"
    for provider in "${MISSING_OPTIONAL[@]}"; do
        echo "   - $provider"
    done
    echo "   These are not required but may provide additional functionality."
fi

echo ""
echo "🚀 Next Steps"
echo "============"

if [ ${#MISSING_PROVIDERS[@]} -gt 0 ]; then
    echo -e "${BLUE}To register missing required providers:${NC}"
    echo ""
    for provider in "${MISSING_PROVIDERS[@]}"; do
        echo "   az provider register --namespace $provider"
    done
    echo ""
    echo "   Then wait for registration to complete (may take several minutes):"
    for provider in "${MISSING_PROVIDERS[@]}"; do
        echo "   az provider show --namespace $provider --query registrationState"
    done
    echo ""
fi

if [ "$encryption_feature_missing" == "true" ]; then
    echo -e "${BLUE}To enable EncryptionAtHost feature (required for Build/Jump VMs):${NC}"
    echo ""
    echo "   # Step 1: Register the feature"
    echo "   az feature register --namespace Microsoft.Compute --name EncryptionAtHost"
    echo ""
    echo "   # Step 2: Wait for registration (check status)"
    echo "   az feature show --namespace Microsoft.Compute --name EncryptionAtHost --query properties.state"
    echo ""
    echo "   # Step 3: Re-register the provider to propagate the feature"
    echo "   az provider register --namespace Microsoft.Compute --wait"
    echo ""
fi

if [ ${#MISSING_PROVIDERS[@]} -eq 0 ] && [ ${#UNREGISTERED_PROVIDERS[@]} -eq 0 ] && [ "$encryption_feature_missing" == "false" ]; then
    echo -e "${GREEN}🎉 Ready to deploy!${NC}"
    echo "   Run: azd provision"
    exit 0
else
    echo -e "${YELLOW}⚠️  Complete provider/feature registration before deployment${NC}"
    exit 1
fi