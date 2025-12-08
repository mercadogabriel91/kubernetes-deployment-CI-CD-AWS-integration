terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration - uncomment and configure to use remote state
  # backend "s3" {
  #   bucket         = "k-challenge-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# S3 Buckets Module
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}

# Parameter Store Module
module "parameter_store" {
  source = "./modules/parameter-store"

  project_name = var.project_name
  environment  = var.environment
  app_version  = var.app_version
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name               = var.project_name
  environment                = var.environment
  github_repository          = var.github_repository
  s3_bucket_arns             = module.s3.bucket_arns
  parameter_store_arn        = module.parameter_store.parameter_store_arn
  eks_cluster_name           = var.eks_cluster_name
  eks_oidc_provider_id       = var.eks_oidc_provider_id
  kubernetes_namespace       = var.kubernetes_namespace
  kubernetes_service_account = var.kubernetes_service_account
}

