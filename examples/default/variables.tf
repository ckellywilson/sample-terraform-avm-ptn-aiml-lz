variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed"
  default     = "eastus2"
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID to deploy resources into."
}

variable "existing_dns_zones_rg_id" {
  type        = string
  description = "Resource group ID containing existing private DNS zones. If not provided, DNS zones will be created automatically."
  default     = null
}

variable "storage_shared_access_key_enabled" {
  type        = bool
  description = "Whether to enable shared access keys for storage accounts. When false (disabled), AI Foundry will use managed identity for storage access and appropriate RBAC roles will be assigned automatically."
  default     = false
}

variable "storage_use_azuread_authentication" {
  type        = bool
  description = "Whether to use Azure AD authentication for Terraform provider storage operations. Should be true when storage shared access keys are disabled."
  default     = true
}

variable "use_internet_routing" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
Use direct internet routing instead of firewall routing for subnets when platform landing zone is enabled.

When set to true and `flag_platform_landing_zone` is true, route tables will use NextHopType = "Internet"
for 0.0.0.0/0 traffic instead of NextHopType = "VirtualAppliance" routing through the Azure Firewall.

This setting is particularly useful for Azure Application Gateway v2 deployments that require direct
internet connectivity and cannot use virtual appliance routing.

**Security Considerations**: Enabling this setting bypasses the Azure Firewall for internet-bound traffic
from associated subnets, which may impact security posture. Ensure proper network security group rules
are in place when using this option.

**Compatibility**: This setting only applies when `flag_platform_landing_zone = true`. When
`flag_platform_landing_zone = false`, no route tables are created regardless of this setting.
DESCRIPTION
}
