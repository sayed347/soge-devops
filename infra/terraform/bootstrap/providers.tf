terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Bootstrap can't use the S3/DynamoDB backend it is itself creating —
  # deliberately kept on local state (gitignored). Every other stack uses
  # the remote backend that THIS stack outputs.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner       = "demosg"
      Application = "sg-showcase-payment-orders"
      ManagedBy   = "terraform"
      Stack       = "bootstrap"
    }
  }
}

provider "github" {
  owner = var.github_owner
  # token read from the GITHUB_TOKEN env var — never hardcode it here
}

data "aws_caller_identity" "current" {}
