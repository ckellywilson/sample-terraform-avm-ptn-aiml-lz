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
    # Configure backend for prod environment
    resource_group_name  = "terraform-state-rg-prod"
    storage_account_name = "tfstateprod185873"
    container_name       = "tfstate"
    key                  = "prod/aiml-lz.tfstate"
    use_azuread_auth     = true  # Use Azure AD authentication instead of storage keys
  }
}

provider "azurerm" {
  features {}
}
