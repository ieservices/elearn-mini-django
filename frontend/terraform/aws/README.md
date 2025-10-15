# ieServices E-Learning Platform - Frontend Infrastructure

This directory contains Terraform configurations for deploying the React frontend to AWS.

## Architecture

The infrastructure includes:

- **S3 Bucket**: Hosts the static React application build
- **CloudFront CDN**: Global content delivery network with caching
- **Origin Access Control**: Secure S3 access from CloudFront only
- **CloudWatch**: Logging and monitoring
- **Route53** (optional): Custom domain DNS configuration
- **ACM Certificate** (optional): SSL/TLS for custom domains

## Prerequisites

1. AWS Account with appropriate permissions
2. AWS CLI configured with credentials
3. Terraform >= 1.0 installed
4. Node.js and npm installed (for building the React app)
5. Backend deployed and ALB DNS name available

## Setup

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and update:
   - `backend_api_url`: Set to your backend ALB DNS name (from backend Terraform outputs)
   - `aws_region`: Your preferred AWS region
   - For custom domain: uncomment and set `domain_name`, `subdomain`, and `acm_certificate_arn`
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

### Step 1: Configure the Backend API URL

Create or update the `.env.production` file in the frontend directory:

```bash
cd ../..  # Go to frontend directory
echo "REACT_APP_API_URL=http://your-backend-alb-dns.amazonaws.com" > .env.production
```

### Step 2: Build the React Application

```bash
npm install
npm run build
```

This creates an optimized production build in the `build/` directory.

### Step 3: Deploy to S3

Upload the build files to S3:

```bash
aws s3 sync build/ s3://ieservices-elearn-dev-frontend/ --delete
```

### Step 4: Invalidate CloudFront Cache

After uploading new files, invalidate the CloudFront cache:

```bash
aws cloudfront create-invalidation \
  --distribution-id <distribution_id> \
  --paths "/*"
```

Get the distribution ID from Terraform outputs:
```bash
cd terraform/aws
terraform output cloudfront_distribution_id
```

## Automated Deployment Script

Create a deployment script `deploy.sh` in the frontend directory:

```bash
#!/bin/bash
set -e

# Load environment
ENVIRONMENT=${1:-dev}

# Get bucket name from Terraform
cd terraform/aws
S3_BUCKET=$(terraform output -raw s3_bucket_name)
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
cd ../..

# Build the application
echo "Building application..."
npm run build

# Sync to S3
echo "Uploading to S3..."
aws s3 sync build/ s3://$S3_BUCKET/ --delete

# Invalidate CloudFront cache
echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"

echo "Deployment complete!"
echo "Frontend URL: $(cd terraform/aws && terraform output -raw cloudfront_url)"
```

Make it executable:
```bash
chmod +x deploy.sh
```

Run deployment:
```bash
./deploy.sh dev
```

## CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/deploy-frontend.yml`:

```yaml
name: Deploy Frontend

on:
  push:
    branches: [main]
    paths:
      - 'frontend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build
        env:
          REACT_APP_API_URL: ${{ secrets.BACKEND_API_URL }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Deploy to S3
        run: |
          aws s3 sync build/ s3://${{ secrets.S3_BUCKET }}/ --delete

      - name: Invalidate CloudFront
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"
```

## Accessing the Application

After deployment, get the CloudFront URL:

```bash
terraform output cloudfront_url
```

Access the application at this URL. It will connect to your backend API.

## Custom Domain Setup

### Prerequisites

1. Domain registered in Route53 or external registrar
2. ACM certificate created in `us-east-1` region

### Steps

1. Request an ACM certificate in us-east-1:
   ```bash
   aws acm request-certificate \
     --domain-name example.com \
     --subject-alternative-names app.example.com \
     --validation-method DNS \
     --region us-east-1
   ```

2. Validate the certificate using DNS validation

3. Update `terraform.tfvars`:
   ```hcl
   domain_name         = "example.com"
   subdomain           = "app"
   acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxx"
   ```

4. Uncomment the Route53 and certificate blocks in `main.tf`

5. Apply the changes:
   ```bash
   terraform apply
   ```

## Performance Optimization

### CloudFront Cache Optimization

1. **Static Assets**: Long cache TTL (1 year) with versioned filenames
2. **HTML Files**: Short cache TTL (1 hour) to allow updates
3. **Compression**: Enabled for all content types

### Best Practices

1. Use content hashing in filenames (React does this by default)
2. Set proper cache headers in S3
3. Use CloudFront cache invalidation sparingly (it's not free after 1000/month)
4. Consider using Lambda@Edge for advanced routing

## Cost Optimization

### Development Environment
- Use `PriceClass_100` (North America + Europe only)
- Set appropriate CloudWatch log retention
- Consider using S3 lifecycle policies for old versions

### Production Environment
- Use `PriceClass_200` or `PriceClass_All` based on audience
- Enable CloudFront access logs for analytics
- Use Reserved Capacity for predictable traffic

### Estimated Monthly Costs (Development)

- S3 Storage: $0.023/GB (~$0.05 for typical React app)
- CloudFront: $0.085/GB transfer + $0.01 per 10,000 requests
- Route53 (if using custom domain): $0.50 per hosted zone
- ACM Certificate: Free

**Total**: ~$5-15/month for low traffic dev environment

## Monitoring

### CloudWatch Metrics

Monitor these CloudFront metrics:
- `Requests`: Number of requests
- `BytesDownloaded`: Data transfer
- `4xxErrorRate`: Client errors
- `5xxErrorRate`: Server errors
- `CacheHitRate`: Cache effectiveness

### Setting Up Alarms

Create alarms for error rates:

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name high-error-rate-frontend \
  --alarm-description "Alert when error rate is high" \
  --metric-name 5xxErrorRate \
  --namespace AWS/CloudFront \
  --statistic Average \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold
```

## Troubleshooting

### 403 Forbidden Errors

1. Check S3 bucket policy allows CloudFront access
2. Verify Origin Access Control is configured correctly
3. Ensure files were uploaded to S3

### Application Not Loading

1. Check browser console for errors
2. Verify REACT_APP_API_URL is set correctly
3. Check CORS settings on backend
4. Verify CloudFront distribution is deployed

### Stale Content

1. Check CloudFront cache settings
2. Create cache invalidation
3. Verify S3 files were updated
4. Check browser cache (hard refresh: Ctrl+Shift+R)

### High Costs

1. Review CloudFront usage in Cost Explorer
2. Check for unexpected traffic patterns
3. Consider price class changes
4. Review cache hit rates

## Security Best Practices

1. **S3 Access**: Keep bucket private, use CloudFront OAC
2. **HTTPS**: Always use HTTPS (CloudFront redirects HTTP to HTTPS)
3. **WAF**: Consider adding AWS WAF for production
4. **CSP Headers**: Implement Content Security Policy
5. **Secrets**: Never commit API keys or secrets

## Cleanup

To destroy all resources:

```bash
# Empty S3 buckets first
aws s3 rm s3://ieservices-elearn-dev-frontend --recursive
aws s3 rm s3://ieservices-elearn-dev-deployment-artifacts --recursive

# Destroy infrastructure
terraform destroy
```

## Support

For issues related to:
- **Infrastructure**: Contact ieServices DevOps team
- **Application**: See main project README
- **AWS Services**: Refer to AWS documentation
