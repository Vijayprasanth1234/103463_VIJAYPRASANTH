###############################################
# main.tf - Root Configuration
# 
# This is the main Terraform configuration file that sets up:
# - Provider configuration
# - Remote state management
# - Common tagging strategy
# - Module references for infrastructure components
# - Secrets management for sensitive data
###############################################

terraform {
  required_version = ">= 1.0.0"
  
  # Remote State Management for collaboration and state locking
  backend "s3" {
    bucket         = "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }

  # Version Lock Providers for stability
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Implement Proper Tagging Strategy
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = var.team
    CostCenter  = var.cost_center
    CreatedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}

# Data source for KMS key for EBS encryption
data "aws_kms_key" "ebs" {
  key_id = "alias/aws/ebs"
}

# Secrets Manager Module - Secure Storage for Sensitive Data
module "secrets_manager" {
  source = "./modules/secrets_manager"

  environment             = var.environment
  project_name            = var.project_name
  common_tags             = local.common_tags
  
  # Database credentials
  db_username             = "admin"
  db_password             = var.db_password
  db_host                 = "localhost"
  db_port                 = 5432
  db_name                 = "mydb"
  
  # Application secrets
  alarm_email             = var.alarm_email
  api_keys                = var.api_keys
  
  # Secret rotation configuration
  enable_rotation         = var.environment == "prod" ? true : false
  rotation_days           = 30
}

# VPC Module - Network Infrastructure
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr          = var.vpc_cidr
  environment       = var.environment
  common_tags       = local.common_tags
  az_count          = 3
  enable_nat_gateway = true
  enable_flow_logs   = true
}

# Security Groups Module - Network Security
module "security_groups" {
  source = "./modules/security_groups"

  vpc_id                   = module.vpc.vpc_id
  environment              = var.environment
  common_tags              = local.common_tags
  allowed_ssh_cidr_blocks  = [var.vpc_cidr]  # Restrict SSH access to VPC CIDR
  allow_http               = false           # Only allow HTTPS for security
}

# Autoscaling Module - EC2 Auto Scaling Group
module "autoscaling" {
  source = "./modules/autoscaling"

  environment        = var.environment
  common_tags        = local.common_tags
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.app_sg_id]
  
  # Right-sizing instances based on environment
  instance_type      = var.environment == "prod" ? "t3.medium" : "t3.micro"
  
  # Auto Scaling configuration
  min_size           = var.environment == "prod" ? 3 : 2
  max_size           = var.environment == "prod" ? 10 : 5
  desired_capacity   = var.environment == "prod" ? 3 : 2
  
  # Health check configuration
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  # Storage configuration with encryption
  root_volume_type  = "gp3"
  root_volume_size  = var.environment == "prod" ? 30 : 20
  create_ebs_volume = var.environment == "prod" ? true : false
  ebs_volume_type   = "gp3"
  ebs_volume_size   = 100
  kms_key_id        = data.aws_kms_key.ebs.arn
  
  # Auto Scaling thresholds
  scale_out_threshold = 70
  scale_in_threshold  = 30
  
  # Secrets Manager access
  secrets_access_policy_arn = module.secrets_manager.secrets_access_policy_arn
  
  # User data script for instance configuration
  user_data = <<-EOF
    #!/bin/bash
    # Update system packages
    yum update -y
    
    # Install required software
    amazon-linux-extras install -y nginx1
    yum install -y amazon-cloudwatch-agent
    yum install -y python3 python3-pip jq
    pip3 install boto3
    
    # Configure and start services
    systemctl enable nginx
    systemctl start nginx
    
    # Set up CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-linux
    
    # Create script to fetch database credentials from Secrets Manager
    cat > /usr/local/bin/fetch-secrets.py << 'PYTHON_SCRIPT'
    #!/usr/bin/env python3
    import boto3
    import json
    import os
    
    def get_secret(secret_name, region_name="us-east-1"):
        """Retrieve a secret from AWS Secrets Manager"""
        session = boto3.session.Session()
        client = session.client(service_name='secretsmanager', region_name=region_name)
        
        try:
            response = client.get_secret_value(SecretId=secret_name)
            if 'SecretString' in response:
                return json.loads(response['SecretString'])
            else:
                return None
        except Exception as e:
            print(f"Error retrieving secret: {str(e)}")
            return None
    
    if __name__ == "__main__":
        # Get region from instance metadata
        region = os.popen('curl -s http://169.254.169.254/latest/meta-data/placement/region').read()
        
        # Get database credentials
        db_secret_name = "${module.secrets_manager.database_secret_name}"
        db_creds = get_secret(db_secret_name, region)
        
        if db_creds:
            # Create directory for application configuration
            os.makedirs('/etc/app', exist_ok=True)
            
            # Write to configuration file with restricted permissions
            with open('/etc/app/database.json', 'w') as f:
                json.dump(db_creds, f)
            
            # Set secure permissions (only root can read)
            os.chmod('/etc/app/database.json', 0o600)
            
            print("Database credentials retrieved successfully")
        else:
            print("ERROR: Failed to retrieve database credentials")
        
        # Get application secrets
        app_secret_name = "${module.secrets_manager.application_secret_name}"
        app_secrets = get_secret(app_secret_name, region)
        
        if app_secrets:
            # Create directory for application configuration
            os.makedirs('/etc/app', exist_ok=True)
            
            # Write to configuration file with restricted permissions
            with open('/etc/app/application.json', 'w') as f:
                json.dump(app_secrets, f)
            
            # Set secure permissions (only root can read)
            os.chmod('/etc/app/application.json', 0o600)
            
            print("Application secrets retrieved successfully")
        else:
            print("ERROR: Failed to retrieve application secrets")
    PYTHON_SCRIPT
    
    # Make the script executable
    chmod +x /usr/local/bin/fetch-secrets.py
    
    # Create directory for application configuration
    mkdir -p /etc/app
    
    # Run the script to fetch secrets
    /usr/local/bin/fetch-secrets.py
    
    # Set up a cron job to periodically refresh secrets
    echo "0 */6 * * * /usr/local/bin/fetch-secrets.py > /var/log/fetch-secrets.log 2>&1" | crontab -
    
    # Tag instance with metadata
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Bootstrapped,Value=true --region $REGION
  EOF
}

# EC2 Module - Individual EC2 Instances (if needed outside ASG)
module "ec2_instances" {
  source = "./modules/ec2"

  environment        = var.environment
  common_tags        = local.common_tags
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.app_sg_id]
  
  # Right-sizing instances based on environment
  instance_type      = var.environment == "prod" ? "t3.medium" : "t3.micro"
  instance_count     = 1  # Minimal count as we're using ASG for most instances
  
  # Storage configuration with encryption
  root_volume_type   = "gp3"
  root_volume_size   = var.environment == "prod" ? 30 : 20
  create_ebs_volume  = var.environment == "prod" ? true : false
  ebs_volume_type    = "gp3"
  ebs_volume_size    = 100
  kms_key_id         = data.aws_kms_key.ebs.arn
  
  # CloudWatch alarms
  alarm_actions      = []
  
  # Secrets Manager access
  secrets_access_policy_arn = module.secrets_manager.secrets_access_policy_arn
}