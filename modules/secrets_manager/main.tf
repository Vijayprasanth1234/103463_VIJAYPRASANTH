###############################################
# secrets_manager/main.tf - AWS Secrets Manager Module
# 
# This module creates and manages AWS Secrets Manager resources
# for storing sensitive configuration data
###############################################

# KMS key for encrypting secrets
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-secrets-kms-key"
    }
  )
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.environment}-secrets-key"
  target_key_id = aws_kms_key.secrets.key_id
}

# Database credentials secret
resource "aws_secretsmanager_secret" "database" {
  name                    = "${var.environment}/${var.project_name}/database"
  description             = "Database credentials for ${var.project_name} in ${var.environment} environment"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = var.recovery_window_in_days
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-db-credentials"
    }
  )
}

# Store database credentials
resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = var.db_port
    name     = var.db_name
  })
}

# Application secrets
resource "aws_secretsmanager_secret" "application" {
  name                    = "${var.environment}/${var.project_name}/application"
  description             = "Application secrets for ${var.project_name} in ${var.environment} environment"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = var.recovery_window_in_days
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-app-secrets"
    }
  )
}

# Store application secrets
resource "aws_secretsmanager_secret_version" "application" {
  secret_id = aws_secretsmanager_secret.application.id
  
  secret_string = jsonencode({
    alarm_email = var.alarm_email
    api_keys    = var.api_keys
  })
}

# IAM policy for accessing secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.environment}-${var.project_name}-secrets-access"
  description = "Policy for accessing secrets for ${var.project_name} in ${var.environment}"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.database.arn,
          aws_secretsmanager_secret.application.arn
        ]
      },
      {
        Action = [
          "kms:Decrypt"
        ]
        Effect = "Allow"
        Resource = [
          aws_kms_key.secrets.arn
        ]
      }
    ]
  })
}

# Optional: Secret rotation configuration
resource "aws_secretsmanager_secret_rotation" "database_rotation" {
  count               = var.enable_rotation ? 1 : 0
  secret_id           = aws_secretsmanager_secret.database.id
  rotation_lambda_arn = var.rotation_lambda_arn
  
  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}