module "ai_ml_landing_zone" {
  source = "../../modules/ai-ml-landing-zone"
  
  environment         = "staging"
  project_name        = "aiml-lz"
  location           = "Central US"
  vnet_address_space = "10.10.0.0/16"
  hub_address_space  = "10.11.0.0/24"
  
  enable_diagnostic_logs = true
  purge_on_destroy      = false
  sku_tier              = "Standard"
  
  tags = {
    Environment = "Staging"
    CostCenter  = "Engineering"
    Owner       = "QA Team"
  }
}
