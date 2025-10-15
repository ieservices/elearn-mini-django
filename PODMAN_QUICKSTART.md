# ieServices E-Learning Platform - Podman Kubernetes Quick Start

This guide will help you deploy the entire application stack locally using Podman Kubernetes in under 10 minutes.

## What You'll Get

- Django backend with GraphQL API
- PostgreSQL database with persistent storage
- React frontend with Nginx
- All running in Kubernetes pods on your local machine
- Free (no cloud costs)

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

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install podman
```

### 2. Initialize Podman Machine (Windows/macOS only)

```bash
podman machine init --cpus 4 --memory 4096 --disk-size 50
podman machine start
```

Linux users can skip this step.

### 3. Install kubectl

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

### 4. Setup Kubernetes with Kind

```bash
# Install kind
# Windows: winget install Kubernetes.kind
# macOS: brew install kind
# Linux: See https://kind.sigs.k8s.io/docs/user/quick-start/#installation

# Create cluster with podman driver
KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster --name podman

# Verify
kubectl config use-context kind-podman
kubectl get nodes
```

### 5. Install Terraform

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

## Deployment Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/ieservices/elearn-mini-django.git
cd elearn-mini-django
```

### Step 2: Build Docker Images

#### Backend Image

```bash
cd backend
podman build -t localhost/ieservices-elearn-backend:latest -f terraform/aws/Dockerfile .
```

**Expected output:** Successfully tagged localhost/ieservices-elearn-backend:latest

#### Frontend Image

```bash
cd ../frontend
podman build -t localhost/ieservices-elearn-frontend:latest .
```

**Expected output:** Successfully tagged localhost/ieservices-elearn-frontend:latest

### Step 3: Deploy Backend

```bash
cd terraform/podman

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Initialize Terraform
terraform init

# Deploy
terraform apply -auto-approve
```

**Wait time:** ~2 minutes

**Expected output:**
```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:
backend_url = "http://localhost:30800"
```

### Step 4: Verify Backend

```bash
# Check pods are running
kubectl get pods -n ieservices-elearn

# Test API
curl http://localhost:30800/api/courses/
```

**Expected:** JSON response with courses (may be empty initially)

### Step 5: Load Demo Data

```bash
kubectl run -it --rm seed-demo \
  --image=localhost/ieservices-elearn-backend:latest \
  --restart=Never \
  --namespace=ieservices-elearn \
  --env="DATABASE_URL=postgresql://elearn_admin:elearn_password@ieservices-elearn-postgres:5432/elearn" \
  --env="DJANGO_SECRET_KEY=local-dev-secret-key" \
  -- python manage.py seed_demo
```

**Expected output:** Demo data created successfully

### Step 6: Deploy Frontend

```bash
cd ../../../frontend/terraform/podman

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Initialize Terraform
terraform init

# Deploy
terraform apply -auto-approve
```

**Expected output:**
```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:
frontend_url = "http://localhost:30300"
```

### Step 7: Access the Application

Open your browser and navigate to:

**Frontend:** http://localhost:30300

**Backend API:** http://localhost:30800/api/courses/

**GraphQL Playground:** http://localhost:30800/graphql

## Verify Everything is Running

```bash
# Check all pods
kubectl get pods -n ieservices-elearn

# Expected output:
# NAME                                       READY   STATUS    RESTARTS   AGE
# ieservices-elearn-backend-xxx              1/1     Running   0          5m
# ieservices-elearn-frontend-xxx             1/1     Running   0          2m
# ieservices-elearn-postgres-xxx             1/1     Running   0          5m

# Check services
kubectl get svc -n ieservices-elearn

# Expected output:
# NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
# ieservices-elearn-backend    NodePort    10.96.xxx.xxx   <none>        8000:30800/TCP   5m
# ieservices-elearn-frontend   NodePort    10.96.xxx.xxx   <none>        80:30300/TCP     2m
# ieservices-elearn-postgres   ClusterIP   10.96.xxx.xxx   <none>        5432/TCP         5m
```

## Using the Application

1. **Browse Courses:** Visit http://localhost:30300
2. **Click on a course tile** to see the description
3. **Test GraphQL:** Go to http://localhost:30800/graphql and try:
   ```graphql
   query {
     courses {
       id
       title
       description
       isActive
       createdAt
     }
   }
   ```

## Making Changes

### Update Backend Code

```bash
# Make your changes in backend/

# Rebuild image
cd backend
podman build -t localhost/ieservices-elearn-backend:latest -f terraform/aws/Dockerfile .

# Restart deployment
kubectl rollout restart deployment ieservices-elearn-backend -n ieservices-elearn

# Watch rollout
kubectl rollout status deployment ieservices-elearn-backend -n ieservices-elearn
```

### Update Frontend Code

```bash
# Make your changes in frontend/src/

# Rebuild image
cd frontend
podman build -t localhost/ieservices-elearn-frontend:latest .

# Restart deployment
kubectl rollout restart deployment ieservices-elearn-frontend -n ieservices-elearn

# Watch rollout
kubectl rollout status deployment ieservices-elearn-frontend -n ieservices-elearn
```

## View Logs

```bash
# Backend logs
kubectl logs -n ieservices-elearn -l component=backend -f

# Frontend logs
kubectl logs -n ieservices-elearn -l component=frontend -f

# Database logs
kubectl logs -n ieservices-elearn -l component=database -f
```

## Scaling

```bash
# Scale backend to 3 replicas
kubectl scale deployment ieservices-elearn-backend -n ieservices-elearn --replicas=3

# Scale frontend to 2 replicas
kubectl scale deployment ieservices-elearn-frontend -n ieservices-elearn --replicas=2

# Verify
kubectl get pods -n ieservices-elearn
```

## Cleanup

### Stop Everything (Keep Data)

```bash
# Stop frontend
cd frontend/terraform/podman
terraform destroy -auto-approve

# Stop backend
cd ../../../backend/terraform/podman
terraform destroy -auto-approve
```

### Delete Cluster (Remove Everything)

```bash
kind delete cluster --name podman
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n ieservices-elearn

# Describe pod to see events
kubectl describe pod <pod-name> -n ieservices-elearn

# Check logs
kubectl logs <pod-name> -n ieservices-elearn
```

### Port Already in Use

If ports 30300 or 30800 are already in use:

1. Edit `terraform.tfvars`:
   ```hcl
   # Backend
   backend_node_port = 30801

   # Frontend
   frontend_node_port = 30301
   ```

2. Apply changes:
   ```bash
   terraform apply
   ```

### Cannot Access Application

```bash
# Verify services
kubectl get svc -n ieservices-elearn

# Port forward as alternative
kubectl port-forward -n ieservices-elearn svc/ieservices-elearn-backend 8000:8000
kubectl port-forward -n ieservices-elearn svc/ieservices-elearn-frontend 3000:80
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
kubectl get pods -n ieservices-elearn -l component=database

# Test connection from backend pod
kubectl exec -it -n ieservices-elearn \
  $(kubectl get pod -n ieservices-elearn -l component=backend -o jsonpath="{.items[0].metadata.name}") \
  -- nc -zv ieservices-elearn-postgres 5432
```

## Next Steps

- **Customize:** Modify the code and see changes in real-time
- **Learn:** Explore the Terraform configurations to understand Kubernetes deployments
- **Develop:** Use this as your local development environment
- **Deploy to AWS:** When ready, use the `terraform/aws` configurations for production

## Resources

- Backend Podman README: `backend/terraform/podman/README.md`
- Frontend Podman README: `frontend/terraform/podman/README.md`
- Main README: `README.md`
- Podman Documentation: https://podman.io/docs
- Kubernetes Documentation: https://kubernetes.io/docs
- Kind Documentation: https://kind.sigs.k8s.io/docs

## Support

Having issues? Check:
1. All prerequisites are installed correctly
2. Podman machine is running (Windows/macOS)
3. Kind cluster is created and kubectl context is set
4. Docker images built successfully
5. Kubernetes pods are running

For more help, see the detailed README files in each terraform directory.

---

**Estimated Total Time:** 10-15 minutes

**Disk Space Required:** ~2GB (includes images and data)

**System Requirements:**
- 4 CPU cores
- 4GB RAM
- 20GB disk space
