# PlumpCasino Infrastructure

Terraform/OpenTofu infrastructure for PlumpCasino application.

## What It Does

Creates AWS infrastructure:
- EC2 instances with Auto Scaling
- PostgreSQL database
- Load Balancer
- VPC and networking

## Region

eu-west-1

## Deploy
```bash
cd environments/production
tofu init
tofu plan
tofu apply

## Github Actions
- Actions → Production Infrastructure → Run workflow
