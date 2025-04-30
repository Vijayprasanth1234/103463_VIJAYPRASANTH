###############################################
# EC2 Module - outputs.tf
# 
# Outputs from the EC2 module
###############################################

output "instance_ids" {
  description = "List of IDs of the EC2 instances"
  value       = aws_instance.app_servers[*].id
}

output "instance_private_ips" {
  description = "List of private IP addresses of the EC2 instances"
  value       = aws_instance.app_servers[*].private_ip
}

output "instance_public_ips" {
  description = "List of public IP addresses of the EC2 instances (if applicable)"
  value       = aws_instance.app_servers[*].public_ip
}

output "instance_arns" {
  description = "List of ARNs of the EC2 instances"
  value       = aws_instance.app_servers[*].arn
}

output "iam_role_name" {
  description = "Name of the IAM role attached to the EC2 instances"
  value       = aws_iam_role.ec2_role.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to the EC2 instances"
  value       = aws_iam_role.ec2_role.arn
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}