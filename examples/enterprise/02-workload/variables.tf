variable "location" {
  type        = string
  description = "The Azure region where the workload resources will be deployed."
  default     = "australiaeast"
}

variable "workload_resource_group_name" {
  type        = string
  description = "The name of the resource group for workload resources. If empty, a unique name will be generated."
  default     = ""
}

variable "spoke_vnet_name" {
  type        = string
  description = "The name of the spoke virtual network."
  default     = "vnet-aiml-spoke-enterprise"
}

variable "spoke_address_space" {
  type        = string
  description = "The address space for the spoke virtual network."
  default     = "192.168.0.0/23"
}

variable "enable_telemetry" {
  type        = bool
  description = "This variable controls whether or not telemetry is enabled for the module. For more information see https://aka.ms/avm/telemetryinfo. If it is set to false, then no telemetry will be collected."
  default     = true
}

variable "purge_on_destroy" {
  type        = bool
  description = "Whether to purge AI resources on destroy."
  default     = true
}

# Hub connection configuration
variable "use_remote_state" {
  type        = bool
  description = "Whether to use remote state to reference platform resources (true) or data sources (false)."
  default     = true
}

variable "remote_state_backend" {
  type        = string
  description = "The backend type for remote state (e.g., 'local', 'azurerm')."
  default     = "local"
}

variable "remote_state_config" {
  type        = map(string)
  description = "Configuration for the remote state backend."
  default = {
    path = "../01-platform/terraform.tfstate"
  }
}

# Hub resource names for data source approach
variable "hub_virtual_network_name" {
  type        = string
  description = "Name of the hub virtual network (used when use_remote_state = false)."
  default     = ""
}

variable "hub_resource_group_name" {
  type        = string
  description = "Name of the hub resource group (used when use_remote_state = false)."
  default     = ""
}

variable "hub_firewall_name" {
  type        = string
  description = "Name of the hub firewall (used when use_remote_state = false)."
  default     = ""
}

variable "hub_firewall_ip_address" {
  type        = string
  description = "Private IP address of the hub firewall (used when use_remote_state = false)."
  default     = ""
}

variable "hub_dns_resolver_name" {
  type        = string
  description = "Name of the hub DNS resolver (used when use_remote_state = false)."
  default     = ""
}

variable "hub_dns_resolver_ips" {
  type        = map(string)
  description = "DNS resolver inbound IP addresses (used when use_remote_state = false)."
  default     = {}
}

# AI/ML Configuration
variable "ai_model_deployments" {
  type = map(object({
    name = string
    model = object({
      format  = string
      name    = string
      version = string
    })
    scale = object({
      type     = string
      capacity = number
    })
  }))
  description = "AI model deployments configuration."
  default = {
    "gpt-4o" = {
      name = "gpt-4.1"
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1"
        version = "2025-04-14"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 1
      }
    }
  }
}

variable "ai_projects" {
  type = map(object({
    name                       = string
    description                = string
    display_name               = string
    create_project_connections = bool
    cosmos_db_connection = object({
      new_resource_map_key = string
    })
    ai_search_connection = object({
      new_resource_map_key = string
    })
    storage_account_connection = object({
      new_resource_map_key = string
    })
  }))
  description = "AI projects configuration."
  default = {
    project_1 = {
      name                       = "project-1"
      description                = "Project 1 description"
      display_name               = "Project 1 Display Name"
      create_project_connections = true
      cosmos_db_connection = {
        new_resource_map_key = "this"
      }
      ai_search_connection = {
        new_resource_map_key = "this"
      }
      storage_account_connection = {
        new_resource_map_key = "this"
      }
    }
  }
}

variable "ai_search_definition" {
  type = map(object({
    enable_diagnostic_settings = bool
  }))
  description = "AI Search service configuration."
  default = {
    this = {
      enable_diagnostic_settings = false
    }
  }
}

variable "cosmosdb_definition" {
  type = map(object({
    enable_diagnostic_settings = bool
    consistency_level          = string
  }))
  description = "Cosmos DB configuration."
  default = {
    this = {
      enable_diagnostic_settings = false
      consistency_level          = "Session"
    }
  }
}

variable "key_vault_definition" {
  type = map(object({
    enable_diagnostic_settings = bool
  }))
  description = "Key Vault configuration."
  default = {
    this = {
      enable_diagnostic_settings = false
    }
  }
}

variable "storage_account_definition" {
  type = map(object({
    enable_diagnostic_settings = bool
    shared_access_key_enabled  = bool
    endpoints = map(object({
      type = string
    }))
  }))
  description = "Storage account configuration."
  default = {
    this = {
      enable_diagnostic_settings = false
      shared_access_key_enabled  = true
      endpoints = {
        blob = {
          type = "blob"
        }
      }
    }
  }
}

# Application Gateway Configuration
variable "app_gateway_definition" {
  type = object({
    backend_address_pools = map(object({
      name = string
    }))
    backend_http_settings = map(object({
      name     = string
      port     = number
      protocol = string
    }))
    frontend_ports = map(object({
      name = string
      port = number
    }))
    http_listeners = map(object({
      name               = string
      frontend_port_name = string
    }))
    request_routing_rules = map(object({
      name                       = string
      rule_type                  = string
      http_listener_name         = string
      backend_address_pool_name  = string
      backend_http_settings_name = string
      priority                   = number
    }))
  })
  description = "Application Gateway configuration."
  default = {
    backend_address_pools = {
      example_pool = {
        name = "example-backend-pool"
      }
    }
    backend_http_settings = {
      example_http_settings = {
        name     = "example-http-settings"
        port     = 80
        protocol = "Http"
      }
    }
    frontend_ports = {
      example_frontend_port = {
        name = "example-frontend-port"
        port = 80
      }
    }
    http_listeners = {
      example_listener = {
        name               = "example-listener"
        frontend_port_name = "example-frontend-port"
      }
    }
    request_routing_rules = {
      example_rule = {
        name                       = "example-rule"
        rule_type                  = "Basic"
        http_listener_name         = "example-listener"
        backend_address_pool_name  = "example-backend-pool"
        backend_http_settings_name = "example-http-settings"
        priority                   = 100
      }
    }
  }
}

# Container App Environment Configuration
variable "container_app_environment_definition" {
  type = object({
    enable_diagnostic_settings = bool
  })
  description = "Container App Environment configuration."
  default = {
    enable_diagnostic_settings = false
  }
}

# GenAI Service Configurations
variable "genai_container_registry_definition" {
  type = object({
    enable_diagnostic_settings = bool
  })
  description = "GenAI Container Registry configuration."
  default = {
    enable_diagnostic_settings = false
  }
}

variable "genai_cosmosdb_definition" {
  type = object({
    enable_diagnostic_settings = bool
    consistency_level          = string
  })
  description = "GenAI Cosmos DB configuration."
  default = {
    enable_diagnostic_settings = false
    consistency_level          = "Session"
  }
}

variable "genai_key_vault_definition" {
  type = object({
    public_network_access_enabled = bool
    network_acls = object({
      bypass   = string
      ip_rules = list(string)
    })
  })
  description = "GenAI Key Vault configuration."
  default = {
    public_network_access_enabled = true
    network_acls = {
      bypass   = "AzureServices"
      ip_rules = []
    }
  }
}

variable "genai_storage_account_definition" {
  type = object({
    enable_diagnostic_settings = bool
  })
  description = "GenAI Storage Account configuration."
  default = {
    enable_diagnostic_settings = false
  }
}

variable "ks_ai_search_definition" {
  type = object({
    enable_diagnostic_settings = bool
  })
  description = "Knowledge Store AI Search configuration."
  default = {
    enable_diagnostic_settings = false
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resources."
  default     = {}
}