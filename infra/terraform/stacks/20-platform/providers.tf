terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = "eu-west-3"

  default_tags {
    tags = {
      Owner       = "demosg"
      Application = "sg-showcase-payment-orders"
      ManagedBy   = "terraform"
      Stack       = "20-platform"
      Environment = var.environment
    }
  }
}

data "aws_caller_identity" "current" {}

# Referenced by name, not passed through SSM from bootstrap — these role
# names are a fixed convention for this project. Needed here only to grant
# them explicit access in the KMS key policy below.
data "aws_iam_role" "plan" {
  name = "sg-showcase-ci-plan"
}

data "aws_iam_role" "deploy" {
  name = "sg-showcase-ci-deploy"
}
