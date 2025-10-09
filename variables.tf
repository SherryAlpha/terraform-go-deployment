# ==========================================
# REQUIRED VARIABLES
# ==========================================

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs (public subnets recommended)"
  type        = list(string)
}

variable "github_repo" {
  description = "GitHub repository (format: owner/repo)"
  type        = string
}

variable "project_name" {
  description = "Project name (used for resource naming)"
  type        = string
}

# ==========================================
# OPTIONAL VARIABLES
# ==========================================

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "go_version" {
  description = "Go version to install"
  type        = string
  default     = "1.21.0"
}