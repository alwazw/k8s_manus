# K8s Manus - k3s Deployment Fix

## 🚨 **Issues Fixed**

This addresses the specific issues you encountered:

1. **✅ TLS Certificate Error**: Fixed k3s kubeconfig setup
2. **✅ Service Deployment Failures**: Corrected Helm values for k3s
3. **✅ NodePort Access Issues**: Proper port configuration
4. **✅ Container Startup Problems**: Fixed image references and resource limits

## 🔧 **Quick Fix for Your Environment**

### Step 1: Fix k3s Configuration
```bash
# Fix the TLS certificate issue
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

# Test connectivity
kubectl cluster-info
kubectl get nodes
```

### Step 2: Deploy with k3s-Specific Values
```bash
# Clone the fixed version
git clone https://github.com/alwazw/k8s_manus.git k8s-manus-fixed
cd k8s-manus-fixed

# Deploy with k3s optimizations
./scripts/fix-k3s-deploy.sh deploy
```

### Step 3: Access Services
```bash
# Get your node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Access services via NodePort
echo "Authentik: http://${NODE_IP}:30900"
echo "Grafana:   http://${NODE_IP}:30300"
echo "PgAdmin:   http://${NODE_IP}:30505"
echo "Heimdall:  http://${NODE_IP}:30808"
echo "Homer:     http://${NODE_IP}:30801"
```

## 🎯 **What's Different**

### k3s-Specific Optimizations
- **Storage Class**: Uses `local-path` (k3s default)
- **Ingress Controller**: Configured for Traefik (k3s default)
- **Resource Limits**: Optimized for single-node deployment
- **Image Pull Policy**: Configured for better caching

### Fixed Service Configurations
- **MySQL**: Compatible image tag and proper resource allocation
- **Redis**: Correct authentication setup
- **Authentik**: Proper worker configuration
- **All Services**: Health checks and startup probes

### Network Configuration
- **NodePort**: Guaranteed port assignments (30900, 30300, etc.)
- **Ingress**: Traefik-specific annotations
- **Service Discovery**: Proper internal DNS resolution

## 📋 **Deployment Script Features**

The `fix-k3s-deploy.sh` script:
- ✅ Automatically fixes k3s kubeconfig
- ✅ Tests cluster connectivity
- ✅ Deploys with k3s-optimized values
- ✅ Waits for services to be ready
- ✅ Tests service accessibility
- ✅ Provides direct access URLs

## 🔍 **Troubleshooting Commands**

```bash
# Check pod status
kubectl get pods -n k8s-manus

# Check service endpoints
kubectl get svc -n k8s-manus

# View pod logs
kubectl logs -n k8s-manus deployment/grafana

# Test service connectivity
curl -I http://10.10.10.131:30300  # Grafana
curl -I http://10.10.10.131:30900  # Authentik
```

## 🚀 **Expected Results**

After deployment, you should see:
- ✅ All pods in `Running` status
- ✅ Services accessible via NodePort URLs
- ✅ Web interfaces loading properly
- ✅ No TLS certificate errors

## 🔑 **Default Credentials**
- **Username**: `alwazw`
- **Password**: `WaficWazzan!2`
- **Email**: `wafic@wazzan.us`

## 📊 **Service URLs (Your Environment)**
Based on your node IP `10.10.10.131`:
- **Authentik**: http://10.10.10.131:30900
- **Grafana**: http://10.10.10.131:30300
- **PgAdmin**: http://10.10.10.131:30505
- **Heimdall**: http://10.10.10.131:30808
- **Homer**: http://10.10.10.131:30801

## ⚡ **One-Command Deployment**
```bash
curl -sSL https://raw.githubusercontent.com/alwazw/k8s_manus/main/scripts/fix-k3s-deploy.sh | bash
```

This fix specifically addresses your k3s environment and ensures all services deploy and run correctly.

