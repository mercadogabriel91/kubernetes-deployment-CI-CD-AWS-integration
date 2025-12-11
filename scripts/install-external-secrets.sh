#!/bin/bash

# Script to install External Secrets Operator
# This operator syncs secrets/config from AWS Parameter Store to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Installing External Secrets Operator${NC}"
echo "=========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}⚠️  Helm is not installed.${NC}"
    echo -e "${BLUE}💡 Installing Helm is recommended for External Secrets Operator.${NC}"
    echo -e "${BLUE}   macOS: brew install helm${NC}"
    echo -e "${BLUE}   Linux: https://helm.sh/docs/intro/install/${NC}"
    echo ""
    read -p "Continue without Helm? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Install Helm and re-run this script.${NC}"
        exit 0
    fi
    USE_HELM=false
else
    USE_HELM=true
    echo -e "${GREEN}✅ Helm found${NC}"
fi

# Step 1: Install CRDs
echo -e "${BLUE}📦 Step 1: Installing External Secrets Operator CRDs...${NC}"
# Use the correct CRD bundle URL from the official repository
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml

echo -e "${GREEN}✅ CRDs installed${NC}"

# Step 2: Install External Secrets Operator
if [ "$USE_HELM" = true ]; then
    echo -e "${BLUE}📦 Step 2: Installing External Secrets Operator via Helm...${NC}"
    
    # Add Helm repo
    helm repo add external-secrets https://charts.external-secrets.io
    helm repo update
    
    # Create namespace if it doesn't exist
    kubectl create namespace external-secrets-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Install operator
    helm install external-secrets external-secrets/external-secrets \
        -n external-secrets-system \
        --set installCRDs=false  # CRDs already installed above
    
    echo -e "${GREEN}✅ External Secrets Operator installed via Helm${NC}"
else
    echo -e "${BLUE}📦 Step 2: Installing External Secrets Operator...${NC}"
    echo -e "${YELLOW}⚠️  Helm is strongly recommended for External Secrets Operator.${NC}"
    echo ""
    echo -e "${BLUE}💡 To install Helm (recommended):${NC}"
    echo "  macOS:   brew install helm"
    echo "  Linux:   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    echo ""
    echo -e "${BLUE}Then re-run this script, or install manually:${NC}"
    echo "  helm repo add external-secrets https://charts.external-secrets.io"
    echo "  helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace"
    echo ""
    echo -e "${GREEN}✅ CRDs are installed.${NC}"
    echo -e "${YELLOW}⚠️  Operator installation requires Helm. Please install Helm and re-run this script.${NC}"
    echo ""
    echo -e "${BLUE}Alternatively, you can use the External Secrets configuration without the operator${NC}"
    echo -e "${BLUE}by manually syncing values from Parameter Store using scripts.${NC}"
    exit 0
fi

# Step 3: Wait for operator to be ready
echo -e "${BLUE}⏳ Step 3: Waiting for External Secrets Operator to be ready...${NC}"
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=external-secrets \
    -n external-secrets-system \
    --timeout=5m || {
    echo -e "${YELLOW}⚠️  Operator may still be starting. Check status with:${NC}"
    echo "  kubectl get pods -n external-secrets-system"
}

echo -e "${GREEN}✅ External Secrets Operator is ready!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "  1. Ensure Parameter Store has these parameters:"
echo "     - /k-challenge/aws/account-id"
echo "     - /k-challenge/aws/region"
echo "     - /k-challenge/aws/ecr-registry"
echo ""
echo "  2. Apply the External Secrets configuration:"
echo "     kubectl apply -f kubernetes/base/shared/external-secrets-setup.yaml"
echo ""
echo "  3. Verify the ConfigMap was created:"
echo "     kubectl get configmap ecr-registry-config -n k-challenge-namespace"
echo "     kubectl get externalsecret ecr-registry-config -n k-challenge-namespace"
echo ""

