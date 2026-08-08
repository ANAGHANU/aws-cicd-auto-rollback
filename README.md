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