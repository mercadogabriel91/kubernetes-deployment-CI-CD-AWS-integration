variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  default     = ""
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs"
  type        = list(string)
}

variable "parameter_store_arn" {
  description = "ARN pattern for Parameter Store"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "eks_oidc_provider_id" {
  description = "EKS OIDC provider ID (found in EKS cluster details)"
  type        = string
  default     = ""
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account name"
  type        = string
}

