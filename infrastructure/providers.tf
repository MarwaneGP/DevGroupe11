terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.4.0"
    }
  }
  backend "s3" {
    bucket = "terraform-backend-terraformbackends3bucket-fuz3u5yspci0"
    key ="infraiim"
    region ="eu-west-1"
    dynamodb_table="terraform-backend-TerraformBackendDynamoDBTable-KTO4R4Y635QG"
  }
}

provider "aws" {
  region = "eu-west-1"
}
