output "auxiliary_service_repository_url" {
  description = "URL of the ECR repository for Auxiliary Service"
  value       = aws_ecr_repository.auxiliary_service.repository_url
}

output "main_api_repository_url" {
  description = "URL of the ECR repository for Main API"
  value       = aws_ecr_repository.main_api.repository_url
}

output "auxiliary_service_repository_name" {
  description = "Name of the ECR repository for Auxiliary Service"
  value       = aws_ecr_repository.auxiliary_service.name
}

output "main_api_repository_name" {
  description = "Name of the ECR repository for Main API"
  value       = aws_ecr_repository.main_api.name
}

output "auxiliary_service_repository_arn" {
  description = "ARN of the ECR repository for Auxiliary Service"
  value       = aws_ecr_repository.auxiliary_service.arn
}

output "main_api_repository_arn" {
  description = "ARN of the ECR repository for Main API"
  value       = aws_ecr_repository.main_api.arn
}

