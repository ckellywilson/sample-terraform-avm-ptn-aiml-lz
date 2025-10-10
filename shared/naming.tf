# Consistent naming convention across environments
# This file serves as a REFERENCE for naming patterns used in this project
# It is NOT intended to be used as a module, but as documentation

# Example naming conventions that are implemented in the main module:
#
# resource_group = "${var.project_name}-rg-${var.environment}-${random_suffix}"
# vnet          = "${var.project_name}-vnet-${var.environment}"
# hub_vnet      = "${var.project_name}-hub-vnet-${var.environment}"
# ai_foundry    = "${var.project_name}-aif-${var.environment}"
# key_vault     = "${var.project_name}kv${var.environment}${random_suffix}"
# storage       = "${var.project_name}st${var.environment}${random_suffix}"
#
# Where:
# - project_name: "aiml-lz" (default)
# - environment: "dev", "staging", "prod"
# - random_suffix: 6-character random string for uniqueness
#
# Examples:
# Dev Environment:
#   - Resource Group: "aiml-lz-rg-dev-abc123"
#   - VNet: "aiml-lz-vnet-dev"
#   - Key Vault: "aimlLzkv-dev-abc123"
#
# Production Environment:
#   - Resource Group: "aiml-lz-rg-prod-xyz789"
#   - VNet: "aiml-lz-vnet-prod" 
#   - Key Vault: "aimlLzkv-prod-xyz789"
