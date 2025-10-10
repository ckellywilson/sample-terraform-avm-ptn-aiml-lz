# prod environment specific values
ai_model_capacity = 1
enable_advanced_features = false

# Override default project settings for prod
project_specific_settings = {
  enable_monitoring = true
  backup_retention_days = 30
  auto_scaling_enabled = true
}
