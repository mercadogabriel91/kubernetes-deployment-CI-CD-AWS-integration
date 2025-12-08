# Kubernetes Deployment Guide

This directory contains Kubernetes manifests for deploying the Main API and Auxiliary Service.

## Directory Structure

```
kubernetes/
├── base/                          # Base manifests (shared across environments)
│   ├── infrastructure/            # Cluster-level resources
│   │   ├── namespace.yaml         # Namespace definition
│   │   ├── service-account.yaml  # Service Account (IAM identity)
│   │   └── kustomization.yaml
│   ├── shared/                    # Shared resources
│   │   ├── configmap.yaml         # Application configuration
│   │   ├── aws-credentials-secret.yaml.example  # AWS credentials template
│   │   └── ecr-registry-secret.yaml.example     # ECR auth template
│   ├── auxiliary-service/         # Auxiliary Service resources
│   │   ├── auxiliary-service-deployment.yaml
│   │   ├── auxiliary-service-service.yaml
│   │   └── kustomization.yaml
│   ├── main-api/                  # Main API resources
│   │   ├── main-api-deployment.yaml
│   │   ├── main-api-service.yaml
│   │   └── kustomization.yaml
│   └── kustomization.yaml         # Root kustomization (combines everything)
└── overlays/                      # Environment-specific overrides
    └── dev/                      # Development environment
        ├── kustomization.yaml    # Image replacements (ECR URLs)
        ├── config.yaml.example  # Configuration template
        └── update-images.sh     # Helper script to update image tags
```

**Organization:** Resources are organized by layer (infrastructure → shared → services) for better maintainability and scalability.

> 💡 **For Reviewers/Interviewers:** 
> - See [`DEPLOYMENT_OPTIONS.md`](../DEPLOYMENT_OPTIONS.md) for cost-effective deployment options
> - See [`REVIEWER_TESTING_GUIDE.md`](../REVIEWER_TESTING_GUIDE.md) for how reviewers can test local Kubernetes setups

---

## 🆓 Local Deployment (For Budget-Conscious Developers)

Deploy to a local Kubernetes cluster (minikube or kind) - **FREE**!

### Prerequisites

1. **Install Kubernetes tools:**
   ```bash
   # Install minikube (macOS)
   brew install minikube
   
   # Or install kind
   brew install kind
   
   # Install kubectl
   brew install kubectl
   ```

2. **Start local cluster:**
   ```bash
   # Option 1: minikube
   minikube start
   
   # Option 2: kind
   kind create cluster --name k-challenge
   ```

3. **Verify cluster:**
   ```bash
   kubectl cluster-info
   ```

### Step 1: Build and Push Images to ECR

Even for local deployment, we'll use ECR images (realistic workflow):

```bash
# Authenticate with ECR
export AWS_PROFILE=your-profile
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1

aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push images
cd services/auxiliary-service
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k-challenge-dev-auxiliary-service:latest .
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k-challenge-dev-auxiliary-service:latest

cd ../main-api
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k-challenge-dev-main-api:latest .
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k-challenge-dev-main-api:latest
```

### Step 2: Create ECR Registry Secret

Kubernetes needs credentials to pull images from ECR:

```bash
export AWS_PROFILE=your-profile
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1
export ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
export ECR_TOKEN=$(aws ecr get-login-password --region $AWS_REGION)

kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=$ECR_REGISTRY \
  --docker-username=AWS \
  --docker-password=$ECR_TOKEN \
  --namespace=k-challenge-namespace \
  --dry-run=client -o yaml | kubectl apply -f -
```

**Note:** ECR tokens expire after 12 hours. Refresh the secret:
```bash
# Re-run the secret creation command above
```

### Step 3: Create AWS Credentials Secret

For local Kubernetes, pods need AWS credentials to access S3 and Parameter Store:

```bash
cd kubernetes/base/shared
cp aws-credentials-secret.yaml.example aws-credentials-secret.yaml

# Edit aws-credentials-secret.yaml and add your AWS credentials (base64 encoded)
# Get base64 encoded values:
echo -n "your-access-key" | base64
echo -n "your-secret-key" | base64

# Apply the secret
kubectl apply -f aws-credentials-secret.yaml
```

### Step 4: Deploy Application

```bash
# Deploy using the dev overlay (automatically uses ECR images)
cd kubernetes
kubectl apply -k overlays/dev
```

### Step 5: Verify Deployment

```bash
# Check pods
kubectl get pods -n k-challenge-namespace

# Check services
kubectl get svc -n k-challenge-namespace

# Check logs
kubectl logs -n k-challenge-namespace -l app=auxiliary-service --tail=50
kubectl logs -n k-challenge-namespace -l app=main-api --tail=50
```

### Step 6: Access Services via Port Forwarding

**Why port forwarding?** Your services are `ClusterIP` type (internal only). Port forwarding creates a tunnel from your local machine to the Kubernetes cluster.

**Option 1: Port Forward in Separate Terminals (Recommended)**

Terminal 1:
```bash
kubectl port-forward -n k-challenge-namespace svc/main-api 3000:3000
```

Terminal 2:
```bash
kubectl port-forward -n k-challenge-namespace svc/auxiliary-service 3001:3001
```

Then test:
```bash
# Test Main API
curl http://localhost:3000/health
curl http://localhost:3000/buckets
curl http://localhost:3000/parameters

# Test Auxiliary Service
curl http://localhost:3001/health
curl http://localhost:3001/version
```

**Option 2: Port Forward in Background**

```bash
# Start port-forwarding in background
kubectl port-forward -n k-challenge-namespace svc/main-api 3000:3000 > /dev/null 2>&1 &
kubectl port-forward -n k-challenge-namespace svc/auxiliary-service 3001:3001 > /dev/null 2>&1 &

# Test endpoints
curl http://localhost:3000/health
curl http://localhost:3001/health

# Stop port-forwarding when done
pkill -f "kubectl port-forward"
```

**Note:** Port forwarding keeps running until you stop it (Ctrl+C) or kill the process. Keep the terminal open or run in background.

### Step 7: Clean Up (When Done)

```bash
# Delete all resources
kubectl delete -k overlays/dev

# Stop local cluster
minikube stop
# OR
kind delete cluster --name k-challenge
```

---

## 💰 EKS Deployment (For Production/Enterprise)

Deploy to AWS EKS - **~$13-31 for 3-7 days** (see cost breakdown below).

### Prerequisites

1. **EKS Cluster** (already created via Terraform or manually)
2. **kubectl configured** to connect to EKS:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name your-cluster-name
   kubectl cluster-info
   ```
3. **IAM Role for Service Account (IRSA)** configured (via Terraform)

### Step 1: Build and Push Images to ECR

Same as local deployment - build and push to ECR:

```bash
export AWS_PROFILE=your-profile
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1

# Authenticate with ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push (same as local)
cd services/auxiliary-service
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k-challenge-dev-auxiliary-service:latest .
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k-challenge-dev-auxiliary-service:latest

cd ../main-api
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k-challenge-dev-main-api:latest .
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k-challenge-dev-main-api:latest
```

### Step 2: Configure Service Account for IRSA

Update the Service Account to use the IAM role created by Terraform:

```bash
# Get the IAM role ARN from Terraform outputs
cd terraform
terraform output kubernetes_service_account_role_arn

# Update service-account.yaml with the role ARN
# Edit: kubernetes/base/infrastructure/service-account.yaml
# Uncomment and update:
# annotations:
#   eks.amazonaws.com/role-arn: <role-arn-from-terraform-output>
```

### Step 3: Create ECR Registry Secret (if not using IRSA for ECR)

If your Service Account doesn't have ECR permissions, create the secret:

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1
export ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
export ECR_TOKEN=$(aws ecr get-login-password --region $AWS_REGION)

kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=$ECR_REGISTRY \
  --docker-username=AWS \
  --docker-password=$ECR_TOKEN \
  --namespace=k-challenge-namespace
```

**Note:** With IRSA, you can configure the Service Account to pull from ECR without a secret (more secure).

### Step 4: Remove AWS Credentials Secret

For EKS with IRSA, you don't need the AWS credentials secret. The Service Account handles authentication automatically.

**Skip Step 3 from local deployment** - IRSA handles AWS API access.

### Step 5: Deploy Application

```bash
cd kubernetes
kubectl apply -k overlays/dev
```

### Step 6: Verify Deployment

```bash
# Check pods
kubectl get pods -n k-challenge-namespace -o wide

# Check services
kubectl get svc -n k-challenge-namespace

# Check logs
kubectl logs -n k-challenge-namespace -l app=auxiliary-service --tail=50
kubectl logs -n k-challenge-namespace -l app=main-api --tail=50

# If using LoadBalancer service type, get external IP
kubectl get svc -n k-challenge-namespace
```

### EKS Cost Estimate

- **Control Plane:** $0.10/hour = $2.40/day
- **Worker Nodes (2x t3.medium):** ~$1.00/node/day = $2.00/day
- **Total:** ~$4.40/day = ~$13.20 for 3 days, ~$30.80 for 7 days

See [EKS pricing](https://aws.amazon.com/eks/pricing/) for details.

---

## Image Management

### How It Works

Base deployments use **placeholder images** (`auxiliary-service:latest`), and overlays replace them with ECR URLs. This keeps base manifests generic and reusable.

**Base:** `image: auxiliary-service:latest`  
**Overlay:** Replaces with `image: <ECR-URL>/k-challenge-dev-auxiliary-service:latest`

### Updating Image Tags

#### Option 1: Edit Overlay (Manual)

Edit `overlays/dev/kustomization.yaml`:

```yaml
images:
  - name: auxiliary-service
    newTag: v1.2.3  # Update this
```

Then apply: `kubectl apply -k overlays/dev`

#### Option 2: Use Helper Script

```bash
cd overlays/dev
./update-images.sh v1.2.3 v1.2.3
kubectl apply -k .
```

#### Option 3: CI/CD Integration

```bash
cd overlays/dev
kubectl kustomize edit set image auxiliary-service=${ECR_REGISTRY}/k-challenge-dev-auxiliary-service:${NEW_TAG}
kubectl kustomize edit set image main-api=${ECR_REGISTRY}/k-challenge-dev-main-api:${NEW_TAG}
kubectl apply -k .
```

### Preview Changes

Before applying, preview what will be deployed:

```bash
kubectl kustomize overlays/dev
```

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n k-challenge-namespace

# Describe pod for details
kubectl describe pod <pod-name> -n k-challenge-namespace

# Check events
kubectl get events -n k-challenge-namespace --sort-by='.lastTimestamp'
```

### Image Pull Errors

```bash
# Verify ECR secret exists
kubectl get secret ecr-registry-secret -n k-challenge-namespace

# Refresh ECR secret (tokens expire after 12 hours)
export ECR_TOKEN=$(aws ecr get-login-password --region us-east-1)
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=$ECR_REGISTRY \
  --docker-username=AWS \
  --docker-password=$ECR_TOKEN \
  --namespace=k-challenge-namespace \
  --dry-run=client -o yaml | kubectl apply -f -
```

### AWS API Access Issues

**Local Kubernetes:**
- Verify AWS credentials secret exists: `kubectl get secret aws-credentials -n k-challenge-namespace`
- Check credentials are correct in the secret

**EKS:**
- Verify Service Account has IRSA annotation: `kubectl describe sa k-challenge-app-sa -n k-challenge-namespace`
- Verify IAM role has correct permissions

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n k-challenge-namespace

# Test service from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- sh
# Inside pod: curl http://auxiliary-service:3001/health
```

---

## Key Differences: Local vs EKS

| Feature | Local (minikube/kind) | EKS |
|---------|----------------------|-----|
| **Cost** | FREE | ~$4.40/day |
| **AWS Auth** | Secret with credentials | IRSA (Service Account) |
| **ECR Auth** | imagePullSecret | IRSA or imagePullSecret |
| **Setup Time** | 5 minutes | 30+ minutes (cluster creation) |
| **Use Case** | Development, testing | Production, CI/CD |

---
