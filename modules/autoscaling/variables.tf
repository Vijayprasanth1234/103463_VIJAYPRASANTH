###############################################
# Autoscaling Module - variables.tf
# 
# Variables for the autoscaling module
###############################################

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "List of subnet IDs where EC2 instances will be launched"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to EC2 instances"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 2
  validation {
    condition     = var.min_size > 0
    error_message = "Minimum size must be greater than 0."
  }
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 10
  validation {
    condition     = var.max_size >= 2
    error_message = "Maximum size must be at least 2 for high availability."
  }
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 2
  validation {
    condition     = var.desired_capacity > 0
    error_message = "Desired capacity must be greater than 0."
  }
}

variable "health_check_type" {
  description = "Health check type for the Auto Scaling Group (EC2 or ELB)"
  type        = string
  default     = "ELB"
  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Health check type must be either EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "target_group_arns" {
  description = "List of target group ARNs for the Auto Scaling Group"
  type        = list(string)
  default     = []
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "create_ebs_volume" {
  description = "Whether to create an additional EBS volume"
  type        = bool
  default     = false
}

variable "ebs_volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp3"
}

variable "ebs_volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 50
}

variable "kms_key_id" {
  description = "KMS key ID for EBS encryption"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script for EC2 instances"
  type        = string
  default     = ""
}

variable "scale_out_threshold" {
  description = "CPU utilization threshold for scaling out"
  type        = number
  default     = 70
}

variable "scale_in_threshold" {
  description = "CPU utilization threshold for scaling in"
  type        = number
  default     = 30
}

variable "secrets_access_policy_arn" {
  description = "ARN of the IAM policy for accessing secrets"
  type        = string
  default     = null
}