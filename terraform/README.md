# Terraform Infrastructure

This directory contains Terraform configuration for provisioning AWS infrastructure required for the k Challenge.

## Structure

```
terraform/
├── main.tf                    # Main Terraform configuration
├── variables.tf                # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example variables file
├── modules/
│   ├── s3/                    # S3 buckets module
│   ├── parameter-store/       # Parameter Store module
│   └── iam/                   # IAM roles and policies module
└── README.md                  # This file
```

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
   ```bash
   aws configure --profile gabe-personal
   ```

2. **Terraform installed** (>= 1.5.0)
   ```bash
   brew install terraform  # macOS
   # or download from https://www.terraform.io/downloads
   ```

3. **Set AWS profile** (if using named profile)
   ```bash
   export AWS_PROFILE=gabe-personal
   ```

## Quick Start

1. **Copy the example variables file**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with your values
   ```hcl
   aws_region              = "us-east-1"
   project_name            = "k-challenge"
   environment             = "dev"
   app_version             = "1.0.0"
   github_repository       = "your-username/kubernetes-deployment-CI-CD-AWS-integration"
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review the execution plan**
   ```bash
   terraform plan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply
   ```

6. **View outputs**
   ```bash
   terraform output
   ```

## Modules

### S3 Module

Creates S3 buckets for:
- Application data storage
- Terraform state storage (optional, for remote state)

Features:
- Versioning enabled
- Server-side encryption (AES256)
- Public access blocked
- Proper tagging

### Parameter Store Module

Creates SSM Parameter Store parameters:
- `/kantox-challenge/app-version` - Application version
- `/kantox-challenge/environment` - Environment identifier
- `/kantox-challenge/main-api/port` - Main API port
- `/kantox-challenge/auxiliary-service/port` - Auxiliary Service port
- `/kantox-challenge/auxiliary-service/url` - Auxiliary Service URL

### IAM Module

Creates IAM roles and policies for:

1. **GitHub Actions** (OIDC-based authentication)
   - ECR push/pull permissions
   - S3 read/write permissions
   - Parameter Store read/write permissions

2. **Kubernetes Service Account** (IRSA - IAM Roles for Service Accounts)
   - S3 read/write permissions
   - Parameter Store read permissions
   - Requires EKS cluster with OIDC provider

## Variables

See `variables.tf` for all available variables. Key variables:

- `aws_region` - AWS region (default: us-east-1)
- `project_name` - Project name (default: k-challenge)
- `environment` - Environment name (default: dev)
- `app_version` - Application version (default: 1.0.0)
- `github_repository` - GitHub repo for OIDC (format: owner/repo)
- `eks_cluster_name` - EKS cluster name (optional, for IRSA)

## Outputs

- `s3_bucket_names` - Names of created S3 buckets
- `s3_bucket_arns` - ARNs of created S3 buckets
- `parameter_store_paths` - Paths of Parameter Store parameters
- `github_actions_role_arn` - ARN of GitHub Actions IAM role
- `kubernetes_service_account_role_arn` - ARN of Kubernetes Service Account IAM role

## Remote State (Optional)

To use remote state storage in S3:

1. First, create the S3 bucket manually or uncomment the backend in `main.tf`
2. Update the backend configuration with your bucket name
3. Run `terraform init` again to migrate state

## Security Notes

- Never commit `terraform.tfvars` files (they're gitignored)
- Use IAM roles with least privilege
- GitHub Actions uses OIDC (no long-lived credentials)
- Kubernetes uses IRSA (no AWS keys in pods)

## Destroying Resources

To destroy all created resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources created by Terraform, including S3 buckets and their contents.

## Troubleshooting

### "Error: No valid credential sources found"
- Ensure AWS credentials are configured: `aws configure list`
- Export AWS_PROFILE if using named profile: `export AWS_PROFILE=gabe-personal`

### "Error: Error creating IAM OIDC Provider"
- GitHub OIDC provider may already exist. Check AWS Console or use `terraform import`

### "Error: InvalidParameterException: Parameter name must be a fully qualified name"
- Parameter Store names must start with `/`. The module handles this automatically.

## Next Steps

After applying Terraform:
1. Use the outputs to configure Kubernetes manifests
2. Update GitHub Actions workflow with the IAM role ARN
3. Configure Kubernetes Service Account with the IRSA role ARN

