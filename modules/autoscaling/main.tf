###############################################
# Autoscaling Module - main.tf
# 
# This module creates an Auto Scaling Group with:
# - Launch template with best practices
# - Scaling policies based on CPU utilization
# - Integration with Application Load Balancer
# - Instance refresh for zero-downtime deployments
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

# IAM role for EC2 instances in the ASG
resource "aws_iam_role" "asg_role" {
  name = "${var.environment}-asg-role"

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
resource "aws_iam_instance_profile" "asg_profile" {
  name = "${var.environment}-asg-profile"
  role = aws_iam_role.asg_role.name
}

# SSM policy attachment for secure shell access without SSH keys
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.asg_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch policy for enhanced monitoring
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.asg_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Launch template for Auto Scaling Group
resource "aws_launch_template" "app" {
  name_prefix            = "${var.environment}-app-lt-"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  vpc_security_group_ids = var.security_group_ids
  
  iam_instance_profile {
    name = aws_iam_instance_profile.asg_profile.name
  }
  
  # Require IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  
  # Enable detailed monitoring
  monitoring {
    enabled = true
  }
  
  # User data for instance configuration
  user_data = base64encode(var.user_data != "" ? var.user_data : <<-EOF
    #!/bin/bash
    echo "Hello from ${var.environment} environment!"
    yum update -y
    amazon-linux-extras install -y nginx1
    systemctl enable nginx
    systemctl start nginx
  EOF
  )

  # Root volume with encryption
  block_device_mappings {
    device_name = "/dev/xvda"
    
    ebs {
      volume_type           = var.root_volume_type
      volume_size           = var.root_volume_size
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = var.kms_key_id
    }
  }
  
  # Additional EBS volume (if enabled)
  dynamic "block_device_mappings" {
    for_each = var.create_ebs_volume ? [1] : []
    content {
      device_name = "/dev/sdf"
      
      ebs {
        volume_type           = var.ebs_volume_type
        volume_size           = var.ebs_volume_size
        delete_on_termination = true
        encrypted             = true
        kms_key_id            = var.kms_key_id
      }
    }
  }
  
  # Tag specifications for instances and volumes
  tag_specifications {
    resource_type = "instance"
    
    tags = merge(
      var.common_tags,
      {
        Name = "${var.environment}-app-server"
      }
    )
  }
  
  tag_specifications {
    resource_type = "volume"
    
    tags = merge(
      var.common_tags,
      {
        Name = "${var.environment}-app-volume"
      }
    )
  }
  
  # Prevent accidental destruction
  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                      = "${var.environment}-app-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  
  # Use launch template
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  # Target group attachment (if ALB is used)
  dynamic "target_group_arns" {
    for_each = var.target_group_arns
    content {
      target_group_arns = var.target_group_arns
    }
  }
  
  # Instance refresh for zero-downtime deployments
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
  }
  
  # Dynamic scaling based on metrics
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]
  
  # Propagate tags to EC2 instances
  dynamic "tag" {
    for_each = merge(
      var.common_tags,
      {
        Name = "${var.environment}-app-asg"
      }
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# Scale out policy (add instances)
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.environment}-app-scale-out"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

# Scale in policy (remove instances)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.environment}-app-scale-in"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

# CloudWatch alarm for high CPU utilization (scale out)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-app-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.scale_out_threshold
  alarm_description   = "Scale out if CPU utilization is high"
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
  
  tags = var.common_tags
}

# CloudWatch alarm for low CPU utilization (scale in)
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.environment}-app-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.scale_in_threshold
  alarm_description   = "Scale in if CPU utilization is low"
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
  
  tags = var.common_tags
}