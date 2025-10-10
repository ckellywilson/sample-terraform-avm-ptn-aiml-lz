# Environment-specific variable overrides
variable "ai_model_capacity" {
  type        = number
  description = "Capacity for AI model deployments"
  default     = 1
}

variable "enable_advanced_features" {
  type        = bool
  description = "Enable advanced features"
  default     = false
}
