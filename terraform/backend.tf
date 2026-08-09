terraform {
  backend "s3" {
    bucket       = "devops-aws-cicd-terraform-state-testing01"
    key          = "devops-aws-cicd/prod/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}