# Kubernetes Deployment CI/CD with AWS Integration

A complete GitOps-based CI/CD pipeline for deploying containerized applications to Kubernetes, integrated with AWS services (ECR, S3, Parameter Store) using Argo CD, Terraform, and GitHub Actions.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Developer                                │
│                    (Code Changes)                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ git push
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Repository                              │
│              (Source of Truth - GitOps)                          │
└──────────────┬──────────────────────────────┬──────────────────┘
               │                                │
               │                                │
    ┌──────────▼──────────┐         ┌──────────▼──────────┐
    │  GitHub Actions     │         │   Argo CD            │
    │  (CI Pipeline)      │         │  (CD Controller)     │
    │                     │         │                      │
    │  • Build Images    │         │  • Watches Git       │
    │  • Push to ECR      │         │  • Auto-syncs       │
    │  • Update Manifests │         │  • Deploys to K8s    │
    └──────────┬──────────┘         └──────────┬──────────┘
               │                                │
               │                                │
    ┌──────────▼──────────┐         ┌──────────▼──────────┐
    │   AWS ECR            │         │   Kubernetes        │
    │  (Container Registry)│         │     Cluster         │
    │                      │         │                     │
    │  • Stores Images    │         │  • Main API          │
    │  • Image Tags       │         │  • Auxiliary Service│
    └──────────────────────┘         └─────────────────────┘
               │                                │
               │                                │
               └──────────┬─────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   AWS Services        │
              │                       │
              │  • S3 Buckets         │
              │  • Parameter Store    │
              │  • IAM Roles (IRSA)   │
              └───────────────────────┘
```

## 🔄 CI/CD Flow

### 1. **Code Change** → Developer pushes code to `main` branch

### 2. **GitHub Actions (CI)**
   - Detects changes in `services/**/*`
   - Builds Docker images for both services
   - Tags images with `:latest` and `:<commit-sha>`
   - Pushes images to AWS ECR
   - Updates `kubernetes/overlays/dev/kustomization.yaml` with commit SHA
   - Commits and pushes updated manifests back to Git

### 3. **Argo CD (CD)**
   - Detects Git changes (auto-sync every ~3 minutes)
   - Reads Kubernetes manifests from `kubernetes/overlays/dev/`
   - Applies Kustomize transformations
   - Deploys updated images to Kubernetes cluster
   - Pods restart with new image tags

### 4. **Result**
   - Kubernetes cluster is always in sync with Git
   - Every code change automatically triggers a deployment
   - Full traceability (commit SHA = image tag)

## 📁 Project Structure

```
kubernetes-deployment-CI-CD-AWS-integration/
│
├── services/                    # Application source code
│   ├── main-api/               # Main API service (NestJS)
│   ├── auxiliary-service/      # Auxiliary service (NestJS)
│   └── README.md              # Services documentation
│
├── kubernetes/                  # Kubernetes manifests
│   ├── base/                   # Base configurations (shared)
│   │   ├── infrastructure/     # Namespace, ServiceAccount
│   │   ├── shared/            # ConfigMaps, Secrets
│   │   ├── main-api/          # Main API deployment
│   │   └── auxiliary-service/ # Auxiliary service deployment
│   └── overlays/              # Environment-specific configs
│       └── dev/               # Development environment
│           └── kustomization.yaml  # Image tags (updated by CI)
│
├── terraform/                   # Infrastructure as Code
│   ├── modules/
│   │   ├── s3/                # S3 buckets
│   │   ├── parameter-store/   # SSM Parameter Store
│   │   ├── ecr/               # ECR repositories
│   │   └── iam/               # IAM roles & policies (IRSA)
│   └── README.md              # Terraform documentation
│
├── argocd/                      # Argo CD configuration
│   ├── applications/          # Argo CD Application manifests
│   ├── install.sh            # Installation script
│   └── README.md             # Argo CD documentation
│
├── .github/
│   └── workflows/
│       └── build-and-push.yml  # CI/CD pipeline
│
└── scripts/                     # Utility scripts
    └── README.md              # Scripts documentation
```

## 🚀 Quick Start

### Prerequisites

- **Kubernetes cluster** (EKS, minikube, or local)
- **AWS CLI** configured with appropriate credentials
- **kubectl** configured to access your cluster
- **Terraform** >= 1.5.0
- **Node.js** 20+ (for local development)

### 1. Provision AWS Infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

export AWS_PROFILE=your-profile  # If using named profile
terraform init
terraform plan
terraform apply
```

This creates:
- ECR repositories for Docker images
- S3 buckets
- Parameter Store entries
- IAM roles for GitHub Actions and Kubernetes (IRSA)

See [`terraform/README.md`](terraform/README.md) for details.

### 2. Install Argo CD

```bash
./argocd/install.sh
```

Or manually:
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s
```

See [`argocd/README.md`](argocd/README.md) for details.

### 3. Configure GitHub Actions

Set the following secrets in your GitHub repository:
- `AWS_ROLE_ARN`: IAM role ARN for GitHub Actions (from Terraform output)

### 4. Deploy Application

Argo CD will automatically deploy when you push to `main` branch. Or manually:

```bash
kubectl apply -f argocd/applications/k-challenge-app.yaml
```

### 5. Access Services

**Argo CD UI:**
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
# Open https://localhost:8080
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Application Services:**
```bash
# Port forward to access services
kubectl port-forward -n k-challenge-namespace svc/main-api 3000:3000
kubectl port-forward -n k-challenge-namespace svc/auxiliary-service 3001:3001
```

## 🔑 Key Concepts

### GitOps
- **Git is the source of truth** - All Kubernetes manifests are in Git
- **Argo CD watches Git** - Automatically syncs changes to cluster
- **Declarative** - Describes desired state, not how to achieve it

### Kustomize
- **Base + Overlays** - Reusable base configs with environment-specific overrides
- **Image Replacement** - Overlays inject ECR image URLs and tags
- **No Templating** - Plain YAML, no complex templating engines

### IRSA (IAM Roles for Service Accounts)
- **Secure AWS Access** - Kubernetes pods use IAM roles, not access keys
- **Fine-grained Permissions** - Each service gets only what it needs
- **No Secrets Management** - AWS SDK automatically handles credentials

### CI/CD Pipeline
- **Automated Builds** - Every push to `main` triggers image build
- **Immutable Tags** - Images tagged with commit SHA for traceability
- **Git-based Updates** - CI updates manifests, CD deploys them

## 📚 Documentation

Each directory contains detailed documentation:

- **[`services/README.md`](services/README.md)** - Application services (NestJS)
- **[`kubernetes/README.md`](kubernetes/README.md)** - Kubernetes manifests structure
- **[`terraform/README.md`](terraform/README.md)** - Infrastructure provisioning
- **[`argocd/README.md`](argocd/README.md)** - Argo CD setup and usage
- **[`scripts/README.md`](scripts/README.md)** - Utility scripts

## 🛠️ Development Workflow

1. **Make code changes** in `services/`
2. **Commit and push** to `main` branch
3. **GitHub Actions** builds and pushes images
4. **Argo CD** automatically deploys (within 3 minutes)
5. **Verify deployment** in Argo CD UI or via `kubectl`

## 🔍 Monitoring & Troubleshooting

### Check Argo CD Status
```bash
kubectl get application k-challenge-app -n argocd
kubectl describe application k-challenge-app -n argocd
```

### Check Pod Status
```bash
kubectl get pods -n k-challenge-namespace
kubectl logs -n k-challenge-namespace deployment/main-api
kubectl logs -n k-challenge-namespace deployment/auxiliary-service
```

### Check Image Tags
```bash
kubectl get deployment main-api -n k-challenge-namespace -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl get deployment auxiliary-service -n k-challenge-namespace -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### View Argo CD Sync History
```bash
kubectl describe application k-challenge-app -n argocd | grep -A 20 "History:"
```

## 🎯 Features

- ✅ **Full GitOps** - Git as single source of truth
- ✅ **Automated CI/CD** - Zero-touch deployments
- ✅ **Immutable Images** - Commit SHA-based tagging
- ✅ **Secure AWS Access** - IRSA for Kubernetes pods
- ✅ **Infrastructure as Code** - Terraform for AWS resources
- ✅ **Environment Separation** - Kustomize overlays for different environments
- ✅ **Auto-sync** - Argo CD automatically syncs Git changes
- ✅ **Rollback Support** - Argo CD maintains deployment history

## 📝 License

This project is part of the Kantox Cloud Engineer Challenge.

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test locally
4. Push to `main` (triggers automatic deployment)

---

**Questions?** Check the README files in each subdirectory for detailed documentation.

