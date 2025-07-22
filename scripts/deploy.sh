#!/bin/bash

# K8s Manus - Kubernetes Deployment Script
# Production-ready Kubernetes deployment with Helm

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CHART_DIR="$PROJECT_DIR/charts/k8s-manus"
NAMESPACE="k8s-manus"
RELEASE_NAME="k8s-manus"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if kubectl is installed and configured
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if Helm is installed
    if ! command -v helm &> /dev/null; then
        error "Helm is not installed. Please install Helm first."
        exit 1
    fi
    
    # Check if we can connect to Kubernetes cluster
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    # Check if chart directory exists
    if [[ ! -d "$CHART_DIR" ]]; then
        error "Helm chart directory not found at $CHART_DIR"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Validate Helm chart
validate_chart() {
    log "Validating Helm chart..."
    
    cd "$CHART_DIR"
    
    # Lint the chart
    if ! helm lint .; then
        error "Helm chart validation failed"
        exit 1
    fi
    
    # Template the chart to check for syntax errors
    if ! helm template "$RELEASE_NAME" . --namespace "$NAMESPACE" > /dev/null; then
        error "Helm chart templating failed"
        exit 1
    fi
    
    success "Helm chart validation passed"
}

# Create namespace if it doesn't exist
create_namespace() {
    log "Creating namespace if it doesn't exist..."
    
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        kubectl create namespace "$NAMESPACE"
        success "Namespace $NAMESPACE created"
    else
        success "Namespace $NAMESPACE already exists"
    fi
}

# Deploy with Helm
deploy_helm() {
    log "Deploying K8s Manus stack with Helm..."
    
    cd "$CHART_DIR"
    
    # Deploy or upgrade the release
    helm upgrade --install "$RELEASE_NAME" . \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --wait \
        --timeout 10m \
        --atomic
    
    success "Helm deployment completed"
}

# Check deployment status
check_deployment() {
    log "Checking deployment status..."
    
    # Wait for all deployments to be ready
    local deployments=(
        "postgres"
        "mysql" 
        "redis"
        "authentik-server"
        "authentik-worker"
        "grafana"
    )
    
    for deployment in "${deployments[@]}"; do
        log "Waiting for deployment $deployment to be ready..."
        if kubectl wait --for=condition=available deployment/"$deployment" \
            --namespace "$NAMESPACE" --timeout=300s; then
            success "$deployment is ready"
        else
            warning "$deployment may not be fully ready yet"
        fi
    done
}

# Display service information
display_services() {
    log "Getting service information..."
    
    echo ""
    echo "🎉 K8s Manus Stack Deployment Complete!"
    echo "========================================"
    echo ""
    
    # Get NodePort services
    echo "📋 Service Access (NodePort):"
    kubectl get services -n "$NAMESPACE" -o wide | grep NodePort || echo "No NodePort services found"
    
    echo ""
    echo "🔗 Service URLs (if using NodePort):"
    
    # Get node IP
    local node_ip
    node_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || \
              kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || \
              echo "localhost")
    
    echo "   🔐 Authentik SSO:    http://$node_ip:30900"
    echo "   📊 Grafana:          http://$node_ip:30300"
    echo "   🗄️  PgAdmin:          http://$node_ip:30505"
    echo "   🏠 Heimdall:         http://$node_ip:30808"
    echo "   🏠 Homer:            http://$node_ip:30801"
    
    echo ""
    echo "🔑 Default Credentials:"
    echo "   Username: alwazw"
    echo "   Password: WaficWazzan!2"
    echo "   Email:    wafic@wazzan.us"
    
    echo ""
    echo "⚙️  Initial Setup:"
    echo "   1. Access Authentik at http://$node_ip:30900/if/flow/initial-setup/"
    echo "   2. Set up the admin user with the credentials above"
    echo "   3. Configure SSO for other services"
    
    echo ""
    echo "📊 Pod Status:"
    kubectl get pods -n "$NAMESPACE"
}

# Cleanup function
cleanup() {
    log "Cleaning up previous deployment..."
    
    # Delete the Helm release if it exists
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE"
        success "Previous Helm release removed"
    fi
    
    # Optionally delete the namespace
    read -p "Do you want to delete the namespace $NAMESPACE? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
        success "Namespace $NAMESPACE deleted"
    fi
}

# Show logs
show_logs() {
    local service="${1:-}"
    
    if [[ -z "$service" ]]; then
        echo "Available services:"
        kubectl get deployments -n "$NAMESPACE" -o name | sed 's/deployment.apps\///'
        return
    fi
    
    kubectl logs -f deployment/"$service" -n "$NAMESPACE"
}

# Main function
main() {
    echo "🚀 K8s Manus - Kubernetes Deployment"
    echo "====================================="
    echo ""
    
    case "${1:-deploy}" in
        "deploy")
            check_prerequisites
            validate_chart
            create_namespace
            deploy_helm
            check_deployment
            display_services
            ;;
        "upgrade")
            check_prerequisites
            validate_chart
            deploy_helm
            check_deployment
            display_services
            ;;
        "status")
            kubectl get all -n "$NAMESPACE"
            ;;
        "logs")
            show_logs "${2:-}"
            ;;
        "cleanup")
            cleanup
            ;;
        "validate")
            check_prerequisites
            validate_chart
            success "Chart validation completed"
            ;;
        *)
            echo "Usage: $0 {deploy|upgrade|status|logs|cleanup|validate}"
            echo ""
            echo "Commands:"
            echo "  deploy    - Deploy the entire K8s Manus stack"
            echo "  upgrade   - Upgrade existing deployment"
            echo "  status    - Show deployment status"
            echo "  logs      - Show logs for a specific service"
            echo "  cleanup   - Remove the deployment"
            echo "  validate  - Validate Helm chart without deploying"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

