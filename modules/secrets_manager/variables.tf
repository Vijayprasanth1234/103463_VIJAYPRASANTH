###############################################
# secrets_manager/variables.tf - Variables for Secrets Manager Module
# 
# This file defines all variables used in the secrets manager module
###############################################

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret"
  type        = number
  default     = 30
}

# Database credentials
variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Database host"
  type        = string
  default     = "localhost"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "mydb"
}

# Application secrets
variable "alarm_email" {
  description = "Email address to send alarms to"
  type        = string
  default     = null
}

variable "api_keys" {
  description = "Map of API keys for external services"
  type        = map(string)
  default     = {}
  sensitive   = true
}

# Secret rotation configuration
variable "enable_rotation" {
  description = "Whether to enable automatic secret rotation"
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function that can rotate the secret"
  type        = string
  default     = null
}

variable "rotation_days" {
  description = "Number of days after which the secret is rotated automatically"
  type        = number
  default     = 30
}