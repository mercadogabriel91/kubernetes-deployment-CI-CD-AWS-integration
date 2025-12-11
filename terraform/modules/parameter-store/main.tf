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
  # Allow overwrite since we created this manually first
  overwrite = true

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
  # Allow overwrite since we created this manually first
  overwrite = true

  tags = {
    Name        = "${var.project_name}-aws-region"
    Environment = var.environment
    Purpose     = "AWS Region for ECR registry URLs"
  }
}

# ECR Registry URL - computed from account ID and region
# This makes it easy for External Secrets Operator to sync
resource "aws_ssm_parameter" "ecr_registry" {
  name      = "/${var.project_name}/aws/ecr-registry"
  type      = "String"
  value     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
  overwrite = true

  tags = {
    Name        = "${var.project_name}-ecr-registry"
    Environment = var.environment
    Purpose     = "ECR registry URL for Docker images"
  }
}

# IAM Role ARN for Argo CD Image Updater (IRSA)
# Store the full ARN to avoid hardcoding account IDs in Git
# This references the IAM role created by the IAM module
# Format: arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>
# Note: This parameter will only be created if EKS cluster info is provided
# For local Kubernetes, you can create the role manually and set this parameter
resource "aws_ssm_parameter" "argocd_image_updater_role_arn" {
  name      = "/${var.project_name}/aws/argocd-image-updater-role-arn"
  type      = "String"
  # Use the role ARN from IAM module if available, otherwise construct it
  # The IAM module will create the role if eks_cluster_name and eks_oidc_provider_id are provided
  value     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-argocd-image-updater"
  overwrite = true

  tags = {
    Name        = "${var.project_name}-argocd-image-updater-role-arn"
    Environment = var.environment
    Purpose     = "IAM Role ARN for Argo CD Image Updater IRSA"
  }
}

