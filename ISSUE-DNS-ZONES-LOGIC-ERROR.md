# Logic Error in `flag_platform_landing_zone` DNS Zone Resource ID Construction

## Summary
There is a logic error in `locals.networking.tf` that causes invalid DNS zone resource IDs to be constructed when `flag_platform_landing_zone = false`. This forces users to create workarounds like the `/examples/standalone/dns-zones.tf` file to provide valid DNS zone resource group IDs.

## Problem Description
In `locals.networking.tf` lines 83-85, when `flag_platform_landing_zone = false`, the module attempts to construct DNS zone resource IDs using:

```terraform
private_dns_zones_existing = var.flag_platform_landing_zone == false ? { for key, value in local.private_dns_zone_map : key => {
  name        = value.name
  resource_id = "${coalesce(var.private_dns_zones.existing_zones_resource_group_resource_id, "notused")}/providers/Microsoft.Network/privateDnsZones/${value.name}" #TODO: determine if there is a more elegant way to do this while avoiding errors
  }
} : {}
```

The use of `coalesce(..., "notused")` creates invalid resource IDs like:
`notused/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net`

## Impact
- **Deployment Failures**: When `flag_platform_landing_zone = false` and no `existing_zones_resource_group_resource_id` is provided, private endpoints fail to deploy due to invalid DNS zone resource IDs
- **Forced Workarounds**: Users must create additional Terraform resources (like `dns-zones.tf`) to provide valid DNS zone resource group IDs, even for supposedly "standalone" deployments  
- **Poor User Experience**: The "standalone" mode should be truly self-contained without requiring external DNS zone management

## Expected Behavior
When `flag_platform_landing_zone = false`:
1. The module should create its own private DNS zones automatically if none are provided
2. The module should not require users to specify `existing_zones_resource_group_resource_id`
3. The "standalone" deployment should be truly standalone without external dependencies

## Current Workaround
Users must create a separate `dns-zones.tf` file that:
- Creates a resource group for DNS zones
- Creates all required private DNS zones
- Provides the resource group ID to the main module

## Suggested Solution
The logic should be restructured to:
1. When `flag_platform_landing_zone = true`: Use platform-managed DNS zones (current behavior)
2. When `flag_platform_landing_zone = false` AND `existing_zones_resource_group_resource_id` is provided: Use existing zones
3. When `flag_platform_landing_zone = false` AND `existing_zones_resource_group_resource_id` is NOT provided: Create new DNS zones within the module

## Code Location
- **File**: `locals.networking.tf`
- **Lines**: 83-85
- **Current TODO comment**: "determine if there is a more elegant way to do this while avoiding errors"

## Additional Context
This issue affects the core value proposition of the "standalone" deployment pattern, which should be self-contained and not require external DNS zone management. The current implementation forces complexity onto users who want a simple, standalone AI/ML landing zone deployment.