# Throwaway stack — validates that GitHub Actions can really assume the
# OIDC roles and read/write the S3+DynamoDB state backend. No AWS resource
# is created (random_pet only), so there's nothing to clean up in AWS beyond
# the state file itself. Delete this whole directory once infra-plan has
# gone green for real (not just "0 environments, skipped").
terraform {
  required_version = ">= 1.7"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {}
}

provider "random" {}
