output "aws_region" {
  description = "AWS region used by the infrastructure"
  value       = var.aws_region
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "vpc_id" {
  description = "ID of the project VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = aws_subnet.public.cidr_block
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "ID of the application EC2 instance"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "Public IP address of the application EC2 instance"
  value       = aws_instance.app.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the application EC2 instance"
  value       = aws_instance.app.public_dns
}

output "ec2_iam_role" {
  description = "IAM role attached to the application EC2 instance"
  value       = aws_iam_role.ec2.name
}

output "ecr_repository_name" {
  description = "Name of the application ECR repository"
  value       = aws_ecr_repository.app.name
}

output "ecr_repository_url" {
  description = "URL of the application ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the application ECR repository"
  value       = aws_ecr_repository.app.arn
}

output "github_application_role_arn" {
  description = "IAM role used by GitHub Actions for application deployment"
  value       = aws_iam_role.github_application.arn
}