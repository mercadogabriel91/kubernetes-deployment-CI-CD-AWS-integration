output "parameter_paths" {
  description = "Paths of all Parameter Store parameters"
  value = [
    aws_ssm_parameter.app_version.name,
    aws_ssm_parameter.environment.name,
    aws_ssm_parameter.main_api_port.name,
    aws_ssm_parameter.auxiliary_service_port.name,
    aws_ssm_parameter.auxiliary_service_url.name,
    aws_ssm_parameter.aws_account_id.name,
    aws_ssm_parameter.aws_region.name
  ]
}

output "parameter_store_arn" {
  description = "ARN pattern for Parameter Store (used in IAM policies)"
  value       = "arn:aws:ssm:*:*:parameter/${var.project_name}/*"
}

output "app_version_parameter_name" {
  description = "Name of the app version parameter"
  value       = aws_ssm_parameter.app_version.name
}

output "aws_account_id_parameter_name" {
  description = "Name of the AWS account ID parameter"
  value       = aws_ssm_parameter.aws_account_id.name
}

output "aws_region_parameter_name" {
  description = "Name of the AWS region parameter"
  value       = aws_ssm_parameter.aws_region.name
}

