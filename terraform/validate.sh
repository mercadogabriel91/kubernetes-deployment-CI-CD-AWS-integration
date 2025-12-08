#!/bin/bash

# Terraform validation script
# This script validates the Terraform configuration

set -e

echo "Validating Terraform configuration..."
echo "======================================"
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed"
    echo "Install it with: brew install terraform"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws configure list &> /dev/null; then
    echo "Warning: AWS credentials may not be configured"
    echo "Run: aws configure --profile gabe-personal"
fi

# Format Terraform files
echo "1. Formatting Terraform files..."
terraform fmt -recursive
echo "   [OK] Formatting complete"
echo ""

# Initialize Terraform (if not already initialized)
if [ ! -d ".terraform" ]; then
    echo "2. Initializing Terraform..."
    terraform init
    echo "   [OK] Initialization complete"
else
    echo "2. Terraform already initialized"
fi
echo ""

# Validate Terraform configuration
echo "3. Validating Terraform configuration..."
terraform validate
echo "   [OK] Validation complete"
echo ""

# Show plan (dry-run)
echo "4. Generating execution plan..."
terraform plan -out=tfplan
echo "   [OK] Plan generated"
echo ""

echo "======================================"
echo "Validation complete!"
echo ""
echo "Next steps:"
echo "  1. Review the plan above"
echo "  2. Apply with: terraform apply"
echo "  3. Or apply the saved plan: terraform apply tfplan"

