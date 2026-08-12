resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "devops-aws-cicd-vpc-branch"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devops-aws-cicd-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "devops-aws-cicd-public-subnet"
    Tier = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devops-aws-cicd-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "devops-aws-cicd-web-sg"
  description = "Security group for the DevOps application EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound IPv4 traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-aws-cicd-web-sg"
  }
}

resource "aws_iam_role" "ec2" {
  name = "devops-aws-cicd-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "devops-aws-cicd-ec2-role"
  }
}

resource "aws_iam_instance_profile" "ec2" {
  name = "devops-aws-cicd-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name = "devops-aws-cicd-ec2-profile"
  }
}

# resource "aws_iam_role_policy_attachment" "ec2_ecr_pull" {
#   role       = aws_iam_role.ec2.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
# }

resource "aws_iam_role_policy" "ec2_ecr_pull" {
  name = "devops-aws-cicd-ec2-ecr-pull"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]

        Resource = aws_ecr_repository.app.arn
      }
    ]
  })
}

data "aws_ssm_parameter" "amazon_linux" {
  name = var.ami_ssm_parameter
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.amazon_linux.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2.name


  user_data = <<-EOF
              #!/bin/bash

              set -e

              exec > >(tee /var/log/devops-bootstrap.log | logger -t devops-bootstrap -s 2>/dev/console) 2>&1

              echo "Starting EC2 bootstrap..."

              dnf update -y
              dnf install -y docker

              systemctl enable docker
              systemctl start docker

              usermod -aG docker ec2-user

              echo "Installing Docker Compose..."

              mkdir -p /usr/local/lib/docker/cli-plugins

              curl -SL \
                https://github.com/docker/compose/releases/download/v5.1.2/docker-compose-linux-x86_64 \
                -o /usr/local/lib/docker/cli-plugins/docker-compose

              chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

              echo "Docker version:"
              docker --version

              echo "Docker Compose version:"
              docker compose version

              echo "EC2 bootstrap completed."
              EOF

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "devops-aws-cicd-app"
  }
}

resource "aws_ecr_repository" "app" {
  name                 = "devops-aws-cicd-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "devops-aws-cicd-app-ecr"
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 20 most recent images"

        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_application" {
  name = "devops-aws-cicd-github-application"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
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
    Name      = "devops-aws-cicd-github-application"
    Project   = "devops-aws-cicd"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy" "github_application_ecr" {
  name = "devops-aws-cicd-github-ecr"
  role = aws_iam_role.github_application.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]

        Resource = aws_ecr_repository.app.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_application_ssm" {
  name = "devops-aws-cicd-github-ssm"
  role = aws_iam_role.github_application.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ssm:SendCommand"
        ]

        Resource = [
          "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript",
          aws_instance.app.arn
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "ssm:GetCommandInvocation"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "ec2:DescribeInstances"
        ]

        Resource = "*"
      },
    ]
  })
}

