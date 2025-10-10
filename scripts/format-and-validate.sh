#!/bin/bash

# Script to format and validate all Terraform configurations
set -e

echo "🔧 Formatting Terraform files..."
terraform fmt -recursive .

echo "🔍 Validating Terraform configurations..."
for env in dev staging prod; do
    echo "Validating $env environment..."
    cd "environments/$env"
    terraform init -backend=false
    terraform validate
    cd - > /dev/null
done

echo "✅ All validations passed!"
