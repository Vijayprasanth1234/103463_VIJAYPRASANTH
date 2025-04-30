###############################################
# EC2 Module - main.tf
# 
# This module creates EC2 instances with best practices:
# - Encrypted EBS volumes
# - IMDSv2 required
# - Detailed monitoring
# - Instance profile for secure access to AWS services
###############################################

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# SSM policy attachment for secure shell access without SSH keys
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch policy for enhanced monitoring
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Add Secrets Manager policy attachment if provided
resource "aws_iam_role_policy_attachment" "secrets_policy" {
  count      = var.secrets_access_policy_arn != null ? 1 : 0
  role       = aws_iam_role.ec2_role.name
  policy_arn = var.secrets_access_policy_arn
}

# EC2 instances
resource "aws_instance" "app_servers" {
  count = var.instance_count

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = element(var.subnet_ids, count.index % length(var.subnet_ids))
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  
  # Require IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  
  # Enable detailed monitoring
  monitoring = true
  
  # User data for instance configuration
  user_data = var.user_data != "" ? var.user_data : <<-EOF
    #!/bin/bash
    echo "Hello from ${var.environment} environment!"
    yum update -y
    amazon-linux-extras install -y nginx1
    systemctl enable nginx
    systemctl start nginx
  EOF

  # Root volume with encryption
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = var.kms_key_id
    
    tags = merge(
      var.common_tags,
      {
        Name = "${var.environment}-app-server-${count.index + 1}-root"
      }
    )
  }

  # Additional EBS volume (if enabled)
  dynamic "ebs_block_device" {
    for_each = var.create_ebs_volume ? [1] : []
    content {
      device_name           = "/dev/sdf"
      volume_type           = var.ebs_volume_type
      volume_size           = var.ebs_volume_size
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = var.kms_key_id
      
      tags = merge(
        var.common_tags,
        {
          Name = "${var.environment}-app-server-${count.index + 1}-data"
        }
      )
    }
  }

  # Prevent accidental destruction
  lifecycle {
    ignore_changes = [ami]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-app-server-${count.index + 1}"
    }
  )
}

# CloudWatch alarm for high CPU utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count               = var.instance_count
  alarm_name          = "${var.environment}-high-cpu-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    InstanceId = aws_instance.app_servers[count.index].id
  }
  
  tags = var.common_tags
}