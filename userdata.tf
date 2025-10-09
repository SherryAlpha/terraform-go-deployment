# ==========================================
# EC2 SETUP SCRIPT WITH PM2
# ==========================================

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Log everything
    exec > >(tee /var/log/user-data.log)
    exec 2>&1
    
    echo "=== Starting setup ==="
    
    # Update system
    yum update -y
    
    # Install Node.js (required for PM2)
    curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
    yum install -y nodejs
    
    # Install PM2 globally
    npm install -g pm2
    
    # Setup PM2 to start on boot
    pm2 startup systemd -u ec2-user --hp /home/ec2-user
    env PATH=$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user
    
    # Install Go
    cd /tmp
    wget https://go.dev/dl/go${var.go_version}.linux-amd64.tar.gz
    tar -C /usr/local -xzf go${var.go_version}.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/ec2-user/.bashrc
    
    # Install Git
    yum install -y git ruby wget
    
    # Create app directory
    mkdir -p /opt/${var.project_name}
    chown -R ec2-user:ec2-user /opt/${var.project_name}
    
    # Create PM2 ecosystem file
    cat > /opt/${var.project_name}/ecosystem.config.js <<'ECOSYSTEM'
    module.exports = {
      apps: [
        {
          name: '${var.project_name}-app',
          script: '/opt/${var.project_name}/app',
          interpreter: 'none',
          cwd: '/opt/${var.project_name}',
          env: {
            PORT: '${var.app_port}',
            ENVIRONMENT: '${var.environment}'
          },
          error_file: '/var/log/${var.project_name}/app-error.log',
          out_file: '/var/log/${var.project_name}/app-out.log',
          log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
          autorestart: true,
          max_restarts: 10,
          min_uptime: '10s',
          restart_delay: 4000
        },
        {
          name: '${var.project_name}-worker',
          script: '/opt/${var.project_name}/worker',
          interpreter: 'none',
          cwd: '/opt/${var.project_name}',
          env: {
            WORKER_MODE: 'true',
            ENVIRONMENT: '${var.environment}'
          },
          error_file: '/var/log/${var.project_name}/worker-error.log',
          out_file: '/var/log/${var.project_name}/worker-out.log',
          log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
          autorestart: true,
          max_restarts: 10,
          min_uptime: '10s',
          restart_delay: 4000
        }
      ]
    };
    ECOSYSTEM
    
    # Create log directory
    mkdir -p /var/log/${var.project_name}
    chown -R ec2-user:ec2-user /var/log/${var.project_name}
    
    # Set proper permissions
    chown -R ec2-user:ec2-user /opt/${var.project_name}
    
    # Install CodeDeploy agent
    cd /tmp
    wget https://aws-codedeploy-${var.aws_region}.s3.${var.aws_region}.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
    systemctl start codedeploy-agent
    systemctl enable codedeploy-agent
    
    echo "=== Setup complete ==="
  EOF
}