provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-aws-cicd"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}