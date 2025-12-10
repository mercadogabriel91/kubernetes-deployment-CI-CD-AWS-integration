#!/bin/bash
# deploy-local.sh - Deploy everything locally (minikube/kind + AWS infrastructure)
# Cost: ~$0.50-$1.00 for AWS resources (Kubernetes is FREE locally)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "🚀 Local Deployment Script"
echo "=========================="
echo ""
echo "This script will:"
echo "1. Check/start local Kubernetes (minikube or kind)"
echo "2. Deploy AWS infrastructure (S3, Parameter Store, ECR, IAM)"
echo "3. Build and push Docker images to ECR"
echo "4. Create Kubernetes secrets (ECR auth, AWS credentials)"
echo "5. Deploy Kubernetes manifests"
echo "6. Wait for pods to be ready"
echo "7. Run basic health checks"
echo ""
echo "Cost estimate: ~$0.50-$1.00 per hour (AWS resources only, Kubernetes is FREE)"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Error: terraform is not installed${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}Error: kubectl is not installed${NC}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Error: docker is not installed${NC}"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}Error: aws cli is not installed${NC}"; exit 1; }

# Check/prompt for AWS profile
# DEFAULT: Use gabe-personal profile to avoid deploying to work account
if [ -z "$AWS_PROFILE" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "${YELLOW}AWS_PROFILE or AWS_ACCESS_KEY_ID not set${NC}"
    echo -e "${BLUE}💡 Defaulting to 'gabe-personal' profile to avoid work account${NC}"
    echo "Available AWS profiles:"
    aws configure list-profiles 2>/dev/null || grep -E '^\[profile ' ~/.aws/config 2>/dev/null | sed 's/\[profile \(.*\)\]/\1/' || echo "  (none found)"
    echo ""
    read -p "Enter AWS profile to use (or press Enter to use 'gabe-personal'): " AWS_PROFILE_INPUT
    if [ -n "$AWS_PROFILE_INPUT" ]; then
        export AWS_PROFILE="$AWS_PROFILE_INPUT"
    else
        export AWS_PROFILE="gabe-personal" # You can change this to your preferred profile i use this in my pc to prevent deploying to the wrong account
        echo -e "${GREEN}✅ Using AWS_PROFILE: gabe-personal${NC}"
        echo -e "${BLUE}Using AWS profile: $AWS_PROFILE${NC}"
    else
        echo -e "${YELLOW}Using default AWS profile${NC}"
    fi
    echo ""
fi

# Verify AWS credentials work
echo -e "${YELLOW}Verifying AWS credentials...${NC}"
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo -e "${RED}Error: Cannot authenticate with AWS${NC}"
    echo "Please check your AWS credentials:"
    echo "  - Set AWS_PROFILE environment variable"
    echo "  - Or run: aws configure"
    exit 1
fi

# Get AWS account info
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=${AWS_REGION:-us-east-1}
export ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Show which profile is being used
if [ -n "$AWS_PROFILE" ]; then
    echo -e "${BLUE}Using AWS profile: $AWS_PROFILE${NC}"
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"
echo "  AWS Account: $AWS_ACCOUNT_ID"
echo "  Region: $AWS_REGION"
echo ""

# Step 1: Check/start local Kubernetes
echo -e "${YELLOW}Step 1: Checking local Kubernetes cluster...${NC}"
K8S_TYPE=""
if command -v minikube >/dev/null 2>&1; then
    if minikube status >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Minikube is running${NC}"
        K8S_TYPE="minikube"
        eval $(minikube docker-env) 2>/dev/null || true
    else
        echo -e "${YELLOW}Minikube not running, starting...${NC}"
        minikube start
        K8S_TYPE="minikube"
        eval $(minikube docker-env)
    fi
elif command -v kind >/dev/null 2>&1; then
    if kind get clusters 2>/dev/null | grep -q "k-challenge"; then
        echo -e "${GREEN}✓ Kind cluster 'k-challenge' exists${NC}"
        K8S_TYPE="kind"
    else
        echo -e "${YELLOW}Kind cluster not found, creating...${NC}"
        kind create cluster --name k-challenge
        K8S_TYPE="kind"
    fi
else
    echo -e "${RED}Error: Neither minikube nor kind is installed${NC}"
    echo "Please install one of them:"
    echo "  brew install minikube"
    echo "  brew install kind"
    exit 1
fi

# Verify kubectl can connect
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Kubernetes cluster ready (${K8S_TYPE})${NC}"
echo ""

# Step 2: Deploy Terraform infrastructure
echo -e "${YELLOW}Step 2: Deploying AWS infrastructure...${NC}"
cd terraform
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}Warning: terraform.tfvars not found${NC}"
    echo "Creating terraform.tfvars from example..."
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        echo -e "${YELLOW}Please edit terraform.tfvars with your values, then re-run this script${NC}"
        exit 1
    fi
fi

terraform init
terraform apply -auto-approve
echo -e "${GREEN}✓ AWS infrastructure deployed${NC}"
echo ""

# Step 3: Authenticate with ECR
echo -e "${YELLOW}Step 3: Authenticating with ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY
echo -e "${GREEN}✓ ECR authenticated${NC}"
echo ""

# Step 4: Build and push images
echo -e "${YELLOW}Step 4: Building and pushing Docker images...${NC}"
cd "$PROJECT_ROOT/services/auxiliary-service"
docker build -t $ECR_REGISTRY/k-challenge-dev-auxiliary-service:latest .
docker push $ECR_REGISTRY/k-challenge-dev-auxiliary-service:latest
echo -e "${GREEN}✓ Auxiliary service image pushed${NC}"

cd "$PROJECT_ROOT/services/main-api"
docker build -t $ECR_REGISTRY/k-challenge-dev-main-api:latest .
docker push $ECR_REGISTRY/k-challenge-dev-main-api:latest
echo -e "${GREEN}✓ Main API image pushed${NC}"
echo ""

# Step 5: Create ECR registry secret
echo -e "${YELLOW}Step 5: Creating ECR registry secret...${NC}"
export ECR_TOKEN=$(aws ecr get-login-password --region $AWS_REGION)
kubectl create namespace k-challenge-namespace --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=$ECR_REGISTRY \
  --docker-username=AWS \
  --docker-password=$ECR_TOKEN \
  --namespace=k-challenge-namespace \
  --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ ECR secret created${NC}"
echo ""

# Step 6: Create AWS credentials secret (for local Kubernetes)
echo -e "${YELLOW}Step 6: Creating AWS credentials secret...${NC}"
if kubectl get secret aws-credentials -n k-challenge-namespace >/dev/null 2>&1; then
    echo -e "${BLUE}AWS credentials secret already exists, skipping...${NC}"
elif [ -f "$PROJECT_ROOT/kubernetes/base/shared/aws-credentials-secret.yaml" ]; then
    echo -e "${BLUE}Using existing AWS credentials secret file${NC}"
    kubectl apply -f "$PROJECT_ROOT/kubernetes/base/shared/aws-credentials-secret.yaml"
    echo -e "${GREEN}✓ AWS credentials secret created from file${NC}"
else
    echo -e "${YELLOW}Creating AWS credentials secret...${NC}"
    echo "For local Kubernetes, pods need AWS credentials to access S3 and Parameter Store."
    echo ""
    
    # Try to get from environment variables first
    if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
        echo -e "${BLUE}Using AWS credentials from environment variables${NC}"
        AWS_ACCESS_KEY="$AWS_ACCESS_KEY_ID"
        AWS_SECRET_KEY="$AWS_SECRET_ACCESS_KEY"
    # Try to extract from AWS profile
    elif [ -n "$AWS_PROFILE" ]; then
        echo -e "${BLUE}Extracting credentials from AWS profile: $AWS_PROFILE${NC}"
        AWS_ACCESS_KEY=$(aws configure get aws_access_key_id --profile "$AWS_PROFILE" 2>/dev/null)
        AWS_SECRET_KEY=$(aws configure get aws_secret_access_key --profile "$AWS_PROFILE" 2>/dev/null)
        
        if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ]; then
            echo -e "${YELLOW}Could not extract credentials from profile. Trying default profile...${NC}"
            AWS_ACCESS_KEY=$(aws configure get aws_access_key_id 2>/dev/null)
            AWS_SECRET_KEY=$(aws configure get aws_secret_access_key 2>/dev/null)
        fi
        
        if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ]; then
            echo -e "${RED}Error: Could not extract credentials from AWS profile${NC}"
            echo "Please provide AWS credentials manually:"
            read -p "AWS Access Key ID: " AWS_ACCESS_KEY
            read -sp "AWS Secret Access Key: " AWS_SECRET_KEY
            echo ""
        else
            echo -e "${GREEN}✓ Successfully extracted credentials from AWS profile${NC}"
        fi
    # Try default profile
    else
        echo -e "${BLUE}Extracting credentials from default AWS profile...${NC}"
        AWS_ACCESS_KEY=$(aws configure get aws_access_key_id 2>/dev/null)
        AWS_SECRET_KEY=$(aws configure get aws_secret_access_key 2>/dev/null)
        
        if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ]; then
            echo -e "${YELLOW}Could not extract credentials from default profile${NC}"
            echo "Please provide AWS credentials manually:"
            read -p "AWS Access Key ID: " AWS_ACCESS_KEY
            read -sp "AWS Secret Access Key: " AWS_SECRET_KEY
            echo ""
        else
            echo -e "${GREEN}✓ Successfully extracted credentials from default AWS profile${NC}"
        fi
    fi
    
    AWS_ACCESS_KEY_B64=$(echo -n "$AWS_ACCESS_KEY" | base64)
    AWS_SECRET_KEY_B64=$(echo -n "$AWS_SECRET_KEY" | base64)
    
    cat > /tmp/aws-credentials-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: k-challenge-namespace
type: Opaque
data:
  AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_B64}
  AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_KEY_B64}
EOF
    
    kubectl apply -f /tmp/aws-credentials-secret.yaml
    rm /tmp/aws-credentials-secret.yaml
    echo -e "${GREEN}✓ AWS credentials secret created${NC}"
    echo -e "${YELLOW}Note: Consider saving this to kubernetes/base/shared/aws-credentials-secret.yaml for future use${NC}"
fi
echo ""

# Step 7: Deploy Kubernetes manifests
echo -e "${YELLOW}Step 7: Deploying Kubernetes manifests...${NC}"
cd "$PROJECT_ROOT/kubernetes"

# Update kustomization.yaml from Parameter Store (replaces ${AWS_ACCOUNT_ID} and ${AWS_REGION})
echo -e "${BLUE}Updating kustomization.yaml from Parameter Store...${NC}"
if [ -f "$PROJECT_ROOT/scripts/update-kustomization-from-parameter-store.sh" ]; then
    "$PROJECT_ROOT/scripts/update-kustomization-from-parameter-store.sh" || {
        echo -e "${YELLOW}⚠️  Failed to update from Parameter Store, trying fallback...${NC}"
        # Fallback: Replace placeholders directly if Parameter Store update fails
        if grep -q '\${AWS_ACCOUNT_ID}\|\${AWS_REGION}' overlays/dev/kustomization.yaml; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|\${AWS_ACCOUNT_ID}|$AWS_ACCOUNT_ID|g" overlays/dev/kustomization.yaml
                sed -i '' "s|\${AWS_REGION}|$AWS_REGION|g" overlays/dev/kustomization.yaml
            else
                sed -i "s|\${AWS_ACCOUNT_ID}|$AWS_ACCOUNT_ID|g" overlays/dev/kustomization.yaml
                sed -i "s|\${AWS_REGION}|$AWS_REGION|g" overlays/dev/kustomization.yaml
            fi
        fi
    }
else
    echo -e "${YELLOW}⚠️  Update script not found, using fallback method...${NC}"
    # Fallback: Replace placeholders directly
    if grep -q '\${AWS_ACCOUNT_ID}\|\${AWS_REGION}' overlays/dev/kustomization.yaml; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|\${AWS_ACCOUNT_ID}|$AWS_ACCOUNT_ID|g" overlays/dev/kustomization.yaml
            sed -i '' "s|\${AWS_REGION}|$AWS_REGION|g" overlays/dev/kustomization.yaml
        else
            sed -i "s|\${AWS_ACCOUNT_ID}|$AWS_ACCOUNT_ID|g" overlays/dev/kustomization.yaml
            sed -i "s|\${AWS_REGION}|$AWS_REGION|g" overlays/dev/kustomization.yaml
        fi
    fi
fi

kubectl apply -k overlays/dev
echo -e "${GREEN}✓ Kubernetes manifests applied${NC}"
echo ""

# Step 8: Wait for pods
echo -e "${YELLOW}Step 8: Waiting for pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=auxiliary-service -n k-challenge-namespace --timeout=5m || true
kubectl wait --for=condition=ready pod -l app=main-api -n k-challenge-namespace --timeout=5m || true
echo -e "${GREEN}✓ Pods are ready${NC}"
echo ""

# Step 9: Show status
echo -e "${YELLOW}Step 9: Deployment status...${NC}"
kubectl get pods -n k-challenge-namespace
kubectl get svc -n k-challenge-namespace
echo ""

# Step 10: Health checks
echo -e "${YELLOW}Step 10: Running health checks...${NC}"
echo "Setting up port-forwarding..."
kubectl port-forward -n k-challenge-namespace svc/main-api 3000:3000 > /dev/null 2>&1 &
PF_MAIN_PID=$!
kubectl port-forward -n k-challenge-namespace svc/auxiliary-service 3001:3001 > /dev/null 2>&1 &
PF_AUX_PID=$!
sleep 5

echo "Testing endpoints..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo -e "${GREEN}✓ Main API health check passed${NC}"
else
    echo -e "${RED}✗ Main API health check failed${NC}"
fi

if curl -s http://localhost:3001/health > /dev/null; then
    echo -e "${GREEN}✓ Auxiliary Service health check passed${NC}"
else
    echo -e "${RED}✗ Auxiliary Service health check failed${NC}"
fi

# Kill port-forward processes
kill $PF_MAIN_PID 2>/dev/null || true
kill $PF_AUX_PID 2>/dev/null || true
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Resources are now running:"
echo "  - Local Kubernetes: ${K8S_TYPE} (FREE)"
echo "  - AWS Infrastructure: S3, Parameter Store, ECR, IAM"
echo ""
echo "You can:"
echo "  - Test endpoints: kubectl port-forward -n k-challenge-namespace svc/main-api 3000:3000"
echo "  - View logs: kubectl logs -n k-challenge-namespace -l app=main-api"
echo "  - Check status: kubectl get pods -n k-challenge-namespace"
echo ""
echo -e "${YELLOW}⚠️  To cleanup, run:${NC}"
echo "  ./scripts/cleanup-local.sh"
echo ""
echo "Cost so far: ~$0.50-$1.00 (AWS resources only)"
echo ""

