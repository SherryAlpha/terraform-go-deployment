output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "alb_dns_name" {
  description = "Load Balancer DNS name"
  value       = module.load_balancer.alb_dns_name
}

output "alb_zone_id" {
  description = "Load Balancer Zone ID (for Route53)"
  value       = module.load_balancer.alb_zone_id
}

output "alb_arn" {
  description = "Load Balancer ARN"
  value       = module.load_balancer.alb_arn
}

output "https_url" {
  description = "HTTPS URL (if certificate configured)"
  value       = var.certificate_arn != "" ? "https://${module.load_balancer.alb_dns_name}" : "http://${module.load_balancer.alb_dns_name}"
}

output "rest_api_url" {
  description = "REST API endpoint"
  value       = var.certificate_arn != "" ? "https://${module.load_balancer.alb_dns_name}/rest" : "http://${module.load_balancer.alb_dns_name}/rest"
}

output "websocket_url" {
  description = "WebSocket endpoint"
  value       = var.certificate_arn != "" ? "wss://${module.load_balancer.alb_dns_name}/ws" : "ws://${module.load_balancer.alb_dns_name}/ws"
}

output "db_endpoint" {
  description = "Database endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "db_address" {
  description = "Database address"
  value       = module.database.db_address
  sensitive   = true
}

output "db_port" {
  description = "Database port"
  value       = module.database.db_port
}

output "db_name" {
  description = "Database name"
  value       = module.database.db_name
}

output "db_secret_arn" {
  description = "Database credentials secret ARN"
  value       = module.database.db_secret_arn
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.autoscaling_group_name
}

output "autoscaling_group_id" {
  description = "Auto Scaling Group ID"
  value       = module.compute.autoscaling_group_id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group name"
  value       = module.compute.log_group_name
}
