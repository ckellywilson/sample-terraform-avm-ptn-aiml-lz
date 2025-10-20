# AI/ML Landing Zone with Existing Hub Configuration
# Connected to sample-hub deployment: rg-hub-eus2-byx4af

# Basic Configuration
location    = "East US 2"
name_prefix = "aiml"

# Network Configuration - using different address space from hub (10.0.0.0/16)
ai_lz_vnet_address_space = "192.168.0.0/23"

# Existing Hub Configuration (from sample-hub output)
existing_hub_resource_group_name = "rg-hub-eus2-byx4af"
existing_hub_vnet_name           = "vnet-hub-eus2-byx4af"
hub_subscription_id              = "808c8f6e-4a1c-417e-9a77-db2619ce3d1a"

# Hub DNS Configuration (using DNS Private Resolver from hub)
# Replace with actual IP from hub deployment output: hub_dns_servers
hub_dns_servers = ["10.0.4.4"]  # Update with actual DNS resolver IP from hub

# Hub Firewall Configuration (for internet traffic routing)
hub_firewall_ip_address = "10.0.0.4" # Replace with actual hub firewall private IP

# VNet Peering Configuration
create_reverse_peering = false # Set to false since we don't need reverse peering for this demo

enable_hub_peering_settings = {
  allow_forwarded_traffic      = true  # Allow traffic through hub firewall
  use_remote_gateways          = false # No VPN/ExpressRoute gateway in this demo hub
  allow_gateway_transit_on_hub = true  # Future-proof for when gateways are added
}

# Private DNS Zones Configuration (using existing zones from hub)
# The example hub creates comprehensive private DNS zones for all AI/ML services
existing_private_dns_zones = {
  resource_group_name = "rg-hub-eus2-byx4af"
  blob_zone_name      = "privatelink.blob.core.windows.net"
  vault_zone_name     = "privatelink.vaultcore.azure.net"
  search_zone_name    = "privatelink.search.windows.net"
  cosmos_zone_name    = "privatelink.documents.azure.com"
  cognitive_zone_name = "privatelink.cognitiveservices.azure.com"
}

# Telemetry
enable_telemetry = true

# Tags
tags = {
  Environment    = "demo"
  Project        = "ai-ml-landing-zone"
  ManagedBy      = "terraform"
  Pattern        = "hub-spoke"
  CostCenter     = "IT-Infrastructure"
  Owner          = "platform-team"
  HubConnection  = "sample-hub-byx4af"
  DeploymentDate = "2025-10-16"
}