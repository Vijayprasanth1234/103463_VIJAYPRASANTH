###############################################
# Autoscaling Module - outputs.tf
# 
# Outputs from the autoscaling module
###############################################

output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app.id
}

output "launch_template_arn" {
  description = "ARN of the launch template"
  value       = aws_launch_template.app.arn
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.app.latest_version
}

output "iam_role_name" {
  description = "Name of the IAM role attached to the EC2 instances"
  value       = aws_iam_role.asg_role.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to the EC2 instances"
  value       = aws_iam_role.asg_role.arn
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.asg_profile.name
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.asg_profile.arn
}