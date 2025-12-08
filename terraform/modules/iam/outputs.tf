output "github_actions_role_arn" {
  description = "ARN of IAM role for GitHub Actions"
  value       = var.github_repository != "" ? aws_iam_role.github_actions[0].arn : ""
}

output "kubernetes_service_account_role_arn" {
  description = "ARN of IAM role for Kubernetes Service Account"
  value       = var.eks_cluster_name != "" && var.eks_oidc_provider_id != "" ? aws_iam_role.kubernetes_service_account[0].arn : ""
}

output "oidc_provider_arn" {
  description = "ARN of OIDC provider for GitHub Actions"
  value       = var.github_repository != "" ? aws_iam_openid_connect_provider.github[0].arn : ""
}

