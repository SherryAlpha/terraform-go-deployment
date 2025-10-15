# Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

# Database Outputs
output "db_endpoint" {
  description = "Database endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = module.database.db_name
}

# Compute Outputs
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.asg_name
}

output "elastic_ip" {
  description = "Elastic IP for application access"
  value       = module.compute.elastic_ip
}