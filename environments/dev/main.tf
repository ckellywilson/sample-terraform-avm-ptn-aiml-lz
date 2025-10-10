module "ai_ml_landing_zone" {
  source = "../../modules/ai-ml-landing-zone"
  
  environment         = "dev"
  project_name        = "aiml-lz"
  location           = "East US 2"
  vnet_address_space = "10.0.0.0/16"
  hub_address_space  = "10.1.0.0/24"
  
  enable_diagnostic_logs = false
  purge_on_destroy      = true
  sku_tier              = "Basic"
  
  tags = {
    Environment = "Dev"
    CostCenter  = "Engineering"
    Owner       = "DevOps Team"
  }
}
