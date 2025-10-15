# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Elastic IP for direct access
resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-eip"
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

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

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  }
}

# IAM policy for accessing secrets and CloudWatch
resource "aws_iam_role_policy" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.db_secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::plump-casino-deployments-prod/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AssociateAddress",
          "ec2:DescribeAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach SSM policy for Session Manager access
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# Key pair for SSH access
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-${var.environment}-deployer"
  public_key = var.ssh_public_key

  tags = {
    Name = "${var.project_name}-${var.environment}-deployer-key"
  }
}

# User data script for EC2 initialization
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    dnf update -y
    
    # Install required packages
    dnf install -y amazon-cloudwatch-agent jq
    
    # Create app directory
    mkdir -p /opt/plumpcasino
    chown ec2-user:ec2-user /opt/plumpcasino
    
    # Create log directory
    mkdir -p /var/log/plumpcasino
    chown ec2-user:ec2-user /var/log/plumpcasino
    
    # Download pre-built binaries from S3
    cd /opt/plumpcasino
    aws s3 cp s3://plump-casino-deployments-prod/binaries/rest /opt/plumpcasino/rest || echo "REST binary not found"
    aws s3 cp s3://plump-casino-deployments-prod/binaries/events /opt/plumpcasino/events || echo "Events binary not found"
    aws s3 cp s3://plump-casino-deployments-prod/binaries/bonuses /opt/plumpcasino/bonuses || echo "Bonuses binary not found"
    chmod +x /opt/plumpcasino/rest /opt/plumpcasino/events /opt/plumpcasino/bonuses
    
    # Create config directory
    mkdir -p /opt/plumpcasino/config/local
    
    # Download config from S3
    aws s3 cp s3://plump-casino-deployments-prod/config/config.yaml /opt/plumpcasino/config/local/config.yaml || echo "Config not found"
    
    # Set ownership
    chown -R ec2-user:ec2-user /opt/plumpcasino/config
    
    # Create systemd service for REST API (port 3000)
    cat > /etc/systemd/system/plumpcasino-rest.service <<SERVICE
[Unit]
Description=PlumpCasino REST API
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/plumpcasino
ExecStart=/opt/plumpcasino/rest
Restart=always
RestartSec=10
Environment="AWS_REGION=eu-west-1"
Environment="AWS_SDK_LOAD_CONFIG=1"
Environment="PORT=3000"

[Install]
WantedBy=multi-user.target
SERVICE

    # Create systemd service for Events (port 8081)
    cat > /etc/systemd/system/plumpcasino-events.service <<SERVICE
[Unit]
Description=PlumpCasino Events Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/plumpcasino
ExecStart=/opt/plumpcasino/events
Restart=always
RestartSec=10
Environment="AWS_REGION=eu-west-1"
Environment="AWS_SDK_LOAD_CONFIG=1"
Environment="WS_PORT=8081"

[Install]
WantedBy=multi-user.target
SERVICE

    # Create systemd service for Bonuses (background service)
    cat > /etc/systemd/system/plumpcasino-bonuses.service <<SERVICE
[Unit]
Description=PlumpCasino Bonuses Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/plumpcasino
ExecStart=/opt/plumpcasino/bonuses
Restart=always
RestartSec=10
Environment="AWS_REGION=eu-west-1"
Environment="AWS_SDK_LOAD_CONFIG=1"

[Install]
WantedBy=multi-user.target
SERVICE
    
    # Start services
    systemctl daemon-reload
    systemctl start plumpcasino-rest
    systemctl start plumpcasino-events
    systemctl start plumpcasino-bonuses
    systemctl enable plumpcasino-rest
    systemctl enable plumpcasino-events
    systemctl enable plumpcasino-bonuses
    
    # Associate Elastic IP
    INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
    EIP_ALLOC_ID="${aws_eip.app.allocation_id}"
    aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $EIP_ALLOC_ID --region eu-west-1 || echo "Failed to associate EIP"
    
    # Configure CloudWatch agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json <<'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/plumpcasino/*.log",
            "log_group_name": "/aws/ec2/plumpcasino-production",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CWCONFIG
    
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json
    
    # Signal completion
    echo "Deployment completed at $(date)" > /var/log/userdata.log
  EOF
}

# Launch template for EC2 instances
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  # Use network_interfaces to assign public IP
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.app_security_group_id]
    delete_on_termination       = true
  }

  user_data = base64encode(local.user_data)

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group in PUBLIC subnets
resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-${var.environment}-asg"
  vpc_zone_identifier       = var.private_subnet_ids  # Will be changed to public in main.tf
  health_check_type         = "EC2"
  health_check_grace_period = 300

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "PlumpCasino"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policy - Target Tracking (CPU)
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.project_name}-${var.environment}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-logs"
  }
}