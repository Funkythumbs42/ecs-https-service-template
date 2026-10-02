terraform {
  required_version = ">= 1.10.0" # S3-native state locking (use_lockfile)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Partial configuration: bucket/key/region are supplied per environment with
  #   terraform init -backend-config=envs/<env>.backend.hcl
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Service     = var.service_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
