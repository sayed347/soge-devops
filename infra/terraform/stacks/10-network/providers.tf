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
      Stack       = "10-network"
      Environment = var.environment
    }
  }
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}
