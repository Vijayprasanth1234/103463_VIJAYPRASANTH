###############################################
# main.tf - Root Configuration
# 
# This is the main Terraform configuration file that sets up:
# - Provider configuration
# - Remote state management
# - Common tagging strategy
# - Module references for infrastructure components
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
  
  # User data script for instance configuration
  user_data = <<-EOF
    #!/bin/bash
    # Update system packages
    yum update -y
    
    # Install required software
    amazon-linux-extras install -y nginx1
    yum install -y amazon-cloudwatch-agent
    
    # Configure and start services
    systemctl enable nginx
    systemctl start nginx
    
    # Set up CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-linux
    
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
}