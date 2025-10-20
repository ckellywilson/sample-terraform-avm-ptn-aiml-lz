# Sample Hub Infrastructure Configuration
# Deployment for subscription: ME-MngEnv496195-chwil-2

# Basic Configuration
location       = "East US 2"
location_short = "eus2"

# Network Address Planning
# Hub network with separate address space from AI/ML workloads
hub_address_space   = "10.0.0.0/16"    # Hub network (65,536 addresses)
ai_ml_address_space = "192.168.0.0/22" # AI/ML networks for firewall rules (1,024 addresses)

# Azure Firewall Configuration
# Standard tier provides good balance of features and cost (~$693/month)
firewall_sku = "Standard"

# DNS Configuration
# Using Azure default DNS for simplicity
custom_dns_servers = []

# Private DNS Zones
# Create centralized private DNS zones in the hub
create_private_dns_zones = true

# Monitoring
# Enable Log Analytics for monitoring and diagnostics
create_log_analytics = true

# Resource Tags
tags = {
  Environment    = "hub"
  Project        = "ai-ml-platform"
  ManagedBy      = "terraform"
  CostCenter     = "IT-Infrastructure"
  Owner          = "platform-team"
  Pattern        = "azure-landing-zone"
  DeploymentDate = "2025-10-15"
  Purpose        = "hub-infrastructure"
}

# Example configurations for different environments:

# DEVELOPMENT ENVIRONMENT
# Uncomment and modify for development scenarios:
# firewall_sku             = "Basic"           # Lower cost option
# create_log_analytics     = false            # Reduce costs
# hub_address_space        = "10.10.0.0/24"   # Smaller address space
# ai_ml_address_space      = "10.11.0.0/24"   # Adjacent address space

# PRODUCTION ENVIRONMENT  
# Uncomment and modify for production scenarios:
# firewall_sku             = "Premium"        # Enhanced security features
# create_log_analytics     = true             # Enhanced monitoring
# custom_dns_servers       = ["10.0.1.4", "10.0.1.5"]  # Enterprise DNS servers
# hub_address_space        = "10.0.0.0/16"    # Large address space for growth
# ai_ml_address_space      = "192.168.0.0/20" # Larger space for multiple AI/ML LZs

# MULTI-REGION DEPLOYMENT
# Example for multi-region hub deployment:
# location                 = "West Europe"
# location_short           = "weu"  
# hub_address_space        = "10.1.0.0/16"    # Different region address space
# ai_ml_address_space      = "192.169.0.0/22" # Different region AI/ML space