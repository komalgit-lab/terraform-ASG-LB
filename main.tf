##############################################################
# main.tf  –  Root configuration
# Wires together: networking → asg → alb modules
##############################################################

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── Networking Module ──────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  azs          = var.availability_zones
  public_cidrs = var.public_subnet_cidrs
}

# ── ASG Module ─────────────────────────────────────────────
module "asg" {
  source = "./modules/asg"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  min_size          = var.asg_min_size
  max_size          = var.asg_max_size
  desired_capacity  = var.asg_desired_capacity
  alb_sg_id         = module.alb.alb_security_group_id
  target_group_arn  = module.alb.target_group_arn
}

# ── ALB Module ─────────────────────────────────────────────
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
}
