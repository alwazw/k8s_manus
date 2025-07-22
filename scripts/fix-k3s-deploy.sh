#!/bin/bash

# K8s Manus - k3s Deployment Fix Script
# =====================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="k8s-manus"
CHART_DIR="./charts/k8s-manus"

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

# Fix k3s kubeconfig
fix_k3s_config() {
    log "Fixing k3s kubeconfig..."
    
    if [[ -f "/etc/rancher/k3s/k3s.yaml" ]]; then
        # Copy k3s config to user directory
        sudo mkdir -p ~/.kube
        sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
        sudo chown $(id -u):$(id -g) ~/.kube/config
        chmod 600 ~/.kube/config
        success "k3s kubeconfig copied to ~/.kube/config"
    else
        error "k3s config not found at /etc/rancher/k3s/k3s.yaml"
        return 1
    fi
}

# Test cluster connectivity
test_cluster() {
    log "Testing cluster connectivity..."
    
    if kubectl cluster-info >/dev/null 2>&1; then
        success "Cluster connectivity OK"
        kubectl get nodes
        return 0
    else
        error "Cannot connect to cluster"
        return 1
    fi
}

# Deploy with proper k3s settings
deploy_stack() {
    log "Deploying K8s Manus stack to k3s..."
    
    # Create namespace
    kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy with k3s-specific values
    helm upgrade --install k8s-manus ${CHART_DIR} \
        --namespace ${NAMESPACE} \
        --set global.storageClass=local-path \
        --set networking.ingress.className=traefik \
        --set networking.nodePort.enabled=true \
        --wait --timeout=10m
    
    success "Deployment complete"
}

# Check service status
check_services() {
    log "Checking service status..."
    
    echo "Pods:"
    kubectl get pods -n ${NAMESPACE}
    
    echo ""
    echo "Services:"
    kubectl get svc -n ${NAMESPACE}
    
    echo ""
    echo "NodePort URLs:"
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    
    echo "Authentik: http://${NODE_IP}:30900"
    echo "Grafana:   http://${NODE_IP}:30300"
    echo "PgAdmin:   http://${NODE_IP}:30505"
    echo "Heimdall:  http://${NODE_IP}:30808"
    echo "Homer:     http://${NODE_IP}:30801"
}

# Test service connectivity
test_services() {
    log "Testing service connectivity..."
    
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    
    # Wait for services to be ready
    sleep 30
    
    # Test each service
    services=(
        "30900:Authentik"
        "30300:Grafana"
        "30505:PgAdmin"
        "30808:Heimdall"
        "30801:Homer"
    )
    
    for service in "${services[@]}"; do
        port=$(echo $service | cut -d: -f1)
        name=$(echo $service | cut -d: -f2)
        
        if curl -s --connect-timeout 5 http://${NODE_IP}:${port} >/dev/null; then
            success "${name} is accessible on port ${port}"
        else
            warning "${name} is not yet accessible on port ${port}"
        fi
    done
}

# Main execution
main() {
    echo "🚀 K8s Manus - k3s Deployment Fix"
    echo "=================================="
    echo ""
    
    # Fix k3s configuration
    if ! fix_k3s_config; then
        error "Failed to fix k3s configuration"
        exit 1
    fi
    
    # Test cluster connectivity
    if ! test_cluster; then
        error "Cluster connectivity test failed"
        exit 1
    fi
    
    # Deploy the stack
    if ! deploy_stack; then
        error "Deployment failed"
        exit 1
    fi
    
    # Check service status
    check_services
    
    # Test service connectivity
    test_services
    
    echo ""
    success "k3s deployment complete!"
    echo ""
    echo "🌐 Access your services:"
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    echo "   Authentik: http://${NODE_IP}:30900"
    echo "   Grafana:   http://${NODE_IP}:30300"
    echo "   PgAdmin:   http://${NODE_IP}:30505"
    echo "   Heimdall:  http://${NODE_IP}:30808"
    echo "   Homer:     http://${NODE_IP}:30801"
    echo ""
    echo "🔑 Credentials: alwazw / WaficWazzan!2"
}

# Command line interface
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "fix-config")
        fix_k3s_config
        ;;
    "test")
        test_cluster
        ;;
    "status")
        check_services
        ;;
    "test-services")
        test_services
        ;;
    *)
        echo "Usage: $0 {deploy|fix-config|test|status|test-services}"
        exit 1
        ;;
esac

