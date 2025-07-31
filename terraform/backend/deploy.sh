#!/bin/bash

# Configuration
PROJECT_NAME="terraform-backend"
ENVIRONMENT="dev"
STACK_NAME="${PROJECT_NAME}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check AWS CLI
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured"
        exit 1
    fi

    log_success "AWS CLI is configured"
}

# Deploy stack
deploy_stack() {
    log_info "Deploying Terraform Backend infrastructure..."
    
    aws cloudformation deploy \
        --stack-name "${STACK_NAME}" \
        --template-file backend.yaml \
        --parameter-overrides \
            ProjectName="${PROJECT_NAME}" \
            Environment="${ENVIRONMENT}" \
        --capabilities CAPABILITY_IAM \
        --tags \
            Project="${PROJECT_NAME}" \
            Environment="${ENVIRONMENT}" \
            ManagedBy="CloudFormation"

    if [ $? -eq 0 ]; then
        log_success "CloudFormation stack deployed successfully"
    else
        log_error "Failed to deploy CloudFormation stack"
        exit 1
    fi
}

# Get outputs and update providers.tf
get_outputs_and_update() {
    log_info "Retrieving stack outputs..."

    s3_bucket=$(aws cloudformation describe-stacks \
        --stack-name "${STACK_NAME}" \
        --output text \
        --query "Stacks[*].Outputs[?OutputKey=='S3Bucket'].OutputValue" 2>/dev/null | xargs)

    dynamodb_table=$(aws cloudformation describe-stacks \
        --stack-name "${STACK_NAME}" \
        --output text \
        --query "Stacks[*].Outputs[?OutputKey=='DynamoDBTable'].OutputValue" 2>/dev/null | xargs)

    kms_key=$(aws cloudformation describe-stacks \
        --stack-name "${STACK_NAME}" \
        --output text \
        --query "Stacks[*].Outputs[?OutputKey=='KMSKeyId'].OutputValue" 2>/dev/null | xargs)

    region=$(aws cloudformation describe-stacks \
        --stack-name "${STACK_NAME}" \
        --output text \
        --query "Stacks[*].Outputs[?OutputKey=='Region'].OutputValue" 2>/dev/null | xargs)

    if [ -z "$s3_bucket" ] || [ -z "$dynamodb_table" ]; then
        log_error "Failed to retrieve stack outputs"
        exit 1
    fi

    log_success "Stack outputs retrieved successfully"

    # Auto-update providers.tf if it exists
    if [ -f "../providers.tf" ]; then
        log_info "Updating ../providers.tf backend configuration..."
        
        # Create backup
        cp ../providers.tf ../providers.tf.backup
        
        # Update backend configuration using sed
        sed -i.tmp "s/bucket[[:space:]]*=[[:space:]]*\"[^\"]*\"/bucket         = \"${s3_bucket}\"/g" ../providers.tf
        sed -i.tmp "s/region[[:space:]]*=[[:space:]]*\"[^\"]*\"/region         = \"${region}\"/g" ../providers.tf
        sed -i.tmp "s/dynamodb_table[[:space:]]*=[[:space:]]*\"[^\"]*\"/dynamodb_table = \"${dynamodb_table}\"/g" ../providers.tf
        
        # Remove temp file
        rm -f ../providers.tf.tmp
        
        log_success "providers.tf updated automatically"
    fi
}

# Display summary
display_summary() {
    echo
    echo "=========================================="
    echo "🚀 TERRAFORM BACKEND DEPLOYMENT COMPLETE"
    echo "=========================================="
    echo
    log_info "📦 S3 Bucket: ${s3_bucket}"
    log_info "🔒 DynamoDB Table: ${dynamodb_table}"
    log_info "🔑 KMS Key: ${kms_key}"
    log_info "🌍 Region: ${region}"
    echo
    echo "🔧 Backend configuration in terraform/providers.tf:"
    echo "terraform {"
    echo "  backend \"s3\" {"
    echo "    bucket         = \"${s3_bucket}\""
    echo "    key            = \"infraiim\""
    echo "    region         = \"${region}\""
    echo "    dynamodb_table = \"${dynamodb_table}\""
    echo "    encrypt        = true"
    echo "  }"
    echo "}"
    echo
    log_warning "⚠️  Next steps:"
    echo "1. Add AWS credentials to GitHub Secrets"
    echo "2. Run 'terraform init' in the terraform directory"
    echo "3. Commit and push changes to deploy your application"
}

# Main execution
main() {
    echo "🔧 Terraform Backend Deployment Script"
    echo "======================================="
    echo

    check_aws_cli
    deploy_stack
    get_outputs_and_update
    display_summary
}

main "$@"