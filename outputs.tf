###############################################
# outputs.tf - Root Outputs
# 
# This file defines all outputs from the root module
# that are useful for users of this Terraform configuration
###############################################

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# Security Group Outputs
output "app_security_group_id" {
  description = "ID of the application security group"
  value       = module.security_groups.app_sg_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security_groups.alb_sg_id
}

# Auto Scaling Group Outputs
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = module.autoscaling.launch_template_id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = module.autoscaling.launch_template_latest_version
}

# EC2 Instance Outputs (for instances outside ASG)
output "ec2_instance_ids" {
  description = "List of IDs of the EC2 instances"
  value       = module.ec2_instances.instance_ids
}

output "ec2_instance_private_ips" {
  description = "List of private IP addresses of the EC2 instances"
  value       = module.ec2_instances.instance_private_ips
}

# IAM Role Outputs
output "ec2_iam_role_name" {
  description = "Name of the IAM role attached to the EC2 instances"
  value       = module.ec2_instances.iam_role_name
}

output "asg_iam_role_name" {
  description = "Name of the IAM role attached to the ASG instances"
  value       = module.autoscaling.iam_role_name
}

# Summary Output
output "infrastructure_summary" {
  description = "Summary of the infrastructure created"
  value = {
    environment        = var.environment
    region             = var.aws_region
    vpc_id             = module.vpc.vpc_id
    private_subnet_count = length(module.vpc.private_subnet_ids)
    public_subnet_count  = length(module.vpc.public_subnet_ids)
    asg_min_size       = var.environment == "prod" ? 3 : 2
    asg_max_size       = var.environment == "prod" ? 10 : 5
    instance_type      = var.environment == "prod" ? "t3.medium" : "t3.micro"
  }
}