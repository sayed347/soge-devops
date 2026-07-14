terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70, < 6.0"
    }
  }

  backend "s3" {}
}

locals {
  default_tags = {
    Owner       = "demosg"
    Application = "sg-showcase-payment-orders"
    ManagedBy   = "terraform"
    Stack       = "40-edge"
    Environment = var.environment
  }
}

provider "aws" {
  region = "eu-west-3"

  default_tags {
    tags = local.default_tags
  }
}

# CloudFront and WAFv2 (scope CLOUDFRONT) are only manageable via the
# us-east-1 API, regardless of where the VPC/ALB they reference actually
# live.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.default_tags
  }
}

data "aws_caller_identity" "current" {}
