# ECR Repository for Auxiliary Service
resource "aws_ecr_repository" "auxiliary_service" {
  name                 = "${var.project_name}-${var.environment}-auxiliary-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-auxiliary-service"
    Environment = var.environment
    Purpose     = "Auxiliary Service container images"
  }
}

# ECR Repository for Main API
resource "aws_ecr_repository" "main_api" {
  name                 = "${var.project_name}-${var.environment}-main-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-main-api"
    Environment = var.environment
    Purpose     = "Main API container images"
  }
}

# Lifecycle Policy for Auxiliary Service - Keep only last 5 images
resource "aws_ecr_lifecycle_policy" "auxiliary_service" {
  repository = aws_ecr_repository.auxiliary_service.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lifecycle Policy for Main API - Keep only last 5 images
resource "aws_ecr_lifecycle_policy" "main_api" {
  repository = aws_ecr_repository.main_api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

