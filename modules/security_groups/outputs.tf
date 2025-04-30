###############################################
# Security Groups Module - outputs.tf
# 
# Outputs from the security groups module
###############################################

output "app_sg_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app_sg.id
}

output "app_sg_name" {
  description = "Name of the application security group"
  value       = aws_security_group.app_sg.name
}

output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "alb_sg_name" {
  description = "Name of the ALB security group"
  value       = aws_security_group.alb_sg.name
}