# General Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "plumpcasino"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

# Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

# Security Variables
variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH (use bastion host IP or VPN)"
  type        = list(string)
  default     = []
}

# Database Variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "plumpcasino"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "dbadmin"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling"
  type        = number
  default     = 500
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}

# Load Balancer Variables
variable "certificate_arn" {
  description = "SSL certificate ARN from ACM"
  type        = string
  default     = ""
}

# Compute Variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
  default     = ""
}

variable "asg_min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 3
}

variable "asg_max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 10
}

variable "asg_desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 4
}

variable "github_token" {
  description = "GitHub Personal Access Token for private repo access"
  type        = string
  sensitive   = true
  default     = ""
}