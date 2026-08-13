# DevOps AWS CI/CD

A production-style DevOps project demonstrating containerized
application deployment on AWS using Terraform, Docker, GitHub Actions,
Amazon ECR, EC2, Nginx, AWS Systems Manager (SSM), and GitHub OIDC
authentication.

The project is designed as a realistic CI/CD environment rather than a
collection of unrelated tools. Infrastructure and application delivery
are separated, infrastructure is managed through Terraform and GitHub
Actions, application images are immutable Git-SHA tags, and deployments
include health verification, image tracking, manual rollback, and
automatic rollback.

------------------------------------------------------------------------

## Current Status

**Production-style application CI/CD pipeline completed and tested.**

Implemented and tested:

-   AWS infrastructure provisioned with Terraform.
-   Remote Terraform state stored in S3.
-   Terraform state locking using DynamoDB.
-   AWS region standardized to `ap-south-1` (Mumbai).
-   GitHub Actions authentication to AWS using OIDC.
-   Separate GitHub IAM roles for infrastructure and application
    workflows.
-   EC2 application host with IAM instance profile.
-   Amazon ECR repository for application images.
-   Dockerized Python/Flask application.
-   Production Docker Compose configuration.
-   Nginx reverse proxy.
-   Port 5000 blocked from the Internet; application exposed through
    Nginx on port 80.
-   Application CI/CD using GitHub Actions.
-   Docker image tagged with the Git commit SHA.
-   Docker image tested before being pushed to ECR.
-   Deployment to EC2 through AWS Systems Manager Run Command.
-   Production health checks after deployment.
-   `current_image_tag` and `previous_image_tag` tracking on EC2.
-   Manual application rollback workflow.
-   Automatic rollback when the production health check fails.
-   Automatic rollback tested successfully.
-   Manual rollback tested successfully.
-   Application deployment and recovery behavior verified end-to-end.

> **Important:** SSM is used for non-interactive deployment commands
> through `AWS-RunShellScript`. The project does not depend on an
> SSH-based deployment path.

------------------------------------------------------------------------

## Project Goals

The project was built to demonstrate the following real-world DevOps
practices:

1.  Infrastructure as Code instead of manually creating AWS resources.
2.  Remote Terraform state and state locking.
3.  CI/CD separation between infrastructure and application delivery.
4.  Short-lived AWS credentials through GitHub OIDC.
5.  Immutable Docker images identified by Git SHA.
6.  Automated application deployment.
7.  Production health verification.
8.  Manual and automatic rollback.
9.  Reproducible infrastructure.
10. Security-conscious networking and IAM.
11. A workflow that can be explained clearly in a DevOps interview.

------------------------------------------------------------------------

# Architecture

``` text
                         Developer
                             |
                             | git push
                             v
                    GitHub Repository
                    ANAGHANU/devops-aws-cicd
                             |
             +---------------+----------------+
             |                                |
             | Terraform changes              | app changes
             v                                v
      Terraform Workflow              Application CI/CD
             |                                |
          OIDC                              OIDC
             |                                |
             v                                v
       AWS IAM Role                    AWS IAM Role
             |                                |
             v                                v
      Terraform Plan                    Docker Build
             |                                |
      Terraform Apply                   Docker Test
             |                                |
             v                                v
       AWS Infrastructure                     ECR
             |                                |
             |                                v
             |                           SSM Run Command
             |                                |
             v                                v
       +------------- AWS --------------------------+
       |                                             |
       |  VPC                                        |
       |   |                                         |
       |   +-- Public Subnet                         |
       |          |                                  |
       |          +-- EC2                            |
       |                |                             |
       |                +-- Nginx :80                |
       |                |      |                      |
       |                |      v                      |
       |                |   Flask :5000               |
       |                |                             |
       |                +-- Docker Compose            |
       |                                             |
       +---------------------------------------------+
```

### Application request flow

``` text
Internet
   |
   | :80
   v
Nginx
   |
   | proxy_pass
   v
Flask application
   |
   | :5000
   v
/health
```

Port `5000` is not exposed to the Internet. It is only used internally
between Nginx and the application container.

------------------------------------------------------------------------

# Repository Structure

``` text
devops-aws-cicd/
│
├── app/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── docker-compose.prod.yml
│   └── nginx/
│       └── nginx.conf
│
├── bootstrap/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── ...
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── backend.tf
│   ├── terraform.tfvars.example
│   └── ...
│
├── .github/
│   └── workflows/
│       ├── terraform.yml
│       ├── application.yml
│       ├── rollback.yml
│       └── aws-oidc-test.yml
│
├── .gitignore
└── README.md
```

> Filenames may evolve during cleanup, but the architectural separation
> remains: bootstrap, infrastructure, application, and CI/CD workflows.

------------------------------------------------------------------------

# Technologies

-   Python / Flask
-   Docker
-   Docker Compose
-   Nginx
-   Terraform
-   AWS
-   Amazon ECR
-   Amazon EC2
-   Amazon VPC
-   Amazon S3
-   DynamoDB
-   AWS IAM
-   AWS Systems Manager
-   GitHub Actions
-   GitHub OIDC

------------------------------------------------------------------------

# AWS Region

The project uses:

``` text
ap-south-1
```

AWS region:

**Asia Pacific (Mumbai)**

All Terraform and CI/CD workflows are configured to use `ap-south-1`.

------------------------------------------------------------------------

# Dockerfile

``` dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

### Explanation

### `FROM python:3.12-slim`

Uses a lightweight Python image as the base.

### `WORKDIR /app`

Sets `/app` as the working directory inside the container.

### `COPY requirements.txt .`

Copies dependencies first.

This also improves Docker layer caching because dependency installation
does not need to be repeated when only application source code changes.

### `RUN pip install --no-cache-dir -r requirements.txt`

Installs Python dependencies without keeping pip's cache, reducing image
size.

### `COPY . .`

Copies the application source code into the container.

### `EXPOSE 5000`

Documents that the application listens on port `5000`.

### `CMD ["python", "app.py"]`

Starts the application when the container runs.

------------------------------------------------------------------------

# Docker Compose

The project uses separate development and production-oriented Compose
configurations.

## Production Compose

The production stack contains:

``` text
app
nginx
```

The Flask container:

-   pulls an immutable image from ECR.
-   exposes port `5000` internally.
-   uses a Docker health check.
-   restarts automatically.

Nginx:

-   uses `nginx:1.29-alpine`.
-   listens on port `80`.
-   proxies traffic to the Flask application.
-   waits for the application health condition.
-   restarts automatically.

The production image is selected using:

``` text
ECR_REGISTRY
ECR_REPOSITORY
IMAGE_TAG
```

Example:

``` text
340593397664.dkr.ecr.ap-south-1.amazonaws.com/devops-aws-cicd-app:<GIT_SHA>
```

This makes deployments immutable and traceable to a specific Git commit.

------------------------------------------------------------------------

# Nginx - Security Group

The intended network model is:

``` text
Internet
   |
   ├── :80  → allowed
   ├── :443 → allowed / reserved for HTTPS configuration
   |
   └── :5000 → blocked
```

The Flask application is therefore not directly accessible from the
Internet.

Traffic follows:

``` text
Internet
   ↓
Nginx :80
   ↓
Flask :5000
```

This provides a clean reverse-proxy boundary between the Internet and
the application container.

> If HTTPS is not configured yet, port `443` should not be described as
> an active application endpoint. It is reserved for future TLS
> configuration.

------------------------------------------------------------------------

# Public / Private Subnet

A **public subnet** has a route to an Internet Gateway, allowing
resources with public addressing to communicate with the Internet.

A **private subnet** does not have a direct route to an Internet
Gateway. It keeps resources away from direct inbound Internet access,
while outbound Internet access can be provided through a NAT Gateway or
equivalent.

For this project, the EC2 application host is currently deployed in a
public subnet because the project intentionally keeps the architecture
relatively small and interview-friendly.

The security group prevents direct access to the Flask port `5000`,
while Nginx receives public HTTP traffic.

A future production-hardening step could move the application host into
a private subnet and place a public load balancer/reverse proxy in front
of it.

------------------------------------------------------------------------

# Terraform

Terraform is the Infrastructure as Code layer.

Core commands:

``` bash
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

For destruction:

``` bash
terraform destroy
```

### Typical local validation

``` bash
cd terraform

terraform fmt -recursive
terraform validate
terraform plan
```

The long-term goal is for the main infrastructure `plan` and `apply`
operations to be owned by GitHub Actions rather than the developer's
local machine.

------------------------------------------------------------------------

# Terraform Remote State

Terraform state is stored remotely instead of using a local
`terraform.tfstate` as the authoritative state.

Architecture:

``` text
GitHub Actions
      |
terraform apply
      |
      v
S3
 |
 +-- Terraform state
 |
 +-- Version history
```

DynamoDB is used for state locking.

``` text
Terraform
   |
   +-- S3 → state
   |
   +-- DynamoDB → state locking
```

This prevents multiple Terraform operations from modifying the same
state simultaneously.

### S3 state bucket recommendations

The bootstrap state bucket should use:

-   unique bucket naming
-   `ap-south-1`
-   versioning
-   server-side encryption
-   public access blocking
-   appropriate ownership controls

S3 versioning provides recovery from accidental state-object overwrites
or deletions.

However, if the entire bootstrap bucket is intentionally destroyed
during a complete project teardown, its state history is also destroyed.
That is acceptable for the full rebuild test described later.

------------------------------------------------------------------------

# Bootstrap

The bootstrap layer exists because Terraform's main remote backend
cannot depend on an S3 bucket that does not yet exist.

The dependency is:

``` text
Bootstrap
   |
   +-- S3 state bucket
   |
   +-- DynamoDB lock table
   |
   +-- GitHub OIDC / Terraform authentication foundation
             |
             v
      Main Terraform
```

Therefore bootstrap is a separate initial step.

## Bootstrap lifecycle

``` bash
cd bootstrap

terraform init
terraform apply
```

After bootstrap succeeds, the main Terraform configuration can
initialize its remote backend.

The bootstrap should be small and stable. It should not contain
application resources.

------------------------------------------------------------------------

# OIDC

OIDC (OpenID Connect) is a secure, secretless authentication method that
lets GitHub Actions authenticate to AWS using short-lived credentials.

Instead of storing long-lived AWS access keys in GitHub:

``` text
GitHub Actions
      |
      v
GitHub OIDC token
      |
      v
AWS IAM trust policy
      |
      v
Short-lived AWS credentials
```

This eliminates the need to store permanent AWS access keys for CI/CD.

The project restricts the GitHub IAM trust relationship to the intended
repository and `main` branch.

### Important distinction

The OIDC IAM role used by the main Terraform workflow is itself AWS
infrastructure. Therefore, a complete rebuild requires a bootstrap
mechanism that can recreate the authentication foundation before the
main Terraform workflow runs.

------------------------------------------------------------------------

# Bootstrap Authentication

Bootstrap is the initial trust-establishment phase.

A common bootstrap model is:

``` text
Administrator / controlled bootstrap credentials
                 |
                 v
       Create baseline IAM/OIDC
                 |
                 v
       GitHub Actions OIDC
                 |
                 v
       Short-lived credentials
```

Bootstrap credentials should be treated as highly sensitive and
temporary where possible.

They should not become the normal CI/CD authentication mechanism.

The production CI/CD path should use OIDC and short-lived credentials
rather than permanent AWS access keys.

------------------------------------------------------------------------

# IAM Design

The project separates responsibilities between AWS identities.

Conceptually:

``` text
GitHub OIDC
    |
    +---- Terraform role
    |       |
    |       +-- Infrastructure management
    |
    +---- Application role
            |
            +-- ECR push
            +-- EC2 discovery
            +-- SSM deployment commands
```

The EC2 instance has a separate IAM role for actions required by the
application host, including pulling its image from ECR and participating
in the deployment mechanism.

The goal is least privilege: each identity should have only the
permissions required for its role.

------------------------------------------------------------------------

# `.example` Files and Secrets

A `.example` file is a safe template.

For example:

``` text
terraform.tfvars.example
```

contains the expected configuration structure without real secrets or
environment-specific sensitive values.

The developer creates:

``` text
terraform.tfvars
```

locally with the actual values.

The relationship is:

``` text
terraform.tfvars.example
        |
        | copy / reference
        v
terraform.tfvars
        |
        v
.gitignore
        |
        v
Prevents accidental commit
```

The actual `terraform.tfvars` should not be committed if it contains
sensitive or environment-specific values.

------------------------------------------------------------------------

# `.gitignore`

The `.gitignore` protects local Terraform state and configuration from
accidental commits.

Typical protected items include:

``` text
*.tfstate
*.tfstate.*
.terraform/
terraform.tfvars
*.tfplan
crash.log
```

The remote S3 backend remains the authoritative Terraform state location
for the main infrastructure.

------------------------------------------------------------------------

# CI/CD Design

There are two independent pipelines.

``` text
                 Git Push
                    |
          +---------+---------+
          |                   |
          v                   v
 Terraform changes?      Application changes?
          |                   |
          v                   v
 Terraform workflow      Application workflow
```

This avoids rebuilding the application when only infrastructure changes
and avoids running Terraform when only application code changes.

------------------------------------------------------------------------

# Infrastructure Pipeline

Workflow:

``` text
.github/workflows/terraform.yml
```

The intended trigger is based on Terraform changes, for example:

``` yaml
on:
  push:
    paths:
      - "terraform/**"

  workflow_dispatch:
```

Pipeline:

``` text
Git Push
   |
Terraform files changed?
   |
  Yes
   |
terraform fmt
   |
terraform validate
   |
terraform plan
   |
terraform apply
```

The infrastructure pipeline does not build Docker images and does not
deploy the application.

------------------------------------------------------------------------

# Application Pipeline

Workflow:

``` text
.github/workflows/application.yml
```

Application changes trigger the workflow:

``` yaml
on:
  push:
    branches:
      - main
    paths:
      - "app/**"

  workflow_dispatch:
```

Pipeline:

``` text
Checkout
   |
Set Git SHA image tag
   |
Configure AWS OIDC
   |
Login to ECR
   |
Build Docker image
   |
Test Docker image
   |
Push image to ECR
   |
Discover EC2
   |
SSM Run Command
   |
Deploy with Docker Compose
   |
Production health check
```

------------------------------------------------------------------------

# Immutable Image Tagging

The Docker image is tagged using:

``` text
GITHUB_SHA
```

Example:

``` text
74fe94020105b278a84c032772f3e86f69bd931e
```

The resulting ECR image is:

``` text
340593397664.dkr.ecr.ap-south-1.amazonaws.com/devops-aws-cicd-app:74fe94020105b278a84c032772f3e86f69bd931e
```

This provides:

-   traceability
-   reproducibility
-   easy rollback
-   no ambiguity caused by a mutable `latest` tag

A deployment can therefore answer:

> Which exact Git commit is currently running in production?

------------------------------------------------------------------------

# Docker Image Test

Before pushing the image to ECR, GitHub Actions starts the image
locally:

``` bash
docker run -d \
  --name devops-app-test \
  -p 5000:5000 \
  IMAGE
```

Then:

``` bash
curl --fail http://localhost:5000/health
```

If the health endpoint fails, the image is not pushed to ECR and the
deployment does not continue.

This provides an application-level CI gate before production deployment.

------------------------------------------------------------------------

# Deployment to EC2

The application workflow uses AWS Systems Manager Run Command rather
than an SSH-based deployment.

Flow:

``` text
GitHub Actions
      |
      v
AWS OIDC
      |
      v
Application IAM Role
      |
      v
SSM SendCommand
      |
      v
EC2
      |
      +-- Docker login to ECR
      +-- Pull image
      +-- Docker Compose up
      +-- Health check
```

The workflow transfers the production Compose configuration and Nginx
configuration to:

``` text
/opt/devops-aws-cicd/
```

The application is then started with:

``` bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --remove-orphans
```

------------------------------------------------------------------------

# Production Health Check

The application exposes:

``` text
/health
```

Expected response:

``` json
{"status":"healthy"}
```

The production deployment waits for the health check before considering
the deployment successful.

The health-check loop retries for a limited period rather than
immediately failing on the first unsuccessful request.

------------------------------------------------------------------------

# Image Version Tracking

The EC2 host keeps two small tracking files:

``` text
/opt/devops-aws-cicd/current_image_tag
/opt/devops-aws-cicd/previous_image_tag
```

Example:

``` text
current_image_tag
    |
    +-- 74fe940...

previous_image_tag
    |
    +-- 1a123f4...
```

Before a normal deployment:

``` text
current → previous
```

After a successful deployment:

``` text
current → new Git SHA
```

This provides a simple record of the currently deployed image and the
immediately preceding image.

------------------------------------------------------------------------

# Manual Rollback

Workflow:

``` text
.github/workflows/rollback.yml
```

It is manually triggered using:

``` yaml
workflow_dispatch:
```

Rollback process:

``` text
Run rollback workflow
       |
Read previous_image_tag
       |
Pull that immutable ECR image
       |
Docker Compose deployment
       |
Health check
       |
Swap current/previous tracking
```

A rollback was successfully tested in this project.

Example:

``` text
Before:
current  = 74fe940...
previous = 1a123f4...

Rollback:

current  = 1a123f4...
previous = 74fe940...
```

------------------------------------------------------------------------

# Automatic Rollback

The application deployment also contains automatic rollback logic.

Normal deployment:

``` text
New image
   |
Deploy
   |
Health check
   |
   +-- PASS → SUCCESS
   |
   +-- FAIL
          |
          v
   Read known-good current image
          |
          v
   Redeploy known-good image
          |
          v
   Health check
          |
          +-- PASS → application restored
          |
          +-- FAIL → deployment failure
```

The workflow intentionally remains failed if the new deployment fails,
even if automatic recovery succeeds.

This is important because:

``` text
Deployment requested = failed
Application recovery = successful
```

The pipeline should not falsely report the failed release as successful.

Automatic rollback was deliberately tested with a controlled production
failure and successfully restored the application.

------------------------------------------------------------------------

# Rollback Test

The project tested automatic rollback using a controlled failure
introduced into the deployment process.

Expected behavior:

``` text
New deployment
      |
      v
Production health check fails
      |
      v
Automatic rollback starts
      |
      v
Previous known-good image deployed
      |
      v
Rollback health check passes
      |
      v
Application restored
```

The temporary failure mechanism was removed after the test.

------------------------------------------------------------------------

# Infrastructure Fully Reproducible

The intended final lifecycle is:

``` text
                 GitHub Repository
                        |
                        v
                  Bootstrap
                        |
          +-------------+-------------+
          |                           |
          v                           v
     S3 state                    DynamoDB lock
          |
          v
    GitHub OIDC foundation
          |
          v
   Terraform GitHub Actions
          |
          v
     AWS Infrastructure
          |
          v
   Application CI/CD
          |
          v
     ECR + EC2 + Nginx
```

A complete teardown/rebuild can therefore be performed.

## Full teardown

First destroy the main infrastructure:

``` bash
cd terraform
terraform destroy
```

Then destroy the bootstrap resources:

``` bash
cd ../bootstrap
terraform destroy
```

This intentionally removes the remote Terraform state backend and lock
table as part of a complete project shutdown.

## Full rebuild

Later:

``` bash
git clone https://github.com/ANAGHANU/devops-aws-cicd.git
cd devops-aws-cicd
```

Run bootstrap manually:

``` bash
cd bootstrap
terraform init
terraform apply
```

Verify:

-   S3 state bucket exists.
-   S3 versioning/encryption is configured.
-   DynamoDB lock table exists.
-   GitHub OIDC foundation exists.
-   Terraform GitHub IAM role can be assumed.

Run the OIDC test workflow.

Then run the Terraform workflow:

``` text
GitHub Actions
      |
Terraform init
      |
Terraform fmt
      |
Terraform validate
      |
Terraform plan
      |
Terraform apply
```

Then run the Application CI/CD workflow.

This is the intended proof that the infrastructure can be recreated from
the Git repository rather than relying on undocumented manual AWS
configuration.

------------------------------------------------------------------------

# Branch Synchronization

When `testbranch` needs the latest changes from `main`:

``` bash
git fetch origin
git checkout testbranch
git merge origin/main
git push origin testbranch
```

This brings the latest changes from `main` into `testbranch` while
preserving commits that were already unique to `testbranch`.

------------------------------------------------------------------------

# Useful Commands

## Git

``` bash
git status
git add .
git commit -m "message"
git push origin main
git pull
git fetch origin
git checkout testbranch
git merge origin/main
git push origin testbranch
```

## Terraform

``` bash
cd terraform

terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform destroy
terraform output
```

## Bootstrap

``` bash
cd bootstrap

terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform destroy
```

## Docker

``` bash
docker build -t devops-aws-cicd-app .
docker images
docker ps
docker logs <container>
```

## Docker Compose

``` bash
docker compose up -d
docker compose ps
docker compose logs
docker compose down
```

Production:

``` bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --remove-orphans
docker compose -f docker-compose.prod.yml ps
```

------------------------------------------------------------------------

# Important Project Lessons / Points to Remember

### 1. Separate infrastructure from application delivery

Terraform should manage infrastructure.

Application CI/CD should build and deploy application images.

Don't mix:

``` text
Terraform → Docker build → ECR → application deployment
```

into one giant workflow.

### 2. Remote Terraform state is mandatory for shared CI/CD

A GitHub Actions runner is ephemeral.

Local state cannot be the authoritative state for a shared
infrastructure pipeline.

Use:

``` text
S3 + DynamoDB
```

for the remote backend and locking.

### 3. Bootstrap is a dependency

The backend bucket cannot be created by the Terraform configuration that
requires the bucket during `terraform init`.

Therefore bootstrap must be separate.

### 4. OIDC is preferable to long-lived AWS keys

The target CI/CD authentication model is:

``` text
GitHub
   ↓
OIDC
   ↓
IAM role
   ↓
temporary credentials
```

rather than storing:

``` text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

as permanent GitHub secrets.

### 5. Don't use `latest` for production deployments

Use Git SHA tags:

``` text
IMAGE_TAG=$GITHUB_SHA
```

This makes the deployed version identifiable and rollbackable.

### 6. Health checks are part of deployment

A deployment is not successful merely because:

``` bash
docker compose up -d
```

returns successfully.

The application must actually answer:

``` text
/health
```

### 7. Rollback must restore the application, not just change a file

The rollback process must:

``` text
pull image
↓
start containers
↓
verify health
```

### 8. Don't over-engineer

The project intentionally uses:

``` text
Terraform
Docker
ECR
EC2
Nginx
GitHub Actions
OIDC
SSM
```

It does not add Kubernetes, Jenkins, Argo CD, or other tools merely to
increase the tool count.

The architecture should remain explainable and defensible.

------------------------------------------------------------------------

# Known Design Limitations / Future Improvements

The current project is intentionally designed around a single EC2 host.

Potential future improvements:

-   HTTPS with ACM.
-   Application Load Balancer.
-   Private application subnet.
-   NAT Gateway where required.
-   Auto Scaling Group.
-   Multiple EC2 instances.
-   Centralized logging.
-   CloudWatch monitoring and alarms.
-   Secrets Manager / Parameter Store.
-   ECR lifecycle policies.
-   More granular IAM permissions.
-   Deployment history beyond the immediate previous image.
-   Blue/green or canary deployments.
-   Terraform module separation.
-   Automated infrastructure drift detection.
-   GitHub environment protection and approvals.
-   Automated integration testing.

These are potential production-hardening improvements, not requirements
for the current project.

------------------------------------------------------------------------

# Resume Points

Use concise points on the resume rather than listing every
implementation detail.

### Option 1 --- Strong technical version

-   Built a production-style AWS CI/CD platform using **Terraform,
    Docker, GitHub Actions, Amazon ECR, EC2, Nginx, and AWS OIDC**, with
    infrastructure and application pipelines separated by path-based
    triggers.
-   Implemented **immutable Git-SHA Docker releases, production health
    checks, SSM-based deployment, and automatic/manual rollback**,
    enabling recovery to the last known-good application version.

### Option 2 --- More infrastructure-focused

-   Provisioned AWS networking, EC2, ECR, IAM, and remote Terraform
    state using **Infrastructure as Code**, with GitHub Actions managing
    Terraform plan/apply through **OIDC-based short-lived AWS
    credentials**.
-   Built a containerized Flask deployment behind Nginx with **ECR-based
    image delivery, health verification, version tracking, and tested
    automatic rollback**.

------------------------------------------------------------------------

# Interview Project Explanation

## 30-second version

> "I built a production-style AWS CI/CD project where Terraform manages
> the infrastructure and GitHub Actions handles the delivery pipeline.
> The application is a Dockerized Flask service running on EC2 behind
> Nginx, with images stored in ECR. GitHub Actions authenticates to AWS
> using OIDC instead of long-lived access keys. Application images are
> tagged with the Git SHA, tested before being pushed to ECR, deployed
> to EC2 through SSM, and verified with a production health check. I
> also implemented and tested both manual and automatic rollback to the
> last known-good image."

## 1-minute version

> "The project is split into two pipelines. The infrastructure pipeline
> runs when Terraform changes and performs formatting, validation, plan,
> and apply. The application pipeline runs when application files
> change. It builds the Flask Docker image, runs a health test, pushes
> the immutable Git-SHA image to ECR, and deploys it to EC2 through AWS
> Systems Manager. Nginx acts as the reverse proxy, so port 5000 isn't
> exposed directly to the Internet.
>
> For security, GitHub Actions uses OIDC to assume restricted IAM roles
> and receive short-lived AWS credentials. Terraform state is stored
> remotely in S3 with DynamoDB locking. On the EC2 host, the deployment
> tracks the current and previous image SHA. I implemented both a manual
> rollback workflow and automatic rollback when the production health
> check fails, and I deliberately tested both recovery paths."

------------------------------------------------------------------------

# Interview Questions You Should Be Ready For

### Why Terraform?

Because infrastructure should be version-controlled, repeatable,
reviewable, and reproducible rather than manually configured.

### Why remote state?

Because GitHub Actions runners are ephemeral and multiple infrastructure
operations need a shared authoritative state.

### Why S3?

It provides durable remote storage for Terraform state and supports
versioning and encryption.

### Why DynamoDB?

It provides state locking so concurrent Terraform operations don't
modify the same state simultaneously.

### Why OIDC?

It removes the need for long-lived AWS access keys in GitHub and
provides short-lived credentials through an IAM trust relationship.

### Why ECR?

It provides a private AWS container registry integrated with IAM and
EC2.

### Why Git SHA instead of `latest`?

A Git SHA provides immutable, traceable releases and makes rollback
deterministic.

### Why Nginx?

It provides a reverse-proxy boundary and prevents the Flask application
port from being directly exposed to the Internet.

### Why SSM instead of SSH?

It avoids managing SSH keys for CI/CD deployment and allows GitHub
Actions to execute controlled commands on the EC2 instance through AWS
Systems Manager.

### How does rollback work?

The deployment records the currently running image before replacing it.
If the new version fails the production health check, the pipeline
redeploys the previously known-good image and verifies that the
application becomes healthy again.

### What happens if automatic rollback also fails?

The workflow remains failed and reports the rollback failure. The
application requires investigation rather than falsely reporting a
successful deployment.

### Why separate Terraform and application pipelines?

Infrastructure changes shouldn't trigger application builds, and
application changes shouldn't unnecessarily run Terraform.

### How is the infrastructure reproducible?

The AWS resources are defined in Terraform and stored in Git. The
remote-state/OIDC foundation is created by a separate bootstrap step.
After bootstrap, the infrastructure can be recreated through the
Terraform GitHub Actions workflow.

------------------------------------------------------------------------

# Final Architecture Summary

``` text
                         GitHub
                           |
              +------------+------------+
              |                         |
              v                         v
       Terraform changes          App changes
              |                         |
              v                         v
       Terraform Workflow        Application Workflow
              |                         |
             OIDC                      OIDC
              |                         |
              v                         v
        AWS IAM Role               AWS IAM Role
              |                         |
              v                         v
       Terraform Plan             Docker Build
              |                         |
       Terraform Apply              Test Image
              |                         |
              v                         v
        AWS Infrastructure              ECR
                                        |
                                        v
                                   SSM RunCommand
                                        |
                                        v
                                       EC2
                                        |
                               +--------+--------+
                               |                 |
                              Nginx             Docker
                               |                 |
                               +------> Flask <---+
                                        |
                                        v
                                     /health

              Deployment failure
                       |
                       v
               Automatic rollback
                       |
                       v
              Previous Git SHA
                       |
                       v
                 Health check
```

------------------------------------------------------------------------

# Project Outcome

This project demonstrates an end-to-end DevOps workflow rather than
isolated technology usage:

``` text
Infrastructure as Code
        +
Cloud security
        +
Containerization
        +
CI/CD
        +
Immutable releases
        +
Production verification
        +
Rollback
        +
Reproducibility
```

The strongest part of the project is not the number of tools used. It is
the complete delivery lifecycle:

``` text
Git commit
   ↓
CI
   ↓
Docker image
   ↓
ECR
   ↓
CD
   ↓
EC2
   ↓
Nginx
   ↓
Health check
   ↓
Production
   ↓
Automatic/manual recovery
```
