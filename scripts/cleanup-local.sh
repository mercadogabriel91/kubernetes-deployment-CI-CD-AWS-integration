#!/bin/bash
# cleanup-local.sh - Cleanup local Kubernetes deployment with options

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "🧹 Local Cleanup Script"
echo "======================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check/prompt for AWS profile (needed for Terraform destroy)
if [ -z "$AWS_PROFILE" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "${YELLOW}AWS_PROFILE not set${NC}"
    echo "Available AWS profiles:"
    aws configure list-profiles 2>/dev/null || grep -E '^\[profile ' ~/.aws/config 2>/dev/null | sed 's/\[profile \(.*\)\]/\1/' || echo "  (none found)"
    echo ""
    read -p "Enter AWS profile to use (or press Enter to use default): " AWS_PROFILE_INPUT
    if [ -n "$AWS_PROFILE_INPUT" ]; then
        export AWS_PROFILE="$AWS_PROFILE_INPUT"
        echo -e "${BLUE}Using AWS profile: $AWS_PROFILE${NC}"
    else
        echo -e "${YELLOW}Using default AWS profile${NC}"
    fi
    echo ""
fi

# Detect Kubernetes type
K8S_TYPE=""
if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
    K8S_TYPE="minikube"
elif command -v kind >/dev/null 2>&1 && kind get clusters 2>/dev/null | grep -q "k-challenge"; then
    K8S_TYPE="kind"
fi

# List AWS resources that will be destroyed
echo -e "${YELLOW}AWS Resources that will be destroyed:${NC}"
echo "  - S3 Buckets (application data, terraform state)"
echo "  - Parameter Store parameters"
echo "  - ECR Repositories"
echo "  - IAM Roles and Policies"
echo "  - OIDC Provider (if created)"
echo ""

# Ask about AWS resources
echo -e "${BLUE}Do you want to destroy AWS infrastructure?${NC}"
echo -e "${YELLOW}This will delete all AWS resources created by Terraform.${NC}"
read -p "Destroy AWS resources? (y/N): " DESTROY_AWS

DESTROY_AWS=$(echo "$DESTROY_AWS" | tr '[:upper:]' '[:lower:]')

# Step 1: Delete Kubernetes resources
echo ""
echo -e "${YELLOW}Step 1: Deleting Kubernetes resources...${NC}"
cd kubernetes
kubectl delete -k overlays/dev --ignore-not-found=true || true
echo -e "${GREEN}✓ Kubernetes resources deleted${NC}"
echo ""

# Step 2: Destroy AWS infrastructure (if requested)
if [ "$DESTROY_AWS" = "y" ] || [ "$DESTROY_AWS" = "yes" ]; then
    echo -e "${YELLOW}Step 2: Destroying AWS infrastructure...${NC}"
    cd "$PROJECT_ROOT/terraform"
    
    # Show what will be destroyed
    echo -e "${BLUE}Running terraform plan to show what will be destroyed...${NC}"
    terraform plan -destroy 2>&1 | head -30 || true
    echo ""
    
    read -p "Confirm destruction of AWS resources? (yes/no): " CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')
    
    if [ "$CONFIRM" = "yes" ]; then
        terraform destroy -auto-approve
        echo -e "${GREEN}✓ AWS infrastructure destroyed${NC}"
    else
        echo -e "${YELLOW}⚠️  AWS infrastructure destruction cancelled${NC}"
    fi
    echo ""
else
    echo -e "${BLUE}Skipping AWS infrastructure destruction${NC}"
    echo -e "${YELLOW}AWS resources are still running and will incur costs${NC}"
    echo "To destroy them later, run:"
    echo "  cd terraform && terraform destroy"
    echo ""
fi

# Step 3: Ask about stopping Kubernetes cluster
if [ -n "$K8S_TYPE" ]; then
    echo -e "${BLUE}Do you want to stop the local Kubernetes cluster?${NC}"
    echo -e "${YELLOW}Cluster type: ${K8S_TYPE}${NC}"
    read -p "Stop Kubernetes cluster? (y/N): " STOP_K8S
    
    STOP_K8S=$(echo "$STOP_K8S" | tr '[:upper:]' '[:lower:]')
    
    if [ "$STOP_K8S" = "y" ] || [ "$STOP_K8S" = "yes" ]; then
        echo ""
        echo -e "${YELLOW}Step 3: Stopping Kubernetes cluster...${NC}"
        if [ "$K8S_TYPE" = "minikube" ]; then
            minikube stop
            echo -e "${GREEN}✓ Minikube stopped${NC}"
            echo "To start again: minikube start"
        elif [ "$K8S_TYPE" = "kind" ]; then
            kind delete cluster --name k-challenge
            echo -e "${GREEN}✓ Kind cluster deleted${NC}"
            echo "To create again: kind create cluster --name k-challenge"
        fi
        echo ""
    else
        echo -e "${BLUE}Kubernetes cluster will continue running${NC}"
        echo ""
    fi
fi

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ "$DESTROY_AWS" = "y" ] || [ "$DESTROY_AWS" = "yes" ]; then
    echo -e "${GREEN}✓ Kubernetes resources deleted${NC}"
    echo -e "${GREEN}✓ AWS infrastructure destroyed${NC}"
    if [ "$STOP_K8S" = "y" ] || [ "$STOP_K8S" = "yes" ]; then
        echo -e "${GREEN}✓ Kubernetes cluster stopped${NC}"
    fi
    echo ""
    echo "All resources have been cleaned up."
    echo "No further charges should occur."
else
    echo -e "${GREEN}✓ Kubernetes resources deleted${NC}"
    echo -e "${YELLOW}⚠️  AWS infrastructure is still running${NC}"
    echo ""
    echo "AWS resources will continue to incur costs:"
    echo "  - S3: ~$0.023/GB-month (minimal)"
    echo "  - Parameter Store: Free (Standard)"
    echo "  - ECR: Free (first 500MB)"
    echo ""
    echo "To destroy AWS resources later:"
    echo "  cd terraform && terraform destroy"
fi

echo ""

