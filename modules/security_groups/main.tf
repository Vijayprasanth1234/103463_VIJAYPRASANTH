###############################################
# Security Groups Module - main.tf
# 
# This module creates security groups for EC2 instances
# following the principle of least privilege
###############################################

# Security group for application servers
resource "aws_security_group" "app_sg" {
  name_prefix = "${var.environment}-app-sg"
  description = "Security group for application servers"
  vpc_id      = var.vpc_id

  # Prevent inline rules to allow better management through dedicated resources
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-app-sg"
    }
  )
}

# Allow inbound HTTPS traffic
resource "aws_security_group_rule" "app_https_in" {
  security_group_id = aws_security_group.app_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_https_cidr_blocks
  description       = "Allow HTTPS inbound traffic"
}

# Allow inbound HTTP traffic (if enabled)
resource "aws_security_group_rule" "app_http_in" {
  count             = var.allow_http ? 1 : 0
  security_group_id = aws_security_group.app_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidr_blocks
  description       = "Allow HTTP inbound traffic"
}

# Allow inbound SSH traffic from bastion hosts only
resource "aws_security_group_rule" "app_ssh_in" {
  count             = var.allow_ssh ? 1 : 0
  security_group_id = aws_security_group.app_sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidr_blocks
  description       = "Allow SSH inbound traffic from bastion hosts"
}

# Allow all outbound traffic
resource "aws_security_group_rule" "app_all_out" {
  security_group_id = aws_security_group.app_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Security group for load balancers
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.environment}-alb-sg"
  description = "Security group for application load balancer"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-alb-sg"
    }
  )
}

# Allow inbound HTTPS traffic to ALB
resource "aws_security_group_rule" "alb_https_in" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS inbound traffic"
}

# Allow inbound HTTP traffic to ALB (if enabled)
resource "aws_security_group_rule" "alb_http_in" {
  count             = var.allow_http ? 1 : 0
  security_group_id = aws_security_group.alb_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP inbound traffic"
}

# Allow all outbound traffic from ALB
resource "aws_security_group_rule" "alb_all_out" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}