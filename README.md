# K8s Manus - Production Kubernetes Stack

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Helm Chart](https://img.shields.io/badge/Helm-Chart-blue.svg)](https://helm.sh/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-blue.svg)](https://kubernetes.io/)

A comprehensive, production-ready Kubernetes stack with SSO authentication, monitoring, and database management services, deployed using Helm charts.

## 🏗️ Architecture

This is a **true Kubernetes deployment** featuring:

- **🎯 Helm Charts**: Professional package management with templating
- **☸️ Kubernetes Native**: Deployments, Services, Ingress, PVCs, Secrets
- **🔒 Namespace Isolation**: Dedicated namespace for security and organization
- **💾 Persistent Storage**: StatefulSets with PersistentVolumeClaims
- **🌐 Service Discovery**: Internal DNS and service mesh ready
- **🚪 Ingress Controller**: External access with subdomain routing
- **⚙️ ConfigMaps & Secrets**: Secure configuration management
- **❤️ Health Checks**: Kubernetes-native liveness and readiness probes
- **📊 Resource Management**: CPU/Memory limits and requests
- **🛡️ RBAC**: Role-based access control

## 📦 Services Included

| Service | Description | Port | Subdomain |
|---------|-------------|------|-----------|
| **🔐 Authentik** | Enterprise SSO with OIDC/SAML | 9000 | authentik.wazzan.us |
| **📊 Grafana** | Analytics dashboards with SSO | 3000 | grafana.wazzan.us |
| **🗄️ PostgreSQL** | Primary database for Authentik | 5432 | - |
| **🗄️ MySQL** | Database for Grafana | 3306 | - |
| **🗄️ Redis** | Cache and session storage | 6379 | - |
| **🛠️ PgAdmin** | PostgreSQL administration | 5050 | pgadmin.wazzan.us |
| **🏠 Heimdall** | Dynamic application dashboard | 8080 | heimdall.wazzan.us |
| **🏠 Homer** | Static service dashboard | 8081 | homer.wazzan.us |

## 🚀 Quick Start

### Prerequisites
- **Kubernetes cluster** (v1.20+)
- **kubectl** configured and connected
- **Helm 3.0+** installed
- **4GB+ RAM** available in cluster
- **20GB+ storage** for persistent volumes

### Installation
```bash
# Clone repository
git clone https://github.com/alwazw/k8s_manus.git
cd k8s_manus

# Deploy with default settings
./scripts/deploy.sh deploy

# Check status
./scripts/deploy.sh status
```

### Access Services
```bash
# Get node IP
kubectl get nodes -o wide

# Access via NodePort (default)
# Authentik: http://node-ip:30900
# Grafana:   http://node-ip:30300
# PgAdmin:   http://node-ip:30505
```

## 📁 Project Structure

```
k8s-manus/
├── 📊 charts/k8s-manus/           # Main Helm chart
│   ├── Chart.yaml                 # Chart metadata
│   ├── values.yaml                # Default configuration
│   └── templates/                 # Kubernetes manifests
│       ├── namespace/             # Namespace creation
│       ├── storage/               # PVCs and Secrets
│       ├── databases/             # Database deployments
│       ├── authentication/       # Authentik SSO
│       ├── applications/          # Grafana, PgAdmin
│       ├── dashboards/           # Heimdall, Homer
│       └── networking/           # Ingress configuration
├── 📚 docs/                      # Documentation
│   ├── INSTALLATION.md           # Installation guide
│   └── CONFIGURATION.md          # Configuration guide
├── 📋 examples/                  # Example configurations
│   ├── values-production.yaml    # Production template
│   └── values-development.yaml   # Development template
├── 🔧 scripts/                   # Deployment scripts
│   └── deploy.sh                 # Main deployment script
├── 🧪 tests/                     # Testing scripts
│   └── test-chart.sh             # Chart validation
├── 🛠️ tools/                     # Additional tools
├── 📄 LICENSE                    # MIT License
└── 📖 README.md                  # This file
```

## 🎯 Quick Commands

### Deployment
```bash
# Deploy entire stack
./scripts/deploy.sh deploy

# Upgrade existing deployment
./scripts/deploy.sh upgrade

# Check deployment status
./scripts/deploy.sh status

# View logs for specific service
./scripts/deploy.sh logs grafana

# Clean up deployment
./scripts/deploy.sh cleanup
```

### Testing & Validation
```bash
# Run all chart tests
./tests/test-chart.sh all

# Validate Helm chart
./tests/test-chart.sh lint

# Test template generation
./tests/test-chart.sh template
```

### Helm Commands
```bash
# Install with custom values
helm install k8s-manus ./charts/k8s-manus \
  --namespace k8s-manus \
  --create-namespace \
  --values examples/values-production.yaml

# Upgrade deployment
helm upgrade k8s-manus ./charts/k8s-manus \
  --namespace k8s-manus \
  --reuse-values

# Check status
helm status k8s-manus -n k8s-manus
```

## 🔧 Configuration

### Environment-Specific Deployment

**Development**:
```bash
helm install k8s-manus ./charts/k8s-manus \
  --values examples/values-development.yaml \
  --namespace k8s-manus-dev --create-namespace
```

**Production**:
```bash
# Copy and customize production values
cp examples/values-production.yaml my-prod-values.yaml
# Edit my-prod-values.yaml with your settings

helm install k8s-manus ./charts/k8s-manus \
  --values my-prod-values.yaml \
  --namespace k8s-manus-prod --create-namespace
```

### Key Configuration Options

```yaml
# Global settings
global:
  namespace: k8s-manus
  domain: wazzan.us
  hostIP: 10.10.10.131

# Authentication
auth:
  adminUser: alwazw
  adminPassword: WaficWazzan!2  # Change in production!
  adminEmail: wafic@wazzan.us

# Networking
networking:
  ingress:
    enabled: true              # Enable for subdomain access
  nodePort:
    enabled: true              # Enable for direct port access
```

## 🌐 Service Access

### NodePort Access (Default)
| Service | URL | Credentials |
|---------|-----|-------------|
| Authentik | http://node-ip:30900 | alwazw / WaficWazzan!2 |
| Grafana | http://node-ip:30300 | alwazw / WaficWazzan!2 |
| PgAdmin | http://node-ip:30505 | wafic@wazzan.us / WaficWazzan!2 |
| Heimdall | http://node-ip:30808 | - |
| Homer | http://node-ip:30801 | - |

### Ingress Access (with Ingress Controller)
| Service | URL |
|---------|-----|
| Authentik | https://authentik.wazzan.us |
| Grafana | https://grafana.wazzan.us |
| PgAdmin | https://pgadmin.wazzan.us |
| Heimdall | https://heimdall.wazzan.us |
| Homer | https://homer.wazzan.us |

## 🔐 Initial Setup

### 1. Authentik Configuration
1. Access: http://node-ip:30900/if/flow/initial-setup/
2. Create admin user with provided credentials
3. Configure SSO providers for other services

### 2. Grafana SSO Integration
- Pre-configured for Authentik SSO
- Automatic role mapping based on groups
- MySQL backend for persistence

### 3. Database Access
**PostgreSQL** (via PgAdmin):
- Server: `postgres.k8s-manus.svc.cluster.local`
- Database: `authentik`
- Username: `authentik`
- Password: `WaficWazzan!2`

## 🛡️ Security Features

- **🔒 Namespace Isolation**: Services isolated in dedicated namespace
- **🛡️ RBAC**: Role-based access control (configurable)
- **🌐 Network Policies**: Traffic segmentation (configurable)
- **🔐 Pod Security Standards**: Security contexts and policies
- **🗝️ Secrets Management**: Encrypted secret storage
- **🔗 SSO Integration**: Centralized authentication via Authentik
- **🔒 TLS/SSL**: HTTPS support via Ingress (configurable)

## 📊 Monitoring & Observability

### Health Checks
```bash
# Check pod health
kubectl get pods -n k8s-manus

# View events
kubectl get events -n k8s-manus --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n k8s-manus
```

### Logging
```bash
# View logs for all services
kubectl logs -l app.kubernetes.io/instance=k8s-manus -n k8s-manus

# Follow specific service logs
kubectl logs -f deployment/grafana -n k8s-manus
```

## 🔧 Troubleshooting

### Common Issues

1. **Pods in Pending State**:
   ```bash
   kubectl describe pod <pod-name> -n k8s-manus
   # Check for resource constraints or storage issues
   ```

2. **Service Not Accessible**:
   ```bash
   kubectl get endpoints -n k8s-manus
   # Check if services have endpoints
   ```

3. **Storage Issues**:
   ```bash
   kubectl get pvc -n k8s-manus
   # Ensure storage class is available
   ```

### Debug Commands
```bash
# Get all resources
kubectl get all -n k8s-manus

# Describe problematic resources
kubectl describe deployment/grafana -n k8s-manus

# Check logs
kubectl logs deployment/authentik-server -n k8s-manus --previous
```

## 🚀 Production Deployment

### Prerequisites
1. **Ingress Controller** (NGINX recommended)
2. **Cert-Manager** (for TLS certificates)
3. **Storage Class** (fast SSD recommended)
4. **Load Balancer** (cloud environments)

### Production Checklist
- [ ] Change default passwords
- [ ] Configure custom domain
- [ ] Enable TLS/SSL certificates
- [ ] Set up monitoring and alerting
- [ ] Configure backup strategy
- [ ] Review resource limits
- [ ] Enable security policies

## 📚 Documentation

- **[Installation Guide](docs/INSTALLATION.md)** - Detailed installation instructions
- **[Configuration Guide](docs/CONFIGURATION.md)** - Complete configuration reference
- **[Examples](examples/)** - Production and development configurations

## 🧪 Testing

```bash
# Run all tests
./tests/test-chart.sh all

# Individual test categories
./tests/test-chart.sh lint      # Helm linting
./tests/test-chart.sh template  # Template generation
./tests/test-chart.sh examples  # Example configurations
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `./tests/test-chart.sh all`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **📖 Documentation**: Check the [docs/](docs/) directory
- **🐛 Issues**: Report bugs via [GitHub Issues](https://github.com/alwazw/k8s_manus/issues)
- **💬 Discussions**: Use [GitHub Discussions](https://github.com/alwazw/k8s_manus/discussions)

---

**🎯 Production-Ready**: This is a professional Kubernetes deployment using industry best practices with Helm charts, proper resource management, and comprehensive security considerations.

