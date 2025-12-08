output "s3_bucket_names" {
  description = "Names of created S3 buckets"
  value       = module.s3.bucket_names
}

output "s3_bucket_arns" {
  description = "ARNs of created S3 buckets"
  value       = module.s3.bucket_arns
}

output "parameter_store_paths" {
  description = "Paths of Parameter Store parameters"
  value       = module.parameter_store.parameter_paths
}

output "github_actions_role_arn" {
  description = "ARN of IAM role for GitHub Actions"
  value       = module.iam.github_actions_role_arn
}

output "kubernetes_service_account_role_arn" {
  description = "ARN of IAM role for Kubernetes Service Account"
  value       = module.iam.kubernetes_service_account_role_arn
}

output "oidc_provider_arn" {
  description = "ARN of OIDC provider for GitHub Actions (if created)"
  value       = module.iam.oidc_provider_arn
}

output "ecr_auxiliary_service_repository_url" {
  description = "ECR repository URL for Auxiliary Service"
  value       = module.ecr.auxiliary_service_repository_url
}

output "ecr_main_api_repository_url" {
  description = "ECR repository URL for Main API"
  value       = module.ecr.main_api_repository_url
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value = {
    auxiliary_service = module.ecr.auxiliary_service_repository_url
    main_api          = module.ecr.main_api_repository_url
  }
}

