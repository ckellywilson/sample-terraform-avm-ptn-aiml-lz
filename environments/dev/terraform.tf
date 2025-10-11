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
  
  backend "azurerm" {
    # Configure backend for dev environment
    resource_group_name  = "terraform-state-rg-dev"
    storage_account_name = "tfstatedev185492"
    container_name       = "tfstate"
    key                  = "dev/aiml-lz.tfstate"
    use_azuread_auth     = true  # Use Azure AD authentication instead of storage keys
  }
}

provider "azurerm" {
  features {}
}
