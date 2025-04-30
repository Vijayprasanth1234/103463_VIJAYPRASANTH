###############################################
# EC2 Module - variables.tf
# 
# Variables for the EC2 module
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

variable "instance_count" {
  description = "Number of EC2 instances to launch"
  type        = number
  default     = 2
  validation {
    condition     = var.instance_count > 0
    error_message = "Instance count must be greater than 0."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
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

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

variable "secrets_access_policy_arn" {
  description = "ARN of the IAM policy for accessing secrets"
  type        = string
  default     = null
}