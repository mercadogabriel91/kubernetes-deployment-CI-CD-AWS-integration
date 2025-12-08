variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "k-challenge"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_version" {
  description = "Application version to store in Parameter Store"
  type        = string
  default     = "1.0.0"
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo' (e.g., 'username/k-challenge')"
  type        = string
  # No default - must be provided via terraform.tfvars
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster (required if using IRSA for Kubernetes Service Accounts). Note: This Terraform config does NOT create the EKS cluster - it only creates IAM roles for an existing cluster."
  type        = string
  default     = "" # Leave empty if not using EKS or if using local Kubernetes (minikube/kind)
}

variable "eks_oidc_provider_id" {
  description = "EKS OIDC provider ID (required for IRSA). Found in EKS cluster details in AWS Console, or via: aws eks describe-cluster --name <cluster-name> --query 'cluster.identity.oidc.issuer' --output text | cut -d '/' -f 5"
  type        = string
  default     = "" # Leave empty if not using EKS/IRSA. Required if eks_cluster_name is set.
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "k-challenge"
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account name"
  type        = string
  default     = "k-app-sa"
}

