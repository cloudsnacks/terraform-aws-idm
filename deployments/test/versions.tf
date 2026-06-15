terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }

  # Local state for the throwaway test deployment. Swap for an S3 backend
  # if you want to share/persist it.
  backend "local" {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "terraform-aws-idm"
      Env       = "test"
      ManagedBy = "terraform"
    }
  }
}
