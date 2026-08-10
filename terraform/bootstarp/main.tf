provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  tags = {
    Name        = var.state_bucket_name
    Project     = "devops-aws-cicd"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = {
    Name      = "github-actions-oidc"
    Project   = "devops-aws-cicd"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role" "github_terraform" {
  name = "devops-aws-cicd-github-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:ANAGHANU@90793496/devops-aws-cicd@1327489396:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Name      = "devops-aws-cicd-github-terraform"
    Project   = "devops-aws-cicd"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_terraform_poweruser" {
  role       = aws_iam_role.github_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy" "github_terraform_iam" {
  name = "devops-aws-cicd-terraform-iam"
  role = aws_iam_role.github_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:PassRole"
        ]

        Resource = "*"
      }
    ]
  })
}