# Define the AWS provider
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.36"
    }
  }
}

provider "aws" {
  profile = "tfuser"
  region  = "us-east-1"

   assume_role {
     role_arn = var.assume_role_arn
   }
}
