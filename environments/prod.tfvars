# Production Environment Variables

# General
aws_region   = "us-east-1"
environment  = "prod"
project_name = "example-project"
team         = "infrastructure"
cost_center  = "infrastructure"

# Network
vpc_cidr     = "10.0.0.0/16"

# EC2 and Auto Scaling
enable_enhanced_monitoring = true
enable_backups             = true
backup_retention_days      = 30

# Monitoring
alarm_email = "alerts@example.com"