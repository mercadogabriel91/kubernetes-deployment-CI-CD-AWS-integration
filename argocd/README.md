# Argo CD GitOps Deployment

This directory contains Argo CD configuration for GitOps-based deployment of the K-Challenge application.

## What is Argo CD?

**Argo CD** is a declarative, GitOps continuous delivery tool for Kubernetes. It:
- ✅ Watches your Git repository for changes
- ✅ Automatically syncs Kubernetes manifests from Git to your cluster
- ✅ Shows you what's deployed vs what's in Git (drift detection)
- ✅ Provides rollback capabilities
- ✅ Supports Kustomize, Helm, and plain YAML

## Architecture

```
┌─────────────────┐
│   Git Repo      │
│  (Source of     │
│   Truth)        │
└────────┬────────┘
         │
         │ Watches for changes
         │
┌────────▼────────┐
│   Argo CD       │
│  (Controller)   │
└────────┬────────┘
         │
         │ Syncs manifests
         │
┌────────▼────────┐
│  Kubernetes     │
│    Cluster      │
└─────────────────┘
```

## Directory Structure

```
argocd/
├── applications/
│   └── k-challenge-app.yaml    # Argo CD Application manifest
├── install.sh                  # Installation script
└── README.md                   # This file
```

## Quick Start

### 1. Install Argo CD

```bash
# Run the installation script
./argocd/install.sh
```

Or manually:
```bash
# Create namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s
```

### 2. Access Argo CD UI

**Port Forward:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Open Browser:**
```
https://localhost:8080
```

**Get Admin Password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

**Login:**
- Username: `admin`
- Password: (from command above)

### 3. Install Argo CD CLI (Optional but Recommended)

**Mac:**
```bash
brew install argocd
```

**Linux:**
```bash
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```

**Login via CLI:**
```bash
argocd login localhost:8080
# Username: admin
# Password: (from step 2)
```

### 4. Create the Application

```bash
kubectl apply -f argocd/applications/k-challenge-app.yaml
```

### 5. Verify Sync

**Via CLI:**
```bash
# List applications
argocd app list

# Get application details
argocd app get k-challenge-app

# Watch sync status
argocd app get k-challenge-app --watch
```

**Via UI:**
- Open Argo CD UI (https://localhost:8080)
- Click on `k-challenge-app`
- View sync status and resources

## How It Works

### Application Manifest

The `k-challenge-app.yaml` file defines:

1. **Source**: Git repository and path
   - Repo: `https://github.com/mercadogabriel91/kubernetes-deployment-CI-CD-AWS-integration.git`
   - Branch: `main`
   - Path: `kubernetes/overlays/dev` (Kustomize overlay)

2. **Destination**: Where to deploy
   - Cluster: Current cluster (`https://kubernetes.default.svc`)
   - Namespace: `k-challenge-namespace`

3. **Sync Policy**: How to sync
   - **Automated**: Auto-sync when Git changes
   - **Prune**: Delete resources removed from Git
   - **SelfHeal**: Auto-sync if cluster drifts from Git

### GitOps Flow

```
1. Developer commits changes to Git
   ↓
2. GitHub Actions builds Docker images & pushes to ECR
   ↓
3. GitHub Actions updates image tags in kubernetes/overlays/dev/kustomization.yaml
   ↓
4. Argo CD detects Git changes (polls every 3 minutes by default)
   ↓
5. Argo CD builds Kustomize overlay (resolves images, applies patches)
   ↓
6. Argo CD syncs manifests to Kubernetes cluster
   ↓
7. Kubernetes deploys new version
   ↓
8. Argo CD shows "Synced" status
```

## Application Status

### Healthy States
- ✅ **Synced**: Git and cluster match
- ✅ **Healthy**: All resources are healthy

### Unhealthy States
- ⚠️ **OutOfSync**: Git and cluster differ (needs sync)
- ⚠️ **Degraded**: Resources exist but unhealthy
- ❌ **Missing**: Resources in Git but not in cluster

### Check Status

```bash
# Get detailed status
argocd app get k-challenge-app

# List all resources
argocd app resources k-challenge-app

# View resource details
argocd app resource k-challenge-app deployment/auxiliary-service
```

## Common Operations

### Manual Sync

```bash
# Sync application
argocd app sync k-challenge-app

# Sync with prune (delete resources not in Git)
argocd app sync k-challenge-app --prune

# Sync specific resource
argocd app sync k-challenge-app --resource deployment/auxiliary-service
```

### Rollback

```bash
# View history
argocd app history k-challenge-app

# Rollback to previous version
argocd app rollback k-challenge-app

# Rollback to specific revision
argocd app rollback k-challenge-app <REVISION>
```

### Refresh

```bash
# Force refresh (check Git for changes)
argocd app get k-challenge-app --refresh
```

### Delete

```bash
# Delete application (doesn't delete resources)
argocd app delete k-challenge-app

# Delete application and resources
argocd app delete k-challenge-app --cascade
```

## Integration with CI/CD

### GitOps Best Practice: Main Branch Only

**✅ Best Practice**: Argo CD only syncs from the `main` branch (after PR merge).

**Why?**
- Code is reviewed before deployment
- CI/CD tests must pass before merge
- Clear audit trail
- Easy rollback
- No accidental deployments from feature branches

**Workflow:**
```
Feature Branch → PR → Review → CI/CD Tests → Merge to Main → Argo CD Syncs → Deploy
```

See [`GITOPS_BEST_PRACTICES.md`](./GITOPS_BEST_PRACTICES.md) for detailed best practices.

### GitHub Actions Workflow

When GitHub Actions updates the image tag in `kubernetes/overlays/dev/kustomization.yaml`:

1. **PR is merged** to `main` branch (after review and CI/CD passes)
2. **Argo CD detects** the change (within 3 minutes)
3. **Argo CD syncs** automatically (if `automated: true`)
4. **Kubernetes deploys** the new version

**No manual intervention needed for dev environment!**

**Production**: Requires manual sync approval (see `k-challenge-app-prod.yaml.example`)

### Triggering Sync from GitHub Actions

You can also trigger Argo CD sync from GitHub Actions:

```yaml
# In .github/workflows/deploy.yml
- name: Trigger Argo CD Sync
  run: |
    argocd app sync k-challenge-app --server ${{ secrets.ARGOCD_SERVER }} --auth-token ${{ secrets.ARGOCD_AUTH_TOKEN }}
```

Or use Argo CD CLI in GitHub Actions:
```yaml
- name: Sync Argo CD Application
  uses: argoproj/actions-runner@main
  with:
    argocd-version: latest
    command: app sync k-challenge-app
```

## Troubleshooting

### Application Won't Sync

**Check:**
```bash
# View application details
argocd app get k-challenge-app

# Check Argo CD controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Force refresh
argocd app get k-challenge-app --refresh
```

**Common Issues:**
1. **Git repo not accessible** - Check URL and credentials
2. **Path doesn't exist** - Verify `kubernetes/overlays/dev` exists in Git
3. **Kustomize build fails** - Check `kustomization.yaml` syntax
4. **Namespace doesn't exist** - Argo CD will create it (if `CreateNamespace=true`)

### Resources Not Created

**Check:**
```bash
# View application resources
argocd app resources k-challenge-app

# Check resource details
argocd app resource k-challenge-app deployment/auxiliary-service

# View resource events
kubectl describe deployment/auxiliary-service -n k-challenge-namespace
```

### Kustomize Build Issues

**Check:**
```bash
# Test Kustomize build locally
kubectl kustomize kubernetes/overlays/dev

# Check for errors
argocd app get k-challenge-app --show-operation
```

### Image Pull Errors

If pods fail with `ImagePullBackOff`:
1. Ensure ECR credentials are configured (see `kubernetes/base/shared/ecr-registry-secret.yaml.example`)
2. Check image URL in `kubernetes/overlays/dev/kustomization.yaml`
3. Verify image exists in ECR

## Configuration

### Changing Git Repository

Edit `argocd/applications/k-challenge-app.yaml`:
```yaml
source:
  repoURL: https://github.com/YOUR_USERNAME/YOUR_REPO.git
  targetRevision: main  # BEST PRACTICE: Only sync from main branch
  path: kubernetes/overlays/dev
```

### Changing Sync Policy

**Manual Sync (Production):**
```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
# Remove automated: section = requires manual approval
```

**Automated Sync (Dev/Staging - Current):**
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
```

### Multiple Environments

**Recommended Setup:**

1. **Dev Environment** (Current):
   - File: `argocd/applications/k-challenge-app.yaml`
   - Path: `kubernetes/overlays/dev`
   - Sync: Automated
   - Branch: `main`

2. **Staging Environment**:
   - File: `argocd/applications/k-challenge-app-staging.yaml`
   - Path: `kubernetes/overlays/staging`
   - Sync: Automated
   - Branch: `main`

3. **Production Environment**:
   - File: `argocd/applications/k-challenge-app-prod.yaml` (see example)
   - Path: `kubernetes/overlays/prod`
   - Sync: Manual (requires approval)
   - Branch: `main`

**All environments sync from `main` branch** - different overlays provide environment-specific configs.

## Best Practices

1. **Git as Source of Truth**: All changes go through Git, never manual `kubectl apply`
2. **Automated Sync for Dev**: Enable `automated: true` for dev environment
3. **Manual Sync for Prod**: Use manual sync for production (requires approval)
4. **Self-Healing**: Enable `selfHeal: true` to prevent manual cluster changes
5. **Prune**: Enable `prune: true` to clean up deleted resources
6. **Monitor**: Regularly check Argo CD UI for sync status
7. **Rollback**: Use Argo CD rollback instead of manual kubectl commands

## Security Considerations

1. **Git Repository Access**: Argo CD needs read access to your Git repo
   - Public repos: No credentials needed
   - Private repos: Configure SSH keys or HTTPS credentials in Argo CD

2. **Kubernetes RBAC**: Argo CD uses ServiceAccount with RBAC permissions
   - Default installation creates necessary RBAC resources
   - Can be customized for stricter permissions

3. **Secrets Management**: 
   - Don't commit secrets to Git
   - Use Kubernetes Secrets or external secret managers
   - Argo CD can sync secrets from Git (if encrypted) or external sources

## Best Practices

See [`GITOPS_BEST_PRACTICES.md`](./GITOPS_BEST_PRACTICES.md) for:
- ✅ Why sync only from `main` branch
- ✅ GitOps branching strategies
- ✅ Automated vs manual sync
- ✅ Branch protection rules
- ✅ Environment-specific configurations
- ✅ Common mistakes to avoid

## Resources

- **Official Docs**: https://argo-cd.readthedocs.io/
- **GitOps Guide**: https://www.gitops.tech/
- **Argo CD GitHub**: https://github.com/argoproj/argo-cd
- **Kustomize Docs**: https://kustomize.io/
- **Best Practices**: See [`GITOPS_BEST_PRACTICES.md`](./GITOPS_BEST_PRACTICES.md)


**Happy GitOps! 🚀**

