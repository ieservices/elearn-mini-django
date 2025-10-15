#!/bin/bash
# ieServices E-Learning Platform - Frontend Deployment Script

set -e

# Configuration
ENVIRONMENT=${1:-dev}
PROJECT_NAME="ieservices-elearn"

echo "=========================================="
echo "ieServices E-Learning Frontend Deployment"
echo "Environment: $ENVIRONMENT"
echo "=========================================="

# Check if Terraform is initialized
if [ ! -d "terraform/aws/.terraform" ]; then
    echo "Error: Terraform not initialized. Run 'cd terraform/aws && terraform init' first."
    exit 1
fi

# Get Terraform outputs
echo "Getting infrastructure details from Terraform..."
cd terraform/aws
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")

if [ -z "$S3_BUCKET" ] || [ -z "$DISTRIBUTION_ID" ]; then
    echo "Error: Could not get Terraform outputs. Make sure infrastructure is deployed."
    exit 1
fi

echo "S3 Bucket: $S3_BUCKET"
echo "CloudFront Distribution: $DISTRIBUTION_ID"
cd ../..

# Install dependencies
echo ""
echo "Installing dependencies..."
npm install

# Build the application
echo ""
echo "Building application..."
npm run build

# Sync to S3
echo ""
echo "Uploading to S3..."
aws s3 sync build/ s3://$S3_BUCKET/ --delete

# Invalidate CloudFront cache
echo ""
echo "Invalidating CloudFront cache..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id $DISTRIBUTION_ID \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

echo "Cache invalidation created: $INVALIDATION_ID"

# Get CloudFront URL
cd terraform/aws
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url)
cd ../..

echo ""
echo "=========================================="
echo "Deployment complete!"
echo "Frontend URL: $CLOUDFRONT_URL"
echo "=========================================="
echo ""
echo "Note: CloudFront cache invalidation may take a few minutes."
echo "Check status: aws cloudfront get-invalidation --distribution-id $DISTRIBUTION_ID --id $INVALIDATION_ID"
