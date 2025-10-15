# ieServices E-Learning Platform - Frontend Outputs

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend"
  value       = aws_s3_bucket.frontend.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.frontend.arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_url" {
  description = "Full URL of the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "deployment_artifacts_bucket" {
  description = "Name of the deployment artifacts bucket"
  value       = aws_s3_bucket.deployment_artifacts.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.frontend.name
}

# Uncomment if using custom domain
# output "custom_domain_url" {
#   description = "Custom domain URL"
#   value       = var.subdomain != "" ? "https://${var.subdomain}.${var.domain_name}" : "https://${var.domain_name}"
# }
