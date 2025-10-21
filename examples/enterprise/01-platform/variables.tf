variable "location" {
  type        = string
  description = "The Azure region where the platform resources will be deployed."
  default     = "australiaeast"
}

variable "platform_resource_group_name" {
  type        = string
  description = "The name of the resource group for platform resources. If empty, a unique name will be generated."
  default     = ""
}

variable "hub_address_space" {
  type        = string
  description = "The address space for the hub virtual network."
  default     = "10.10.0.0/24"
}

variable "hub_name_prefix" {
  type        = string
  description = "The name prefix for hub resources. If empty, a unique name will be generated."
  default     = ""
}

variable "enable_telemetry" {
  type        = bool
  description = "This variable controls whether or not telemetry is enabled for the module. For more information see https://aka.ms/avm/telemetryinfo. If it is set to false, then no telemetry will be collected."
  default     = true
}

variable "jump_vm_definition" {
  type = object({
    sku  = optional(string, "Standard_D2s_v3")
    tags = optional(map(string), {})
  })
  description = "Configuration for the jump VM in the hub network."
  default = {
    sku  = "Standard_D2s_v3"
    tags = {}
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resources."
  default     = {}
}