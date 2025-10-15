
## AWS Deployment

The project includes comprehensive Terraform configurations for deploying to AWS.

### Backend Deployment (AWS ECS Fargate)

Located in `backend/terraform/aws/`:

- **Infrastructure**: VPC, ECS Fargate, RDS PostgreSQL, Application Load Balancer
- **Features**: Auto-scaling, CloudWatch logging, Multi-AZ deployment
- **Documentation**: See `backend/terraform/aws/README.md`

Quick start:
```bash
cd backend/terraform/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

### Frontend Deployment (AWS S3 + CloudFront)

Located in `frontend/terraform/aws/`:

- **Infrastructure**: S3 static hosting, CloudFront CDN, optional Route53
- **Features**: Global CDN, HTTPS, automatic cache invalidation
- **Documentation**: See `frontend/terraform/aws/README.md`

Quick start:
```bash
cd frontend/terraform/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your backend API URL
terraform init
terraform apply
```

Deploy the frontend:
```bash
cd frontend
chmod +x deploy.sh
./deploy.sh dev
```
