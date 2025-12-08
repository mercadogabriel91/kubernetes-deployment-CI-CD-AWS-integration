output "bucket_names" {
  description = "Names of created S3 buckets"
  value = [
    aws_s3_bucket.app_bucket.id,
    aws_s3_bucket.terraform_state.id
  ]
}

output "bucket_arns" {
  description = "ARNs of created S3 buckets"
  value = [
    aws_s3_bucket.app_bucket.arn,
    aws_s3_bucket.terraform_state.arn
  ]
}

output "app_bucket_name" {
  description = "Name of the application S3 bucket"
  value       = aws_s3_bucket.app_bucket.id
}

output "app_bucket_arn" {
  description = "ARN of the application S3 bucket"
  value       = aws_s3_bucket.app_bucket.arn
}

output "terraform_state_bucket_name" {
  description = "Name of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

