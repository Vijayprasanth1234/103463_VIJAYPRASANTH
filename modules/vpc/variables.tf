###############################################
# VPC Module - variables.tf
# 
# Variables for the VPC module
###############################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
  validation {
    condition     = var.az_count > 1
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs"
  type        = bool
  default     = true
}