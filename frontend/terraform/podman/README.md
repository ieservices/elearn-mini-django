# ieServices E-Learning Platform - Frontend Podman Kubernetes Deployment

This directory contains Terraform configurations for deploying the React frontend to a local Podman Kubernetes cluster.

## Architecture

The infrastructure includes:

- **React Application**: Containerized SPA served by Nginx
- **Nginx Configuration**: Custom config for SPA routing and caching
- **ConfigMaps**: Nginx configuration and environment variables
- **Service**: NodePort for external access
- **Resource Limits**: CPU and memory constraints
- **Health Checks**: Liveness and readiness probes
- **Horizontal Pod Autoscaler** (optional): Auto-scaling based on CPU/memory

## Prerequisites

1. **Podman Kubernetes cluster running** (see backend README for setup)
2. **Backend deployed** (namespace should exist)
3. **kubectl** configured with podman context
4. **Terraform** installed

## Building the Frontend Image

### Option 1: Multi-stage Docker Build with Nginx

Create `Dockerfile` in the frontend directory:

```dockerfile
# ieServices E-Learning Platform - Frontend Dockerfile

# Build stage
FROM docker.io/library/node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the application
ARG REACT_APP_API_URL=http://localhost:30800
ENV REACT_APP_API_URL=$REACT_APP_API_URL
RUN npm run build

# Production stage
FROM docker.io/library/nginx:alpine

# Copy custom nginx config
COPY --from=builder /app/build /usr/share/nginx/html

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### Build the Image

```bash
cd frontend

# Build with default backend URL
podman build -t localhost/ieservices-elearn-frontend:latest .

# Or build with specific backend URL
podman build \
  --build-arg REACT_APP_API_URL=http://localhost:30800 \
  -t localhost/ieservices-elearn-frontend:latest .
```

### Verify Image

```bash
podman images | grep ieservices-elearn-frontend
```

## Setup

### Step 1: Configure Terraform

```bash
cd terraform/podman
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` if needed. Key settings:

```hcl
frontend_node_port = 30300
backend_api_url    = "http://localhost:30800"
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Deploy

```bash
terraform plan
terraform apply
```

## Accessing the Application

After deployment:

```bash
# Get the frontend URL
terraform output frontend_url
# Output: http://localhost:30300

# Or check manually
kubectl get svc -n ieservices-elearn ieservices-elearn-frontend
```

Open in browser: **http://localhost:30300**

## Configuration

### Nginx Configuration

The deployment includes a custom Nginx configuration that:

- Enables Gzip compression
- Sets security headers
- Configures caching for static assets (1 year)
- Handles SPA routing (serves index.html for all routes)
- Provides a health check endpoint

### Environment Variables

Frontend environment variables are baked into the build. To change the backend API URL:

1. Rebuild the image with new URL:
   ```bash
   podman build --build-arg REACT_APP_API_URL=http://new-backend:30800 \
     -t localhost/ieservices-elearn-frontend:latest .
   ```

2. Restart the deployment:
   ```bash
   kubectl rollout restart deployment ieservices-elearn-frontend -n ieservices-elearn
   ```

## Monitoring and Debugging

### View Pods

```bash
kubectl get pods -n ieservices-elearn -l component=frontend
```

### View Logs

```bash
# Frontend logs
kubectl logs -n ieservices-elearn -l component=frontend -f

# Specific pod logs
kubectl logs -n ieservices-elearn <pod-name>
```

### Describe Resources

```bash
# Describe deployment
kubectl describe deployment ieservices-elearn-frontend -n ieservices-elearn

# Describe service
kubectl describe service ieservices-elearn-frontend -n ieservices-elearn
```

### Execute Commands in Pod

```bash
# Get a shell in frontend pod
kubectl exec -it -n ieservices-elearn \
  $(kubectl get pod -n ieservices-elearn -l component=frontend -o jsonpath="{.items[0].metadata.name}") \
  -- /bin/sh

# Check Nginx configuration
kubectl exec -n ieservices-elearn \
  $(kubectl get pod -n ieservices-elearn -l component=frontend -o jsonpath="{.items[0].metadata.name}") \
  -- nginx -t

# View served files
kubectl exec -n ieservices-elearn \
  $(kubectl get pod -n ieservices-elearn -l component=frontend -o jsonpath="{.items[0].metadata.name}") \
  -- ls -la /usr/share/nginx/html
```

## Scaling

### Manual Scaling

```bash
# Using kubectl
kubectl scale deployment ieservices-elearn-frontend -n ieservices-elearn --replicas=3

# Using Terraform
# Edit terraform.tfvars: frontend_replicas = 3
terraform apply
```

### Auto-Scaling

Enable horizontal pod autoscaling in `terraform.tfvars`:

```hcl
enable_autoscaling       = true
autoscaling_min_replicas = 1
autoscaling_max_replicas = 5
```

Apply changes:
```bash
terraform apply
```

View autoscaler status:
```bash
kubectl get hpa -n ieservices-elearn
```

## Updating the Application

### Step 1: Make Code Changes

Edit your React code as needed.

### Step 2: Rebuild Image

```bash
cd frontend
npm run build  # Test build locally first
podman build -t localhost/ieservices-elearn-frontend:latest .
```

### Step 3: Restart Deployment

```bash
kubectl rollout restart deployment ieservices-elearn-frontend -n ieservices-elearn
```

Or force recreation with Terraform:

```bash
cd terraform/podman
terraform taint kubernetes_deployment.frontend
terraform apply
```

### Step 4: Verify Deployment

```bash
kubectl rollout status deployment ieservices-elearn-frontend -n ieservices-elearn
```

## Resource Management

### View Resource Usage

```bash
kubectl top pods -n ieservices-elearn -l component=frontend
```

### Adjust Resource Limits

Edit `terraform.tfvars`:

```hcl
frontend_cpu_request    = "100m"
frontend_memory_request = "128Mi"
frontend_cpu_limit      = "500m"
frontend_memory_limit   = "256Mi"
```

Apply changes:
```bash
terraform apply
```

## Performance Optimization

### Caching Strategy

The Nginx configuration implements:

1. **Static Assets**: 1-year cache with immutable flag
2. **HTML Files**: No-cache (always fetch fresh)
3. **Gzip Compression**: Enabled for text-based files

### Build Optimization

Optimize React build:

```bash
# Use production build
npm run build

# Analyze bundle size
npm install -g source-map-explorer
source-map-explorer build/static/js/*.js
```

## Testing

### Health Check

```bash
# Test health endpoint
curl http://localhost:30300/health

# Expected output: healthy
```

### Load Testing

```bash
# Install hey (HTTP load testing tool)
# macOS: brew install hey
# Linux: go install github.com/rakyll/hey@latest

# Run load test
hey -n 1000 -c 10 http://localhost:30300/
```

## Troubleshooting

### Pods Not Starting

1. Check pod status:
   ```bash
   kubectl get pods -n ieservices-elearn -l component=frontend
   ```

2. Describe pod:
   ```bash
   kubectl describe pod <pod-name> -n ieservices-elearn
   ```

3. Check events:
   ```bash
   kubectl get events -n ieservices-elearn --sort-by='.lastTimestamp'
   ```

### Image Pull Errors

Verify image exists:
```bash
podman images | grep ieservices-elearn-frontend
```

If missing, rebuild:
```bash
cd frontend
podman build -t localhost/ieservices-elearn-frontend:latest .
```

### 404 Errors / Routing Issues

This usually means SPA routing isn't configured. Check Nginx config:

```bash
kubectl get configmap ieservices-elearn-frontend-nginx-config -n ieservices-elearn -o yaml
```

Verify the config includes:
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### Backend Connection Issues

1. Verify backend is running:
   ```bash
   curl http://localhost:30800/api/courses/
   ```

2. Check CORS configuration on backend

3. Verify API URL was set during build:
   ```bash
   kubectl exec -n ieservices-elearn \
     $(kubectl get pod -n ieservices-elearn -l component=frontend -o jsonpath="{.items[0].metadata.name}") \
     -- cat /usr/share/nginx/html/index.html | grep REACT_APP_API_URL
   ```

### High Memory Usage

Nginx with static files should use minimal memory. If high:

1. Check for memory leaks:
   ```bash
   kubectl top pod -n ieservices-elearn -l component=frontend
   ```

2. Reduce resource limits if over-provisioned:
   ```hcl
   frontend_memory_limit = "64Mi"  # Nginx + static files need very little
   ```

### Port Already in Use

Change NodePort in `terraform.tfvars`:
```hcl
frontend_node_port = 30301
```

Apply changes:
```bash
terraform apply
```

## Development Workflow

### Quick Rebuild and Deploy Script

Create `redeploy.sh` in frontend directory:

```bash
#!/bin/bash
set -e

echo "Building frontend..."
npm run build

echo "Building Docker image..."
podman build -t localhost/ieservices-elearn-frontend:latest .

echo "Restarting deployment..."
kubectl rollout restart deployment ieservices-elearn-frontend -n ieservices-elearn

echo "Waiting for rollout..."
kubectl rollout status deployment ieservices-elearn-frontend -n ieservices-elearn

echo "Deployment complete!"
echo "Frontend URL: http://localhost:30300"
```

Make executable:
```bash
chmod +x redeploy.sh
```

Usage:
```bash
./redeploy.sh
```

## Integration with Backend

The frontend connects to the backend via the NodePort service:

```
Frontend (localhost:30300)
    ↓ HTTP
Backend (localhost:30800)
    ↓ PostgreSQL
Database (internal ClusterIP)
```

Ensure CORS is configured on the backend to allow `http://localhost:30300`.

## Cleanup

### Remove Frontend Only

```bash
terraform destroy
```

This keeps the backend and database running.

### Remove Everything

```bash
# Remove frontend
cd frontend/terraform/podman
terraform destroy

# Remove backend
cd ../../../backend/terraform/podman
terraform destroy

# Or delete entire namespace
kubectl delete namespace ieservices-elearn
```

## Comparison: Podman vs AWS

| Feature | AWS | Podman Kubernetes |
|---------|-----|-------------------|
| Hosting | S3 + CloudFront | Nginx in Pod |
| CDN | CloudFront | None (local) |
| Caching | CloudFront Edge | Browser only |
| HTTPS | ACM Certificate | None (local HTTP) |
| Cost | ~$5-15/month | Free |
| Deployment | S3 sync + invalidation | Pod restart |
| Scaling | Automatic (CDN) | Manual/HPA |

## Best Practices

1. **Resource Limits**: Nginx needs minimal resources (50m CPU, 64Mi RAM)
2. **Health Checks**: Always configure liveness and readiness probes
3. **Caching**: Use appropriate cache headers for static assets
4. **Security Headers**: Configure CSP, X-Frame-Options, etc.
5. **Compression**: Enable Gzip for faster loading
6. **SPA Routing**: Configure try_files for client-side routing
7. **Build Optimization**: Minimize bundle size with code splitting
8. **Monitoring**: Track resource usage with `kubectl top`

## Advanced Configuration

### Custom Domain (Local)

Add to `/etc/hosts`:
```
127.0.0.1 elearn.local
```

Access via: http://elearn.local:30300

### Ingress Controller (Optional)

For more advanced routing, install an ingress controller:

```bash
# Install Nginx Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Create Ingress resource
# See Kubernetes documentation for details
```

## Support

For issues related to:
- **Podman**: https://podman.io/docs
- **Kubernetes**: https://kubernetes.io/docs
- **Nginx**: https://nginx.org/en/docs/
- **React Build**: See Create React App documentation
- **Application**: See main project README
