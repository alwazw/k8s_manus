# Installation Guide

This guide covers the installation of K8s Manus stack on various Kubernetes environments.

## Prerequisites

### Required Software
- **Kubernetes cluster** (v1.20+)
- **kubectl** configured and connected to your cluster
- **Helm 3.0+** installed
- **4GB+ RAM** available in cluster
- **20GB+ storage** for persistent volumes

### Supported Kubernetes Distributions
- **Local Development**: minikube, kind, k3s, Docker Desktop
- **Cloud Providers**: EKS (AWS), GKE (Google Cloud), AKS (Azure)
- **On-Premise**: kubeadm, Rancher, OpenShift, VMware Tanzu

## Quick Installation

### 1. Clone Repository
```bash
git clone https://github.com/alwazw/k8s_manus.git
cd k8s_manus
```

### 2. Deploy with Default Settings
```bash
./scripts/deploy.sh deploy
```

### 3. Access Services
```bash
# Get node IP
kubectl get nodes -o wide

# Access services via NodePort
# Authentik: http://node-ip:30900
# Grafana: http://node-ip:30300
# PgAdmin: http://node-ip:30505
```

## Environment-Specific Installation

### Local Development (minikube)

1. **Start minikube**:
   ```bash
   minikube start --memory=4096 --cpus=2
   ```

2. **Deploy with development values**:
   ```bash
   helm install k8s-manus ./charts/k8s-manus \
     --namespace k8s-manus \
     --create-namespace \
     --values examples/values-development.yaml
   ```

3. **Access services**:
   ```bash
   minikube service list -n k8s-manus
   ```

### Production Cloud Deployment

1. **Prepare production values**:
   ```bash
   cp examples/values-production.yaml values-prod.yaml
   # Edit values-prod.yaml with your configuration
   ```

2. **Install Ingress Controller** (if not already installed):
   ```bash
   helm upgrade --install ingress-nginx ingress-nginx \
     --repo https://kubernetes.github.io/ingress-nginx \
     --namespace ingress-nginx --create-namespace
   ```

3. **Install cert-manager** (for TLS):
   ```bash
   helm install cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --create-namespace \
     --set installCRDs=true
   ```

4. **Deploy K8s Manus**:
   ```bash
   helm install k8s-manus ./charts/k8s-manus \
     --namespace k8s-manus \
     --create-namespace \
     --values values-prod.yaml
   ```

## Configuration

### Storage Classes

Check available storage classes:
```bash
kubectl get storageclass
```

Update `global.storageClass` in values.yaml:
```yaml
global:
  storageClass: fast-ssd  # or gp2, standard, etc.
```

### Domain Configuration

For production with custom domain:
```yaml
global:
  domain: your-domain.com

networking:
  ingress:
    enabled: true
    tls:
      enabled: true
```

### Resource Sizing

Adjust resources based on your cluster capacity:
```yaml
databases:
  postgres:
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "500m"
```

## Verification

### Check Deployment Status
```bash
# Check all pods
kubectl get pods -n k8s-manus

# Check services
kubectl get services -n k8s-manus

# Check persistent volumes
kubectl get pv,pvc -n k8s-manus
```

### Test Connectivity
```bash
# Port forward for testing
kubectl port-forward svc/grafana 3000:3000 -n k8s-manus

# Test in browser: http://localhost:3000
```

### View Logs
```bash
# Check specific service logs
kubectl logs deployment/grafana -n k8s-manus

# Follow logs
kubectl logs -f deployment/authentik-server -n k8s-manus
```

## Troubleshooting

### Common Issues

1. **Pods in Pending State**:
   ```bash
   kubectl describe pod <pod-name> -n k8s-manus
   # Check for resource constraints or storage issues
   ```

2. **Storage Issues**:
   ```bash
   kubectl get pvc -n k8s-manus
   # Ensure storage class is available and has capacity
   ```

3. **Network Issues**:
   ```bash
   kubectl get endpoints -n k8s-manus
   # Check if services have endpoints
   ```

### Debug Commands
```bash
# Get all events
kubectl get events -n k8s-manus --sort-by='.lastTimestamp'

# Describe problematic resources
kubectl describe deployment/grafana -n k8s-manus

# Check resource usage
kubectl top pods -n k8s-manus
```

## Uninstallation

### Remove Helm Release
```bash
helm uninstall k8s-manus -n k8s-manus
```

### Remove Namespace (optional)
```bash
kubectl delete namespace k8s-manus
```

### Remove Persistent Volumes (if needed)
```bash
kubectl get pv | grep k8s-manus
kubectl delete pv <pv-name>
```

