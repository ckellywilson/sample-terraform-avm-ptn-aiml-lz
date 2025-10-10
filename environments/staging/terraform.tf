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
    # Configure backend for staging environment
    resource_group_name  = "terraform-state-rg-staging"
    storage_account_name = "tfstatestagingXXXXXX"  # Replace with actual storage account
    container_name       = "tfstate"
    key                  = "staging/aiml-lz.tfstate"
  }
}

provider "azurerm" {
  features {}
}
