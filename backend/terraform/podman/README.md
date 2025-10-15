# ieServices E-Learning Platform - Backend Podman Kubernetes Deployment

This directory contains Terraform configurations for deploying the Django backend to a local Podman Kubernetes cluster.

## Architecture

The infrastructure includes:

- **Kubernetes Namespace**: Isolated environment for the application
- **PostgreSQL**: Database running in a pod with persistent storage
- **Django Backend**: Containerized application with multiple replicas
- **ConfigMaps & Secrets**: Configuration and sensitive data management
- **Services**: ClusterIP for PostgreSQL, NodePort for backend access
- **Init Containers**: Wait for database readiness
- **Migration Job**: Automated database migrations
- **Resource Limits**: CPU and memory constraints
- **Health Checks**: Liveness and readiness probes

## Prerequisites

### 1. Install Podman

**Windows:**
```powershell
winget install RedHat.Podman
```

**macOS:**
```bash
brew install podman
```

**Linux:**
```bash
# Fedora/RHEL
sudo dnf install podman

# Ubuntu/Debian
sudo apt-get install podman
```

### 2. Initialize Podman Machine (Windows/macOS)

```bash
podman machine init --cpus 4 --memory 4096 --disk-size 50
podman machine start
```

### 3. Enable Podman Kubernetes

```bash
# Start Podman Kubernetes cluster
podman kube play --help

# Or use kind with podman driver (alternative)
KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster --name podman
```

### 4. Install kubectl

**Windows:**
```powershell
winget install Kubernetes.kubectl
```

**macOS:**
```bash
brew install kubectl
```

**Linux:**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 5. Verify Kubernetes Context

```bash
kubectl config get-contexts
kubectl config use-context podman
```

### 6. Install Terraform

**Windows:**
```powershell
winget install Hashicorp.Terraform
```

**macOS:**
```bash
brew install terraform
```

**Linux:**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

## Setup

### Step 1: Build the Docker Image

```bash
cd ../../  # Navigate to backend directory
podman build -t localhost/ieservices-elearn-backend:latest -f terraform/aws/Dockerfile .
```

**Note:** The image is tagged with `localhost/` prefix for local registry.

### Step 2: Configure Terraform

```bash
cd terraform/podman
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` if needed (defaults are suitable for local development).

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Deploy

```bash
terraform plan
terraform apply
```

## Accessing the Application

After deployment, the backend will be available at:

```bash
# Get the backend URL
terraform output backend_url
# Output: http://localhost:30800

# Or manually check
kubectl get svc -n ieservices-elearn
```

Access the API:
- **REST API**: http://localhost:30800/api/courses/
- **GraphQL**: http://localhost:30800/graphql
- **Admin**: http://localhost:30800/admin

## Database Management

### Running Migrations

Migrations run automatically via a Kubernetes Job during deployment. To run manually:

```bash
kubectl run -it --rm migrate \
  --image=localhost/ieservices-elearn-backend:latest \
  --restart=Never \
  --namespace=ieservices-elearn \
  --env="DATABASE_URL=postgresql://elearn_admin:elearn_password@ieservices-elearn-postgres:5432/elearn" \
  -- python manage.py migrate
```

### Loading Demo Data

```bash
kubectl run -it --rm seed-demo \
  --image=localhost/ieservices-elearn-backend:latest \
  --restart=Never \
  --namespace=ieservices-elearn \
  --env="DATABASE_URL=postgresql://elearn_admin:elearn_password@ieservices-elearn-postgres:5432/elearn" \
  -- python manage.py seed_demo
```

### Accessing PostgreSQL

```bash
# Port forward to local machine
kubectl port-forward -n ieservices-elearn svc/ieservices-elearn-postgres 5432:5432

# Connect with psql
psql -h localhost -U elearn_admin -d elearn
# Password: elearn_password
```

## Monitoring and Debugging

### View Pods

```bash
kubectl get pods -n ieservices-elearn
```

### View Logs

```bash
# Backend logs
kubectl logs -n ieservices-elearn -l component=backend -f

# PostgreSQL logs
kubectl logs -n ieservices-elearn -l component=database -f

# Migration job logs
kubectl logs -n ieservices-elearn -l component=migration
```

### Describe Resources

```bash
# Describe backend deployment
kubectl describe deployment ieservices-elearn-backend -n ieservices-elearn

# Describe backend service
kubectl describe service ieservices-elearn-backend -n ieservices-elearn
```

### Execute Commands in Pod

```bash
# Get a shell in backend pod
kubectl exec -it -n ieservices-elearn \
  $(kubectl get pod -n ieservices-elearn -l component=backend -o jsonpath="{.items[0].metadata.name}") \
  -- /bin/bash

# Run Django management commands
kubectl exec -it -n ieservices-elearn \
  $(kubectl get pod -n ieservices-elearn -l component=backend -o jsonpath="{.items[0].metadata.name}") \
  -- python manage.py createsuperuser
```

## Scaling

### Scale Backend

```bash
# Using kubectl
kubectl scale deployment ieservices-elearn-backend -n ieservices-elearn --replicas=3

# Using Terraform
# Edit terraform.tfvars: backend_replicas = 3
terraform apply
```

## Updating the Application

### Step 1: Rebuild Image

```bash
cd ../../
podman build -t localhost/ieservices-elearn-backend:latest -f terraform/aws/Dockerfile .
```

### Step 2: Restart Pods

```bash
kubectl rollout restart deployment ieservices-elearn-backend -n ieservices-elearn
```

Or force recreation with Terraform:

```bash
cd terraform/podman
terraform taint kubernetes_deployment.backend
terraform apply
```

## Resource Management

### View Resource Usage

```bash
kubectl top pods -n ieservices-elearn
kubectl top nodes
```

### Adjust Resource Limits

Edit `terraform.tfvars`:

```hcl
backend_cpu_request    = "200m"
backend_memory_request = "512Mi"
backend_cpu_limit      = "1000m"
backend_memory_limit   = "1Gi"
```

Then apply:

```bash
terraform apply
```

## Persistent Data

PostgreSQL data is stored in a PersistentVolumeClaim. The data persists across pod restarts.

### View PVCs

```bash
kubectl get pvc -n ieservices-elearn
```

### Backup Database

```bash
# Export database
kubectl exec -n ieservices-elearn \
  $(kubectl get pod -n ieservices-elearn -l component=database -o jsonpath="{.items[0].metadata.name}") \
  -- pg_dump -U elearn_admin elearn > backup.sql

# Import database
kubectl exec -i -n ieservices-elearn \
  $(kubectl get pod -n ieservices-elearn -l component=database -o jsonpath="{.items[0].metadata.name}") \
  -- psql -U elearn_admin elearn < backup.sql
```

## Troubleshooting

### Pods Not Starting

1. Check pod status:
   ```bash
   kubectl get pods -n ieservices-elearn
   ```

2. Describe pod for events:
   ```bash
   kubectl describe pod <pod-name> -n ieservices-elearn
   ```

3. Check logs:
   ```bash
   kubectl logs <pod-name> -n ieservices-elearn
   ```

### Image Pull Errors

Make sure image exists locally:
```bash
podman images | grep ieservices-elearn-backend
```

If missing, rebuild:
```bash
cd ../../
podman build -t localhost/ieservices-elearn-backend:latest -f terraform/aws/Dockerfile .
```

### Database Connection Issues

1. Check PostgreSQL pod is running:
   ```bash
   kubectl get pods -n ieservices-elearn -l component=database
   ```

2. Verify service:
   ```bash
   kubectl get svc -n ieservices-elearn ieservices-elearn-postgres
   ```

3. Test connection from backend pod:
   ```bash
   kubectl exec -it -n ieservices-elearn \
     $(kubectl get pod -n ieservices-elearn -l component=backend -o jsonpath="{.items[0].metadata.name}") \
     -- nc -zv ieservices-elearn-postgres 5432
   ```

### Port Already in Use

If NodePort 30800 is already in use, change it in `terraform.tfvars`:
```hcl
backend_node_port = 30801
```

Then apply:
```bash
terraform apply
```

## Cleanup

### Remove All Resources

```bash
terraform destroy
```

### Manual Cleanup (if needed)

```bash
# Delete namespace (removes everything)
kubectl delete namespace ieservices-elearn

# Or delete specific resources
kubectl delete all --all -n ieservices-elearn
kubectl delete pvc --all -n ieservices-elearn
kubectl delete configmap --all -n ieservices-elearn
kubectl delete secret --all -n ieservices-elearn
```

## Development Workflow

### Quick Rebuild and Deploy

Create a helper script `redeploy.sh`:

```bash
#!/bin/bash
set -e

echo "Building image..."
cd ../../
podman build -t localhost/ieservices-elearn-backend:latest -f terraform/aws/Dockerfile .

echo "Restarting deployment..."
kubectl rollout restart deployment ieservices-elearn-backend -n ieservices-elearn

echo "Waiting for rollout..."
kubectl rollout status deployment ieservices-elearn-backend -n ieservices-elearn

echo "Deployment complete!"
```

Make it executable:
```bash
chmod +x redeploy.sh
```

## Integration with Frontend

The frontend should be configured to connect to the backend NodePort:

```bash
# In frontend .env
REACT_APP_API_URL=http://localhost:30800
```

See `frontend/terraform/podman/` for frontend Kubernetes deployment.

## Differences from AWS Deployment

| Feature | AWS | Podman Kubernetes |
|---------|-----|-------------------|
| Database | RDS PostgreSQL | PostgreSQL in Pod |
| Load Balancer | ALB | NodePort Service |
| Container Registry | ECR | Local Podman |
| Auto-Scaling | ECS Service | Manual kubectl scale |
| Persistent Storage | EBS | Local PVC |
| Networking | VPC with subnets | Cluster networking |
| Cost | ~$40-60/month | Free (local) |

## Best Practices

1. **Resource Limits**: Always set CPU and memory limits
2. **Health Checks**: Configure liveness and readiness probes
3. **Init Containers**: Wait for dependencies before starting
4. **Secrets**: Never commit secrets to version control
5. **Namespaces**: Use namespaces for isolation
6. **Labels**: Apply consistent labels for easier management
7. **Backup**: Regularly backup PostgreSQL data
8. **Monitoring**: Use `kubectl top` to monitor resource usage

## Support

For issues related to:
- **Podman**: https://podman.io/docs
- **Kubernetes**: https://kubernetes.io/docs
- **Terraform Kubernetes Provider**: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
- **Application**: See main project README
