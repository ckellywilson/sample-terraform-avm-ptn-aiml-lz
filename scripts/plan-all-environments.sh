#!/bin/bash

# Script to run terraform plan for all environments
set -e

for env in dev staging prod; do
    echo "📋 Planning $env environment..."
    cd "environments/$env"
    terraform init
    terraform plan -out="tfplan-$env"
    cd - > /dev/null
    echo "✅ Plan complete for $env"
    echo ""
done

echo "🎉 All environment plans complete!"
echo "Plans saved as tfplan-<environment> in each environment directory"
