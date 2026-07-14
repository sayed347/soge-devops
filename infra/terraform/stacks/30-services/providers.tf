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
      Stack       = "30-services"
      Environment = var.environment
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
