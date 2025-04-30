###############################################
# secrets_manager/outputs.tf - Outputs for Secrets Manager Module
# 
# This file defines all outputs from the secrets manager module
###############################################

output "database_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.database.arn
}

output "application_secret_arn" {
  description = "ARN of the application secrets"
  value       = aws_secretsmanager_secret.application.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encrypting secrets"
  value       = aws_kms_key.secrets.arn
}

output "secrets_access_policy_arn" {
  description = "ARN of the IAM policy for accessing secrets"
  value       = aws_iam_policy.secrets_access.arn
}

output "database_secret_name" {
  description = "Name of the database credentials secret"
  value       = aws_secretsmanager_secret.database.name
}

output "application_secret_name" {
  description = "Name of the application secrets"
  value       = aws_secretsmanager_secret.application.name
}