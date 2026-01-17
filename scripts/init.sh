#!/usr/bin/env bash

# Initialize Terraform environment for a specific environment
# Usage: ./scripts/init.sh dev|prod

set -e

if [ -z "$1" ]; then
    echo "Usage: ./scripts/init.sh <environment>"
    echo "Example: ./scripts/init.sh dev"
    exit 1
fi

ENV="$1"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Validate environment
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "❌ Invalid environment: $ENV"
    echo "Must be 'dev' or 'prod'"
    exit 1
fi

echo "🚀 Initializing Terraform for: $ENV"

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform >= 1.6"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI >= 2.0"
    exit 1
fi

# Verify AWS credentials
echo "📋 Verifying AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS credentials not configured"
    echo "Run: aws configure"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "sa-east-1")

echo "   Account: $ACCOUNT_ID"
echo "   Region:  $REGION"

# Initialize Bootstrap
echo ""
echo "🔧 Step 1: Initialize Bootstrap Stack..."
cd "${PROJECT_ROOT}/stacks/bootstrap"

terraform init

echo "   Formatting..."
terraform fmt

echo "   Validating..."
terraform validate

echo ""
echo "📋 Bootstrap variables:"
cat "${PROJECT_ROOT}/envs/${ENV}/bootstrap.tfvars"

echo ""
echo "Ready to plan/apply bootstrap:"
echo "  terraform plan -var-file=../../envs/${ENV}/bootstrap.tfvars"
echo "  terraform apply -var-file=../../envs/${ENV}/bootstrap.tfvars"

read -p "Apply bootstrap now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply -var-file="../../envs/${ENV}/bootstrap.tfvars"
    
    echo ""
    echo "✅ Bootstrap complete"
    echo ""
    echo "🔧 Step 2: Reconfigure Bootstrap with remote backend..."
    terraform init \
        -backend-config="../../envs/${ENV}/bootstrap.backend.hcl" \
        -reconfigure
    
    echo ""
    echo "🔧 Step 3: Initialize Network Stack..."
    cd "${PROJECT_ROOT}/stacks/network"
    
    terraform init \
        -backend-config="../../envs/${ENV}/network.backend.hcl"
    
    terraform fmt
    terraform validate
    
    echo ""
    echo "📋 Network variables:"
    cat "${PROJECT_ROOT}/envs/${ENV}/network.tfvars"
    
    echo ""
    echo "Ready to plan/apply network:"
    echo "  terraform plan -var-file=../../envs/${ENV}/network.tfvars"
    echo "  terraform apply -var-file=../../envs/${ENV}/network.tfvars"
    
    read -p "Apply network now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply -var-file="../../envs/${ENV}/network.tfvars"
        echo ""
        echo "✅ Network complete!"
        echo ""
        terraform output
    fi
fi

echo ""
echo "✨ Initialization complete for: $ENV"
