terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-backend-terraformbackends3bucket-fuz3u5yspci0"
    key            = "infraiim"
    region         = "eu-west-1"
    dynamodb_table = "terraform-backend-TerraformBackendDynamoDBTable-KTO4R4Y635QG"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.tags.Environment
      ManagedBy   = "Terraform"
      Repository  = "iim-cloud-project"
    }
  }
}