
# Terraform & Provider Configuration


terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "vela-terraform-state-YOUR_SUFFIX" # REPLACE with your unique bucket name
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "vela-terraform-locks" # REPLACE with your DynamoDB table name (Partition key: LockID)
  }
}

provider "aws" {
  region = var.aws_region
}
