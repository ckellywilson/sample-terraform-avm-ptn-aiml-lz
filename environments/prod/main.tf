module "ai_ml_landing_zone" {
  source = "../../modules/ai-ml-landing-zone"
  
  environment         = "prod"
  project_name        = "aiml-lz"
  location           = "West US 2"
  vnet_address_space = "10.20.0.0/16"
  hub_address_space  = "10.21.0.0/24"
  
  enable_diagnostic_logs = true
  purge_on_destroy      = false
  sku_tier              = "Premium"
  
  tags = {
    Environment = "Prod"
    CostCenter  = "Business"
    Owner       = "Platform Team"
  }
}
