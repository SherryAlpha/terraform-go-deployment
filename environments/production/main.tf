terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "plump-casino-terraform-state-prod"
    key            = "production/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-prod"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "OpenTofu"
      Repository  = "PlumpCasino/community"
      CostCenter  = "PlumpCasino-Production"
    }
  }
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
}

# Security Module
module "security" {
  source = "../../modules/security"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
}

# Database Module
module "database" {
  source = "../../modules/database"

  project_name            = var.project_name
  environment             = var.environment
  private_subnet_ids      = module.networking.private_subnet_ids
  db_security_group_id    = module.security.db_security_group_id
  db_name                 = var.db_name
  db_username             = var.db_username
  db_engine_version       = var.db_engine_version
  db_instance_class       = var.db_instance_class
  db_allocated_storage    = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  backup_retention_period = var.backup_retention_period
}

# Load Balancer Module
module "load_balancer" {
  source = "../../modules/load-balancer"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  certificate_arn       = var.certificate_arn
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = module.networking.private_subnet_ids
  app_security_group_id = module.security.app_security_group_id
  db_secret_arn         = module.database.db_secret_arn
  target_group_arns     = module.load_balancer.target_group_arns
  instance_type         = var.instance_type
  ssh_public_key        = var.ssh_public_key
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  asg_desired_capacity  = var.asg_desired_capacity
}
