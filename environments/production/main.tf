terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "plumpcasino-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "plumpcasino-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "OpenTofu"
    }
  }
}

module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security" {
  source = "../../modules/security"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
}

module "database" {
  source = "../../modules/database"

  project_name         = var.project_name
  environment          = var.environment
  db_instance_class    = var.db_instance_class
  db_name              = var.db_name
  db_username          = var.db_username
  private_subnet_ids   = module.networking.private_subnet_ids
  db_security_group_id = module.security.db_security_group_id
}

module "compute" {
  source = "../../modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = module.networking.public_subnet_ids  # Changed from private to public
  app_security_group_id = module.security.app_security_group_id
  db_secret_arn         = module.database.db_secret_arn
  ssh_public_key        = var.ssh_public_key
  instance_type         = var.instance_type
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  asg_desired_capacity  = var.asg_desired_capacity
}