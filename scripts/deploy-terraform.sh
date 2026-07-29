#!/bin/bash

# AUREUS Platform - Terraform Deployment Script
# Deploy infrastructure using Terraform

set -e

echo "🏛️ AUREUS Platform - Terraform Deployment"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    print_success "Terraform is installed: $(terraform version)"
}

# Check if required environment variables are set
check_environment() {
    print_status "Checking environment variables..."
    
    if [ -z "$AWS_ACCESS_KEY_ID" ]; then
        print_warning "AWS_ACCESS_KEY_ID not set. Using default profile."
    fi
    
    if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        print_warning "AWS_SECRET_ACCESS_KEY not set. Using default profile."
    fi
    
    if [ -z "$GCP_PROJECT_ID" ]; then
        print_warning "GCP_PROJECT_ID not set. Skipping GCP resources."
    fi
    
    if [ -z "$AZURE_CLIENT_ID" ]; then
        print_warning "AZURE_CLIENT_ID not set. Skipping Azure resources."
    fi
}

# Initialize Terraform (state local por padrao; para S3, crie backend "s3" em main.tf e use TF_STATE_BUCKET)
init_terraform() {
    print_status "Initializing Terraform..."
    cd infra/terraform

    terraform init -upgrade

    print_success "Terraform initialized successfully"
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    
    terraform plan \
        -var="environment=${ENVIRONMENT:-dev}" \
        -var="aws_region=${AWS_REGION:-us-east-1}" \
        -var="gcp_project_id=${GCP_PROJECT_ID:-}" \
        -var="azure_location=${AZURE_LOCATION:-East US}" \
        -var="db_password=${DB_PASSWORD:-aurix123}" \
        -out=aurix-platform.tfplan
    
    print_success "Terraform plan created successfully"
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    
    terraform apply aurix-platform.tfplan
    
    print_success "Terraform deployment completed successfully"
}

# Show Terraform outputs
show_outputs() {
    print_status "Terraform outputs:"
    terraform output
}

# Deploy to specific cloud provider
deploy_aws() {
    print_status "Deploying to AWS..."
    
    terraform apply \
        -target=module.aws_vpc \
        -target=module.aws_eks \
        -target=module.aws_rds \
        -target=module.aws_redis \
        -target=module.aws_alb \
        -target=module.aws_cloudfront \
        -target=module.aws_s3 \
        -target=module.aws_cloudwatch \
        -target=module.aws_iam \
        -target=module.aws_security \
        -var="environment=${ENVIRONMENT:-dev}" \
        -var="aws_region=${AWS_REGION:-us-east-1}" \
        -var="db_password=${DB_PASSWORD:-aurix123}" \
        -auto-approve
    
    print_success "AWS deployment completed"
}

deploy_azure() {
    print_status "Deploying to Azure..."
    
    terraform apply \
        -target=module.azure_resource_group \
        -target=module.azure_aks \
        -target=module.azure_postgresql \
        -target=module.azure_redis \
        -var="environment=${ENVIRONMENT:-dev}" \
        -var="azure_location=${AZURE_LOCATION:-East US}" \
        -var="db_password=${DB_PASSWORD:-aurix123}" \
        -auto-approve
    
    print_success "Azure deployment completed"
}

deploy_gcp() {
    print_status "Deploying to Google Cloud..."
    
    terraform apply \
        -target=module.gcp_vpc \
        -target=module.gcp_gke \
        -target=module.gcp_cloud_sql \
        -target=module.gcp_memorystore \
        -var="environment=${ENVIRONMENT:-dev}" \
        -var="gcp_project_id=${GCP_PROJECT_ID}" \
        -var="gcp_region=${GCP_REGION:-us-central1}" \
        -var="db_password=${DB_PASSWORD:-aurix123}" \
        -auto-approve
    
    print_success "Google Cloud deployment completed"
}

# Deploy Kubernetes manifests
deploy_kubernetes() {
    print_status "Deploying Kubernetes manifests..."
    
    # Get kubeconfig
    if [ "$CLOUD_PROVIDER" = "aws" ]; then
        aws eks update-kubeconfig --region ${AWS_REGION:-us-east-1} --name aurix-eks
    elif [ "$CLOUD_PROVIDER" = "azure" ]; then
        az aks get-credentials --resource-group aurix-platform-${ENVIRONMENT:-dev} --name aurix-aks
    elif [ "$CLOUD_PROVIDER" = "gcp" ]; then
        gcloud container clusters get-credentials aurix-gke --region ${GCP_REGION:-us-central1}
    fi
    
    # Apply Kubernetes manifests
    kubectl apply -f ../kubernetes/namespace.yaml
    kubectl apply -f ../kubernetes/aurix-core-deployment.yaml
    
    print_success "Kubernetes deployment completed"
}

# Build frontend (admin + web) with API URL apontamento
deploy_frontend_build() {
    print_status "Building frontend (aurix-admin + aurix-web)..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
    export FRONTEND_API_URL="${FRONTEND_API_URL:-$FRONTEND_API_URL}"
    if [ -n "$FRONTEND_API_URL" ]; then
        export FRONTEND_API_URL
        "$SCRIPT_DIR/build-frontend.sh"
    else
        print_warning "FRONTEND_API_URL not set; using http://localhost:8080 for build"
        export FRONTEND_API_URL="http://localhost:8080"
        "$SCRIPT_DIR/build-frontend.sh"
    fi
    print_success "Frontend build completed"
}

# Deploy frontend only (build + optional upload). Apontamento via FRONTEND_API_URL.
deploy_frontend_only() {
    print_status "Deploy frontend only (apontamento: ${FRONTEND_API_URL:-<not set>})..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    export FRONTEND_API_URL="${FRONTEND_API_URL:-http://localhost:8080}"
    export FRONTEND_UPLOAD="${FRONTEND_UPLOAD:-false}"
    export FRONTEND_S3_BUCKET_ADMIN="${FRONTEND_S3_BUCKET_ADMIN:-}"
    export FRONTEND_S3_BUCKET_WEB="${FRONTEND_S3_BUCKET_WEB:-}"
    "$SCRIPT_DIR/deploy-frontend.sh"
    print_success "Frontend deploy completed"
}

# Main deployment function
main() {
    echo "Starting AUREUS Platform deployment..."
    
    if [ "${DEPLOY_FRONTEND_ONLY:-false}" = "true" ]; then
        deploy_frontend_only
        print_success "Frontend-only deployment completed."
        return 0
    fi
    
    check_terraform
    check_environment
    init_terraform
    
    case "${CLOUD_PROVIDER:-all}" in
        "aws")
            deploy_aws
            ;;
        "azure")
            deploy_azure
            ;;
        "gcp")
            deploy_gcp
            ;;
        "all")
            plan_terraform
            apply_terraform
            ;;
        *)
            print_error "Invalid cloud provider: $CLOUD_PROVIDER"
            print_status "Valid options: aws, azure, gcp, all"
            exit 1
            ;;
    esac
    
    if [ "${DEPLOY_K8S:-false}" = "true" ]; then
        deploy_kubernetes
    fi
    
    if [ "${DEPLOY_FRONTEND:-false}" = "true" ]; then
        if [ "$CLOUD_PROVIDER" = "aws" ] && [ -n "${AWS_ALB_DNS:-}" ]; then
            export FRONTEND_API_URL="${FRONTEND_API_URL:-https://$AWS_ALB_DNS}"
        fi
        if [ "${FRONTEND_UPLOAD:-false}" = "true" ]; then
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            export FRONTEND_UPLOAD=true
            "$SCRIPT_DIR/deploy-frontend.sh"
        else
            deploy_frontend_build
        fi
    fi
    
    show_outputs
    print_success "AUREUS Platform deployment completed successfully!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --cloud-provider)
            CLOUD_PROVIDER="$2"
            shift 2
            ;;
        --deploy-k8s)
            DEPLOY_K8S="true"
            shift
            ;;
        --deploy-frontend)
            DEPLOY_FRONTEND="true"
            shift
            ;;
        --deploy-frontend-only)
            DEPLOY_FRONTEND_ONLY="true"
            shift
            ;;
        --frontend-api-url)
            FRONTEND_API_URL="$2"
            shift 2
            ;;
        --frontend-upload)
            FRONTEND_UPLOAD="true"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --environment ENV        Set environment (dev, staging, prod)"
            echo "  --cloud-provider CP      Set cloud provider (aws, azure, gcp, all)"
            echo "  --deploy-k8s             Deploy Kubernetes manifests"
            echo "  --deploy-frontend        Build and optionally upload frontend with backend (same cloud)"
            echo "  --deploy-frontend-only   Deploy only frontend; apontamento via --frontend-api-url or FRONTEND_API_URL"
            echo "  --frontend-api-url URL   API/gateway URL for frontend (admin + web). Use when same cloud or separate."
            echo "  --frontend-upload        After build, upload frontend to S3 (set FRONTEND_S3_BUCKET_* and AWS CLI)"
            echo "  --help                   Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main
