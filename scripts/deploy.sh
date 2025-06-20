#!/bin/bash

# Space Defender Game - Deployment Script
# This script helps deploy the game to different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
NAMESPACE="space-defender"
IMAGE_TAG="latest"
DOCKER_REGISTRY="ghcr.io"
REPO_NAME="space-defender-game"

# Functions
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment    Environment to deploy to (dev, staging, prod)"
    echo "  -n, --namespace      Kubernetes namespace"
    echo "  -t, --tag           Docker image tag"
    echo "  -r, --registry      Docker registry"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e staging -t v1.2.3"
    echo "  $0 --environment prod --namespace space-defender-prod"
}

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod."
fi

# Set namespace based on environment
if [[ "$ENVIRONMENT" == "staging" ]]; then
    NAMESPACE="space-defender-staging"
elif [[ "$ENVIRONMENT" == "prod" ]]; then
    NAMESPACE="space-defender-prod"
fi

log "Starting deployment to $ENVIRONMENT environment"
log "Namespace: $NAMESPACE"
log "Image Tag: $IMAGE_TAG"
log "Registry: $DOCKER_REGISTRY"

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
    fi
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        error "docker is not installed or not in PATH"
    fi
    
    # Check if we can connect to Kubernetes cluster
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
    fi
    
    success "Prerequisites check passed"
}

# Build Docker image
build_image() {
    log "Building Docker image..."
    
    FULL_IMAGE_NAME="${DOCKER_REGISTRY}/${REPO_NAME}:${IMAGE_TAG}"
    
    docker build -t "$FULL_IMAGE_NAME" .
    
    success "Docker image built: $FULL_IMAGE_NAME"
}

# Push Docker image
push_image() {
    log "Pushing Docker image to registry..."
    
    FULL_IMAGE_NAME="${DOCKER_REGISTRY}/${REPO_NAME}:${IMAGE_TAG}"
    
    docker push "$FULL_IMAGE_NAME"
    
    success "Docker image pushed: $FULL_IMAGE_NAME"
}

# Create namespace if it doesn't exist
create_namespace() {
    log "Creating namespace if it doesn't exist..."
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        warning "Namespace $NAMESPACE already exists"
    else
        kubectl create namespace "$NAMESPACE"
        success "Namespace $NAMESPACE created"
    fi
}

# Update Kubernetes manifests
update_manifests() {
    log "Updating Kubernetes manifests..."
    
    FULL_IMAGE_NAME="${DOCKER_REGISTRY}/${REPO_NAME}:${IMAGE_TAG}"
    
    # Create temporary directory for modified manifests
    TEMP_DIR=$(mktemp -d)
    cp -r k8s/* "$TEMP_DIR/"
    
    # Update image in deployment
    sed -i "s|image: space-defender-game:.*|image: $FULL_IMAGE_NAME|g" "$TEMP_DIR/deployment.yaml"
    
    # Update namespace in all manifests
    find "$TEMP_DIR" -name "*.yaml" -exec sed -i "s/namespace: space-defender$/namespace: $NAMESPACE/g" {} \;
    
    success "Manifests updated in $TEMP_DIR"
    echo "$TEMP_DIR"
}

# Deploy to Kubernetes
deploy_to_k8s() {
    local manifest_dir=$1
    
    log "Deploying to Kubernetes..."
    
    # Apply manifests
    kubectl apply -f "$manifest_dir/" -n "$NAMESPACE"
    
    # Wait for deployment to be ready
    log "Waiting for deployment to be ready..."
    kubectl rollout status deployment/space-defender-game -n "$NAMESPACE" --timeout=300s
    
    success "Deployment completed successfully"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check pods
    log "Checking pods..."
    kubectl get pods -n "$NAMESPACE" -l app=space-defender-game
    
    # Check services
    log "Checking services..."
    kubectl get services -n "$NAMESPACE"
    
    # Check if pods are ready
    READY_PODS=$(kubectl get pods -n "$NAMESPACE" -l app=space-defender-game -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -o "True" | wc -l)
    TOTAL_PODS=$(kubectl get pods -n "$NAMESPACE" -l app=space-defender-game --no-headers | wc -l)
    
    if [[ "$READY_PODS" -eq "$TOTAL_PODS" ]] && [[ "$TOTAL_PODS" -gt 0 ]]; then
        success "All $TOTAL_PODS pods are ready"
    else
        error "Only $READY_PODS out of $TOTAL_PODS pods are ready"
    fi
    
    # Get service URL
    if [[ "$ENVIRONMENT" == "dev" ]]; then
        log "To access the application locally, run:"
        echo "kubectl port-forward service/space-defender-game 8080:80 -n $NAMESPACE"
        echo "Then open http://localhost:8080"
    else
        EXTERNAL_IP=$(kubectl get service space-defender-game -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [[ -n "$EXTERNAL_IP" ]]; then
            success "Application is available at: http://$EXTERNAL_IP"
        else
            log "External IP is being assigned. Check with: kubectl get service space-defender-game -n $NAMESPACE"
        fi
    fi
}

# Cleanup function
cleanup() {
    if [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log "Cleaned up temporary directory"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Main deployment flow
main() {
    log "🚀 Space Defender Game Deployment Script"
    log "========================================"
    
    check_prerequisites
    build_image
    
    if [[ "$ENVIRONMENT" != "dev" ]]; then
        push_image
    fi
    
    create_namespace
    TEMP_DIR=$(update_manifests)
    deploy_to_k8s "$TEMP_DIR"
    verify_deployment
    
    success "🎉 Deployment to $ENVIRONMENT completed successfully!"
}

# Run main function
main
