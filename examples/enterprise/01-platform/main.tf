terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.3.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

# Platform team deploys hub infrastructure
module "connectivity_hub" {
  source = "../../../modules/example_hub_vnet"

  deployer_ip_address = "${data.http.ip.response_body}/32"
  location            = var.location
  resource_group_name = var.platform_resource_group_name != "" ? var.platform_resource_group_name : "rg-platform-hub-${module.naming.resource_group.name_unique}"
  vnet_definition = {
    address_space = var.hub_address_space
  }
  enable_telemetry = var.enable_telemetry
  name_prefix      = var.hub_name_prefix != "" ? var.hub_name_prefix : "${module.naming.resource_group.name_unique}-hub"
  
  jump_vm_definition = var.jump_vm_definition
  tags = var.tags
}