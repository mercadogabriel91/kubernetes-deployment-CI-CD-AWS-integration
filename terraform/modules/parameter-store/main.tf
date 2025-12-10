resource "aws_ssm_parameter" "app_version" {
  name  = "/${var.project_name}/app-version"
  type  = "String"
  value = var.app_version

  tags = {
    Name        = "${var.project_name}-app-version"
    Environment = var.environment
    Purpose     = "Application version tracking"
  }
}

resource "aws_ssm_parameter" "environment" {
  name  = "/${var.project_name}/environment"
  type  = "String"
  value = var.environment

  tags = {
    Name        = "${var.project_name}-environment"
    Environment = var.environment
    Purpose     = "Environment identifier"
  }
}

resource "aws_ssm_parameter" "main_api_port" {
  name  = "/${var.project_name}/main-api/port"
  type  = "String"
  value = "3000"

  tags = {
    Name        = "${var.project_name}-main-api-port"
    Environment = var.environment
    Purpose     = "Main API port configuration"
  }
}

resource "aws_ssm_parameter" "auxiliary_service_port" {
  name  = "/${var.project_name}/auxiliary-service/port"
  type  = "String"
  value = "3001"

  tags = {
    Name        = "${var.project_name}-auxiliary-service-port"
    Environment = var.environment
    Purpose     = "Auxiliary Service port configuration"
  }
}

resource "aws_ssm_parameter" "auxiliary_service_url" {
  name  = "/${var.project_name}/auxiliary-service/url"
  type  = "String"
  value = "http://auxiliary-service:3001"

  tags = {
    Name        = "${var.project_name}-auxiliary-service-url"
    Environment = var.environment
    Purpose     = "Auxiliary Service URL configuration"
  }
}

# AWS Account ID - stored in Parameter Store for use in Kubernetes manifests
# This avoids hardcoding account IDs in Git
data "aws_caller_identity" "current" {}

resource "aws_ssm_parameter" "aws_account_id" {
  name  = "/${var.project_name}/aws/account-id"
  type  = "String"
  value = data.aws_caller_identity.current.account_id

  tags = {
    Name        = "${var.project_name}-aws-account-id"
    Environment = var.environment
    Purpose     = "AWS Account ID for ECR registry URLs"
  }
}

# AWS Region - stored for consistency
data "aws_region" "current" {}

resource "aws_ssm_parameter" "aws_region" {
  name  = "/${var.project_name}/aws/region"
  type  = "String"
  value = data.aws_region.current.name

  tags = {
    Name        = "${var.project_name}-aws-region"
    Environment = var.environment
    Purpose     = "AWS Region for ECR registry URLs"
  }
}

