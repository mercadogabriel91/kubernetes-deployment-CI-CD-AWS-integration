#!/bin/bash

# Argo CD Installation Script
# Installs Argo CD in a local Kubernetes cluster (minikube/kind)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Argo CD Installation Script${NC}"
echo "=================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster.${NC}"
    echo "Please ensure your cluster is running:"
    echo "  - minikube: minikube start"
    echo "  - kind: kind create cluster"
    exit 1
fi

echo -e "${GREEN}✅ Kubernetes cluster is accessible${NC}"

# Create Argo CD namespace
echo ""
echo -e "${YELLOW}📦 Creating argocd namespace...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install Argo CD
echo ""
echo -e "${YELLOW}📥 Installing Argo CD...${NC}"
echo "This may take 2-3 minutes..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD pods to be ready
echo ""
echo -e "${YELLOW}⏳ Waiting for Argo CD pods to be ready...${NC}"
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s || {
    echo -e "${RED}❌ Argo CD pods failed to start. Check status with:${NC}"
    echo "  kubectl get pods -n argocd"
    exit 1
}

echo -e "${GREEN}✅ Argo CD is installed and running!${NC}"

# Get admin password
echo ""
echo -e "${YELLOW}🔑 Retrieving Argo CD admin password...${NC}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "")

if [ -z "$ARGOCD_PASSWORD" ]; then
    echo -e "${YELLOW}⚠️  Password not available yet. Wait a few seconds and run:${NC}"
    echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo"
else
    echo -e "${GREEN}Admin Password: ${ARGOCD_PASSWORD}${NC}"
fi

# Port forward instructions
echo ""
echo -e "${GREEN}📋 Next Steps:${NC}"
echo "=================================="
echo ""
echo "1. Access Argo CD UI (in a new terminal):"
echo -e "   ${YELLOW}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
echo ""
echo "2. Open browser:"
echo -e "   ${YELLOW}https://localhost:8080${NC}"
echo ""
echo "3. Login credentials:"
echo "   Username: admin"
if [ -n "$ARGOCD_PASSWORD" ]; then
    echo "   Password: $ARGOCD_PASSWORD"
else
    echo "   Password: (run command above to get it)"
fi
echo ""
echo "4. Install Argo CD CLI (optional but recommended):"
echo "   Mac: brew install argocd"
echo "   Linux: curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "   chmod +x /usr/local/bin/argocd"
echo ""
echo "5. Login via CLI:"
echo "   argocd login localhost:8080"
echo ""
echo "6. Create the Application:"
echo "   kubectl apply -f argocd/applications/k-challenge-app.yaml"
echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"

