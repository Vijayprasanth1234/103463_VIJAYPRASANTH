###############################################
# variables.tf - Root Variables
# 
# This file defines all variables used in the root module
# and passed to child modules
###############################################

variable "aws_region" {
  description = "AWS Region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "example-project"
}

variable "team" {
  description = "Team name for resource tagging"
  type        = string
  default     = "infrastructure"
}

variable "cost_center" {
  description = "Cost center for resource tagging and billing"
  type        = string
  default     = "infrastructure"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

# Sensitive variables that should be provided via environment variables or other secure methods
variable "db_password" {
  description = "Database password (if applicable)"
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
  default     = null
}

# Variables for EC2 instance configuration
variable "instance_type_map" {
  description = "Map of environment to instance type for right-sizing"
  type        = map(string)
  default     = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }
}

# Variables for Auto Scaling configuration
variable "min_instances_map" {
  description = "Map of environment to minimum number of instances"
  type        = map(number)
  default     = {
    dev     = 1
    staging = 2
    prod    = 3
  }
}

variable "max_instances_map" {
  description = "Map of environment to maximum number of instances"
  type        = map(number)
  default     = {
    dev     = 3
    staging = 5
    prod    = 10
  }
}

# Variables for backup configuration
variable "enable_backups" {
  description = "Whether to enable backups for resources"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

# Variables for monitoring configuration
variable "enable_enhanced_monitoring" {
  description = "Whether to enable enhanced monitoring for resources"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address to send alarms to"
  type        = string
  default     = null
}

# New variables for Secrets Manager
variable "api_keys" {
  description = "Map of API keys for external services"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function that can rotate secrets"
  type        = string
  default     = null
}

variable "enable_secret_rotation" {
  description = "Whether to enable automatic secret rotation"
  type        = bool
  default     = false
}