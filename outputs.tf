# ==========================================
# OUTPUTS
# ==========================================

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IP Address"
  value       = aws_eip.app.public_ip
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_eip.app.public_ip}:${var.app_port}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = var.vpc_id
}

output "subnet_id" {
  description = "Subnet ID used"
  value       = var.subnet_ids[0]
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.app.id
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "codepipeline_name" {
  description = "CodePipeline Name"
  value       = aws_codepipeline.app.name
}

output "codepipeline_url" {
  description = "CodePipeline Console URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.app.name}/view"
}

output "codebuild_project" {
  description = "CodeBuild Project Name"
  value       = aws_codebuild_project.app.name
}

output "codedeploy_app" {
  description = "CodeDeploy Application Name"
  value       = aws_codedeploy_app.app.name
}

output "codedeploy_deployment_group" {
  description = "CodeDeploy Deployment Group"
  value       = aws_codedeploy_deployment_group.app.deployment_group_name
}

output "github_connection_arn" {
  description = "GitHub Connection ARN (Complete the connection in AWS Console)"
  value       = aws_codestarconnections_connection.github.arn
}

output "github_connection_status" {
  description = "GitHub Connection Status"
  value       = aws_codestarconnections_connection.github.connection_status
}

output "s3_artifacts_bucket" {
  description = "S3 Artifacts Bucket Name"
  value       = aws_s3_bucket.artifacts.bucket
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh -i your-key.pem ec2-user@${aws_eip.app.public_ip}"
}

output "pm2_commands" {
  description = "PM2 commands to manage your apps"
  value       = <<-EOT
    SSH to server: ssh -i your-key.pem ec2-user@${aws_eip.app.public_ip}
    
    PM2 Commands:
    - pm2 list              # View all processes
    - pm2 logs              # View logs
    - pm2 monit             # Monitor resources
    - pm2 restart all       # Restart all apps
  EOT
}

output "next_steps" {
  description = "Next steps to complete setup"
  value       = <<-EOT
    ========================================
    DEPLOYMENT SUCCESSFUL! 🚀
    ========================================
    
    1. Complete GitHub Connection:
       - AWS Console → Developer Tools → Connections
       - Click "${aws_codestarconnections_connection.github.name}"
       - Click "Update pending connection" and authorize
    
    2. Add to Your Go Repository:
       - appspec.yml
       - ecosystem.config.js (PM2 config)
       - scripts/stop.sh
       - scripts/start.sh
    
    3. Push to GitHub:
       - git push origin ${var.github_branch}
       - Pipeline automatically deploys!
    
    4. Access Your Application:
       - URL: http://${aws_eip.app.public_ip}:${var.app_port}
       - SSH: ssh -i your-key.pem ec2-user@${aws_eip.app.public_ip}
    
    5. Manage with PM2:
       - pm2 list
       - pm2 logs
       - pm2 restart all
    
    ========================================
  EOT
}