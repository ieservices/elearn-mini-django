# ieServices E-Learning Platform - Backend Infrastructure

This directory contains Terraform configurations for deploying the Django backend to AWS.

## Architecture

The infrastructure includes:

- **VPC**: Multi-AZ VPC with public and private subnets
- **ECS Fargate**: Containerized Django application with auto-scaling
- **Application Load Balancer**: Distributes traffic across ECS tasks
- **RDS PostgreSQL**: Managed database with automated backups
- **ECR**: Container registry for Docker images
- **CloudWatch**: Centralized logging and monitoring
- **Auto Scaling**: CPU and memory-based scaling policies

## Prerequisites

1. AWS Account with appropriate permissions
2. AWS CLI configured with credentials
3. Terraform >= 1.0 installed
4. Docker installed (for building and pushing images)

## Setup

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and update the following values:
   - `db_password`: Set a secure database password
   - `django_secret_key`: Generate a secure Django secret key
   - `aws_region`: Your preferred AWS region
   - Other values as needed

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the infrastructure plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Building and Deploying the Application

1. Create a Dockerfile in the backend directory (if not already present)

2. Authenticate Docker to ECR:
   ```bash
   aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <ecr_repository_url>
   ```

3. Build and tag the Docker image:
   ```bash
   cd ../..  # Go to backend directory
   docker build -t ieservices-elearn-backend .
   docker tag ieservices-elearn-backend:latest <ecr_repository_url>:latest
   ```

4. Push the image to ECR:
   ```bash
   docker push <ecr_repository_url>:latest
   ```

5. Update the ECS service to use the new image:
   ```bash
   aws ecs update-service --cluster <cluster_name> --service <service_name> --force-new-deployment
   ```

## Database Migrations

Run migrations using ECS Exec or by creating a one-off task:

```bash
aws ecs run-task \
  --cluster <cluster_name> \
  --task-definition <task_definition> \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<subnet_ids>],securityGroups=[<security_group_id>]}" \
  --overrides '{"containerOverrides": [{"name": "backend", "command": ["python", "manage.py", "migrate"]}]}'
```

## Accessing the Application

After deployment, the Application Load Balancer DNS name will be available in the Terraform outputs:

```bash
terraform output alb_dns_name
```

Access the backend API at:
- REST API: `http://<alb_dns_name>/api/courses/`
- GraphQL: `http://<alb_dns_name>/graphql`

## Monitoring

- CloudWatch Logs: `/ecs/ieservices-elearn-<environment>-backend`
- ECS Service Metrics: Available in CloudWatch under ECS namespace
- RDS Metrics: Available in CloudWatch under RDS namespace

## Cost Optimization

For development environments:
- Use `db.t3.micro` or `db.t4g.micro` for RDS
- Set `ecs_service_desired_count = 1`
- Set `ecs_autoscaling_max_capacity = 2`
- Consider using Aurora Serverless v2 for variable workloads

For production environments:
- Use larger instance types (`db.t3.small` or higher)
- Enable Multi-AZ for RDS
- Increase desired count and max capacity
- Enable deletion protection on ALB

## Security Best Practices

1. Store secrets in AWS Secrets Manager or SSM Parameter Store
2. Use HTTPS with ACM certificates (not included in this basic setup)
3. Restrict security group rules to necessary ports and sources
4. Enable AWS WAF for additional protection
5. Regularly rotate database credentials
6. Use separate environments for dev/staging/production

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources including the database. Make sure to backup any important data first.

## Troubleshooting

### ECS Tasks Not Starting

1. Check CloudWatch logs for container errors
2. Verify security group rules allow necessary traffic
3. Ensure the Docker image exists in ECR
4. Check IAM role permissions

### Database Connection Issues

1. Verify security group allows traffic from ECS tasks
2. Check DATABASE_URL environment variable
3. Ensure database credentials are correct
4. Verify RDS instance is available

### High Costs

1. Review CloudWatch metrics for over-provisioning
2. Check for idle resources
3. Consider using Savings Plans or Reserved Instances
4. Enable Cost Anomaly Detection

## Support

For issues related to:
- **Infrastructure**: Contact ieServices DevOps team
- **Application**: See main project README
- **AWS Services**: Refer to AWS documentation
