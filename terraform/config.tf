terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}

# Configure S3 backend for tfstate
terraform {
  backend "s3" {
    bucket         = "tfstate-bucket-v1"
    key            = "infra.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tfstate-lock"
  }
}
