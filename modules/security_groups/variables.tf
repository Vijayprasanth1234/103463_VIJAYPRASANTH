###############################################
# Security Groups Module - variables.tf
# 
# Variables for the security groups module
###############################################

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
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

variable "allowed_https_cidr_blocks" {
  description = "CIDR blocks allowed for HTTPS ingress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidr_blocks" {
  description = "CIDR blocks allowed for HTTP ingress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH ingress (should be restricted)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "allow_http" {
  description = "Whether to allow HTTP traffic"
  type        = bool
  default     = false
}

variable "allow_ssh" {
  description = "Whether to allow SSH traffic"
  type        = bool
  default     = true
}