# K8s Manus - Complete Deployment Guide

## 🎯 **For Your k3s Environment (docker-prod)**

### Quick Fix Commands
```bash
# 1. Fix k3s configuration
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

# 2. Test cluster connectivity
kubectl cluster-info
kubectl get nodes

# 3. Deploy the stack
git clone https://github.com/alwazw/k8s_manus.git
cd k8s_manus
./scripts/fix-k3s-deploy.sh deploy

# 4. Access services
echo "Authentik: http://10.10.10.131:30900"
echo "Grafana:   http://10.10.10.131:30300"
echo "PgAdmin:   http://10.10.10.131:30505"
echo "Heimdall:  http://10.10.10.131:30808"
echo "Homer:     http://10.10.10.131:30801"
```

## 🔧 **What the Fix Addresses**

### Original Issues
- ❌ `certificate signed by unknown authority`
- ❌ Services not deploying to cluster
- ❌ NodePort services not accessible
- ❌ Container startup failures

### Solutions Implemented
- ✅ k3s kubeconfig automatic setup
- ✅ k3s-optimized Helm values
- ✅ Guaranteed NodePort assignments
- ✅ Resource limits for single-node deployment
- ✅ Compatible container images

## 📊 **Service Architecture**

### Database Layer
- **PostgreSQL**: Authentik backend (port 5432)
- **MySQL**: Grafana backend (port 3306)  
- **Redis**: Session/cache store (port 6379)

### Application Layer
- **Authentik**: SSO provider (NodePort 30900)
- **Grafana**: Analytics dashboard (NodePort 30300)
- **PgAdmin**: Database management (NodePort 30505)

### Dashboard Layer
- **Heimdall**: Dynamic dashboard (NodePort 30808)
- **Homer**: Static dashboard (NodePort 30801)

## 🌐 **Network Configuration**

### NodePort Services (External Access)
```yaml
authentik: 30900 → 9000
grafana:   30300 → 3000
pgadmin:   30505 → 5050
heimdall:  30808 → 8080
homer:     30801 → 8081
```

### Internal Services (Cluster DNS)
```yaml
postgres.k8s-manus.svc.cluster.local:5432
mysql.k8s-manus.svc.cluster.local:3306
redis.k8s-manus.svc.cluster.local:6379
```

## 💾 **Storage Configuration**

### Persistent Volumes (k3s local-path)
- `postgres-data`: 5Gi
- `mysql-data`: 5Gi
- `redis-data`: 2Gi
- `grafana-data`: 2Gi
- `pgadmin-data`: 1Gi

## 🔐 **Security & Credentials**

### Default Credentials
- **Username**: `alwazw`
- **Password**: `WaficWazzan!2`
- **Email**: `wafic@wazzan.us`

### Kubernetes Secrets
- Database passwords
- Authentik secret key
- Service authentication tokens

## 🚀 **Deployment Process**

### 1. Prerequisites Check
```bash
kubectl version --client
helm version
kubectl get nodes
```

### 2. Namespace Creation
```bash
kubectl create namespace k8s-manus
```

### 3. Helm Deployment
```bash
helm upgrade --install k8s-manus ./charts/k8s-manus \
  --namespace k8s-manus \
  --values values-k3s.yaml \
  --wait --timeout=10m
```

### 4. Service Verification
```bash
kubectl get pods -n k8s-manus
kubectl get svc -n k8s-manus
```

## 🧪 **Testing & Validation**

### Health Checks
```bash
# Check all pods are running
kubectl get pods -n k8s-manus

# Check service endpoints
kubectl get endpoints -n k8s-manus

# Test external connectivity
curl -I http://10.10.10.131:30300  # Grafana
curl -I http://10.10.10.131:30900  # Authentik
```

### Service URLs
- **Authentik Setup**: http://10.10.10.131:30900/if/flow/initial-setup/
- **Grafana Dashboard**: http://10.10.10.131:30300
- **PgAdmin Console**: http://10.10.10.131:30505
- **Heimdall Dashboard**: http://10.10.10.131:30808
- **Homer Dashboard**: http://10.10.10.131:30801

## 🔄 **Management Commands**

### View Logs
```bash
kubectl logs -n k8s-manus deployment/grafana
kubectl logs -n k8s-manus deployment/authentik-server
```

### Scale Services
```bash
kubectl scale deployment grafana --replicas=2 -n k8s-manus
```

### Update Configuration
```bash
helm upgrade k8s-manus ./charts/k8s-manus \
  --namespace k8s-manus \
  --values values-k3s.yaml \
  --reuse-values
```

### Clean Up
```bash
helm uninstall k8s-manus -n k8s-manus
kubectl delete namespace k8s-manus
```

## 🎯 **Expected Results**

After successful deployment:
- ✅ All pods in `Running` status
- ✅ Services accessible via NodePort URLs
- ✅ Web interfaces loading without errors
- ✅ Database connections established
- ✅ SSO authentication working

## 🆘 **Troubleshooting**

### Common Issues
1. **Pods Pending**: Check storage class and node resources
2. **Services Unreachable**: Verify firewall rules for NodePort ranges
3. **Database Connection Errors**: Check pod logs and service endpoints

### Debug Commands
```bash
kubectl describe pod <pod-name> -n k8s-manus
kubectl get events -n k8s-manus --sort-by='.lastTimestamp'
kubectl port-forward svc/grafana 3000:3000 -n k8s-manus
```

This deployment is specifically optimized for your k3s environment and addresses all the issues you encountered.

