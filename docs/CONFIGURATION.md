# Configuration Guide

This guide covers the configuration options for K8s Manus stack.

## Configuration Files

### Main Configuration
- `charts/k8s-manus/values.yaml` - Default configuration
- `examples/values-production.yaml` - Production template
- `examples/values-development.yaml` - Development template

### Custom Configuration
Create your own values file:
```bash
cp examples/values-production.yaml my-values.yaml
# Edit my-values.yaml
helm install k8s-manus ./charts/k8s-manus -f my-values.yaml
```

## Global Settings

### Basic Configuration
```yaml
global:
  namespace: k8s-manus          # Kubernetes namespace
  domain: wazzan.us             # Base domain for services
  hostIP: 10.10.10.131         # Host IP for NodePort access
  storageClass: standard       # Storage class for PVCs
```

### Image Configuration
```yaml
images:
  postgres:
    repository: postgres
    tag: "15-alpine"
    pullPolicy: IfNotPresent
  # ... other images
```

## Authentication & Security

### Admin Credentials
```yaml
auth:
  adminUser: alwazw                    # Admin username
  adminPassword: WaficWazzan!2         # Admin password (change in production!)
  adminEmail: wafic@wazzan.us          # Admin email
```

### Authentik SSO
```yaml
authentik:
  enabled: true
  secretKey: "your-secret-key"         # CHANGE THIS IN PRODUCTION!
  port: 9000
  subdomain: authentik
  replicas: 1                          # Scale for HA
  worker:
    replicas: 1                        # Background workers
```

## Database Configuration

### PostgreSQL
```yaml
databases:
  postgres:
    enabled: true
    database: authentik
    username: authentik
    password: WaficWazzan!2            # Change in production!
    port: 5432
    storage: 10Gi                      # Adjust based on needs
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

### MySQL
```yaml
databases:
  mysql:
    enabled: true
    rootPassword: WaficWazzan!2        # Change in production!
    database: grafana
    username: grafana
    password: WaficWazzan!2            # Change in production!
    port: 3306
    storage: 10Gi
```

### Redis
```yaml
databases:
  redis:
    enabled: true
    password: WaficWazzan!2            # Change in production!
    port: 6379
    storage: 5Gi
```

## Application Services

### Grafana
```yaml
grafana:
  enabled: true
  port: 3000
  subdomain: grafana
  replicas: 1
  plugins:                             # Optional Grafana plugins
    - grafana-clock-panel
    - grafana-simple-json-datasource
  oauth:                               # SSO integration
    enabled: true
    clientId: grafana
    clientSecret: grafana-secret
```

### PgAdmin
```yaml
pgadmin:
  enabled: true
  port: 5050
  subdomain: pgadmin
  replicas: 1
```

### Dashboard Services
```yaml
dashboards:
  heimdall:
    enabled: true
    port: 8080
    subdomain: heimdall
    replicas: 1
    
  homer:
    enabled: true
    port: 8081
    subdomain: homer
    replicas: 1
```

## Networking Configuration

### Ingress (Recommended for Production)
```yaml
networking:
  ingress:
    enabled: true
    className: nginx                   # Ingress controller class
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
      nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    tls:
      enabled: false                   # Enable for HTTPS
      secretName: k8s-manus-tls
```

### NodePort (Good for Development)
```yaml
networking:
  nodePort:
    enabled: true                      # Enables NodePort services
```

### Load Balancer (Cloud Environments)
```yaml
networking:
  loadBalancer:
    enabled: false                     # Enable for cloud load balancers
```

## Storage Configuration

### Persistent Volumes
```yaml
storage:
  persistentVolumes:
    enabled: true
    storageClass: standard             # Use appropriate storage class
    accessMode: ReadWriteOnce          # Access mode for PVCs
```

### Storage Classes by Provider
- **AWS EKS**: `gp2`, `gp3`, `io1`
- **Google GKE**: `standard`, `ssd`
- **Azure AKS**: `default`, `managed-premium`
- **Local**: `standard`, `hostpath`

## Security Configuration

### RBAC
```yaml
security:
  rbac:
    enabled: true                      # Enable role-based access control
```

### Network Policies
```yaml
security:
  networkPolicies:
    enabled: true                      # Enable network segmentation
```

### Pod Security Standards
```yaml
security:
  podSecurityStandards:
    enabled: true                      # Enable pod security policies
```

## Resource Management

### CPU and Memory Limits
```yaml
# Example for Grafana
grafana:
  resources:
    requests:                          # Minimum guaranteed resources
      memory: "256Mi"
      cpu: "100m"
    limits:                            # Maximum allowed resources
      memory: "512Mi"
      cpu: "250m"
```

### Scaling Configuration
```yaml
# High Availability setup
authentik:
  replicas: 3                          # Multiple server instances
  worker:
    replicas: 2                        # Multiple worker instances

grafana:
  replicas: 2                          # Multiple Grafana instances
```

## Monitoring Configuration

### Prometheus Integration
```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true                      # Create ServiceMonitor for Prometheus
  prometheusRule:
    enabled: true                      # Create alerting rules
```

## Backup Configuration

### Automated Backups
```yaml
backup:
  enabled: false                       # Enable for production
  schedule: "0 2 * * *"               # Cron schedule (daily at 2 AM)
  retention: 7                         # Days to keep backups
```

## Environment-Specific Examples

### Development Environment
```yaml
# Minimal resources, no security, NodePort access
global:
  namespace: k8s-manus-dev

auth:
  adminPassword: admin123              # Simple password for dev

databases:
  postgres:
    storage: 2Gi                       # Smaller storage
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"

networking:
  ingress:
    enabled: false                     # No ingress needed
  nodePort:
    enabled: true                      # Easy local access

security:
  rbac:
    enabled: false                     # Simplified for dev
```

### Production Environment
```yaml
# High availability, security enabled, ingress with TLS
global:
  namespace: k8s-manus-prod
  storageClass: fast-ssd

auth:
  adminPassword: "SECURE-RANDOM-PASSWORD"

authentik:
  replicas: 3                          # High availability
  secretKey: "VERY-SECURE-SECRET-KEY"

databases:
  postgres:
    storage: 50Gi                      # Production storage
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"

networking:
  ingress:
    enabled: true
    tls:
      enabled: true                    # HTTPS enabled

security:
  rbac:
    enabled: true                      # Full security
  networkPolicies:
    enabled: true
```

## Advanced Configuration

### Custom Secrets
```yaml
# Use existing secrets instead of creating new ones
authentik:
  existingSecret: my-authentik-secret

databases:
  postgres:
    existingSecret: my-postgres-secret
```

### Custom ConfigMaps
```yaml
# Use existing ConfigMaps for application configuration
grafana:
  existingConfigMap: my-grafana-config
```

### Node Affinity
```yaml
# Pin services to specific nodes
grafana:
  nodeSelector:
    kubernetes.io/arch: amd64
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node-type
            operator: In
            values:
            - compute
```

## Validation

### Validate Configuration
```bash
# Lint the chart with your values
helm lint ./charts/k8s-manus -f my-values.yaml

# Template and check output
helm template k8s-manus ./charts/k8s-manus -f my-values.yaml > output.yaml
```

### Test Configuration
```bash
# Dry run deployment
helm install k8s-manus ./charts/k8s-manus -f my-values.yaml --dry-run

# Deploy with debug
helm install k8s-manus ./charts/k8s-manus -f my-values.yaml --debug
```

