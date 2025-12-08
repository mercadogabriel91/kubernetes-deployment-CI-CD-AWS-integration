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

