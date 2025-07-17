# This block says: "Yo Terraform, we need the AWS plugin"
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use AWS provider version 5.x
    }
  }

  # This says: Use Terraform version 1.3 or higher, like a baseline for the terraform version we'll use
  required_version = ">= 1.3.0"
}

# This says: "Hey AWS, work in the region we pick"
provider "aws" {
  region = var.aws_region # We'll define aws_region later in variables.tf, because we may need to summon that variable again and again.
}
