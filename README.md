# DevOps AWS CI/CD

A production-style DevOps project demonstrating containerized application
deployment on AWS using Terraform, Docker, GitHub Actions, Amazon ECR,
EC2, Nginx, and GitHub OIDC authentication.

## Current Status

Application foundation.

## Architecture

Coming soon.

## Technologies

- Python / Flask
- Docker
- Nginx
- Terraform
- AWS
- Amazon ECR
- Amazon EC2
- GitHub Actions
- GitHub OIDC

## Dockerfile

FROM python:3.12-slim

Uses a lightweight Python image as the base.

WORKDIR /app

Sets /app as the working directory inside the container.

COPY requirements.txt .

Copies dependencies first.

RUN pip install --no-cache-dir -r requirements.txt

Installs Python dependencies without keeping pip's cache, reducing image size.

COPY . .

Copies the application source code into the container.

EXPOSE 5000

Documents that the application listens on port 5000.

CMD ["python", "app.py"]

Starts the application when the container runs.

## Ngix - Security Group:

Internet
   │
   ├── :80  → allowed
   ├── :443 → allowed
   │
   └── :5000 → blocked

So the Flask application isn't directly accessible from the Internet.

## OIDC

OIDC (OpenID Connect) is a secure, secretless authentication method that lets GitHub Actions deploy to AWS using short-lived tokens. It completely eliminates the need to store long-lived AWS Access Keys, removing the risk of leaked credentials. Every time your pipeline runs, GitHub and AWS automatically generate and destroy these temporary keys behind the scenes.

## Bootstap

IAM Bootstrap is the initial process of using a master account or long-lived admin keys to manually set up your baseline cloud infrastructure and OIDC trust. It requires creating permanent credentials that must be tightly secured, stored, and rotated manually. While necessary for the very first deployment, it introduces a permanent leak risk if those bootstrap keys are ever exposed.

## .example = safe template

Developer sees the .example, creates own terraform.tfvars
.tfvars = actual local configuration
.gitignore = protection against accidentally committing the actual configuration

## Public/Private Subnet

A public subnet has a direct route to an Internet Gateway, allowing two-way communication with the public internet. A private subnet has no direct internet route, keeping resources hidden from external threats, though it can use a NAT device for outbound-only updates.

## Terraform

terraform fmt -recursive
terraform validate
terraform plan
terraform apply

