output "terraform_state_bucket" {
  description = "S3 bucket used for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_terraform_role_arn" {
  description = "ARN of the GitHub Actions Terraform role"
  value       = aws_iam_role.github_terraform.arn
}

