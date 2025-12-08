# Deployment Scripts

Scripts for deploying and cleaning up the application.

## Scripts

### `deploy-local.sh` - Full Local Deployment

Deploys everything locally including AWS infrastructure (Terraform) + Kubernetes.

**Use this when:** You're starting from scratch or need to redeploy AWS infrastructure.

### `deploy-local-only.sh` - Local Kubernetes Only (Recommended if AWS exists)

Deploys only to local Kubernetes, skips Terraform (assumes AWS infrastructure already exists).

**Use this when:** AWS infrastructure is already deployed and you just want to deploy/update Kubernetes.

**What it does:**
1. Checks/starts local Kubernetes (minikube or kind)
2. Deploys AWS infrastructure (S3, Parameter Store, ECR, IAM) via Terraform
3. Builds and pushes Docker images to ECR
4. Creates Kubernetes secrets (ECR auth, AWS credentials)
5. Deploys Kubernetes manifests
6. Waits for pods and runs health checks

**Usage:**
```bash
./scripts/deploy-local.sh
```

**Requirements:**
- minikube OR kind installed
- AWS CLI configured
- Docker running
- Terraform installed

**Cost:** ~$0.50-$1.00 per hour (AWS resources only, Kubernetes is FREE)

---

### `deploy-local-only.sh` - Local Kubernetes Only

Deploys only to local Kubernetes, skips Terraform deployment.

**What it does:**
1. Checks/starts local Kubernetes (minikube or kind)
2. Verifies ECR repositories exist
3. Optionally rebuilds/pushes Docker images (asks you)
4. Creates Kubernetes secrets (ECR auth, AWS credentials)
5. Deploys Kubernetes manifests
6. Waits for pods and runs health checks

**Usage:**
```bash
./scripts/deploy-local-only.sh
```

**Requirements:**
- minikube OR kind installed
- AWS CLI configured
- Docker running
- AWS infrastructure already deployed (via Terraform)

**Cost:** $0 (uses existing AWS infrastructure, Kubernetes is FREE)

**When to use:**
- AWS infrastructure is already deployed
- You just want to update/redeploy Kubernetes
- Faster deployment (skips Terraform)

---

### `cleanup-local.sh` - Local Cleanup

Cleans up local Kubernetes deployment with interactive options.

**What it does:**
1. Deletes Kubernetes resources
2. **Asks if you want to destroy AWS infrastructure** (y/n)
   - If **yes**: Destroys all AWS resources (S3, Parameter Store, ECR, IAM)
   - If **no**: Keeps AWS resources running (you pay for them)
3. **Asks if you want to stop Kubernetes cluster** (y/n)
   - If **yes**: Stops minikube or deletes kind cluster
   - If **no**: Keeps cluster running

**Usage:**
```bash
./scripts/cleanup-local.sh
```

**Interactive prompts:**
1. `Destroy AWS resources? (y/N)` - Destroys Terraform-managed AWS resources
2. `Stop Kubernetes cluster? (y/N)` - Stops local Kubernetes cluster

**Example flow:**
```
🧹 Local Cleanup Script
=======================

AWS Resources that will be destroyed:
  - S3 Buckets (application data, terraform state)
  - Parameter Store parameters
  - ECR Repositories
  - IAM Roles and Policies
  - OIDC Provider (if created)

Do you want to destroy AWS infrastructure?
Destroy AWS resources? (y/N): n

Step 1: Deleting Kubernetes resources...
✓ Kubernetes resources deleted

Skipping AWS infrastructure destruction
AWS resources are still running and will incur costs

Do you want to stop the local Kubernetes cluster?
Stop Kubernetes cluster? (y/N): y

Step 3: Stopping Kubernetes cluster...
✓ Minikube stopped
```


## Quick Start

### Option 1: Deploy Everything (First Time)
```bash
# Make sure you have AWS credentials configured
export AWS_PROFILE=your-profile
# Or: export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=...

# Deploy AWS infrastructure + Kubernetes
./scripts/deploy-local.sh
```

### Option 2: Deploy Kubernetes Only (AWS Already Exists)
```bash
# Make sure you have AWS credentials configured
export AWS_PROFILE=your-profile

# Deploy only Kubernetes (skips Terraform)
./scripts/deploy-local-only.sh
```

### Cleanup
```bash
# Interactive cleanup
./scripts/cleanup-local.sh

# Answer prompts:
# - Destroy AWS resources? (y/N) - Choose based on whether you want to keep AWS resources
# - Stop Kubernetes cluster? (y/N) - Choose based on whether you want to keep cluster running
```

---

## Cost Management

### Keep AWS Resources Running
- **When:** You want to test multiple times without redeploying AWS infrastructure
- **Cost:** ~$0.50-$1.00 per hour (S3, Parameter Store, ECR are mostly free)
- **Cleanup:** Run `cleanup-local.sh` and answer "n" to AWS destruction

### Destroy Everything
- **When:** You're done testing and want to avoid all costs
- **Cost:** $0 after cleanup
- **Cleanup:** Run `cleanup-local.sh` and answer "y" to AWS destruction and cluster stop

---

## Troubleshooting

### Script fails at "Checking prerequisites"
- Install missing tools: `brew install terraform kubectl docker awscli`
- For Kubernetes: `brew install minikube` OR `brew install kind`

### Script fails at "Cannot connect to Kubernetes cluster"
- Start minikube: `minikube start`
- Or create kind cluster: `kind create cluster --name k-challenge`

### Script fails at AWS authentication
- Configure AWS: `aws configure` or `export AWS_PROFILE=your-profile`
- Verify: `aws sts get-caller-identity`

### Pods fail to start
- Check ECR secret: `kubectl get secret ecr-registry-secret -n k-challenge-namespace`
- Check AWS credentials secret: `kubectl get secret aws-credentials -n k-challenge-namespace`
- View pod logs: `kubectl logs -n k-challenge-namespace -l app=main-api`

