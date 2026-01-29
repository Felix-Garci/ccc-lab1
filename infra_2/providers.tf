terraform {
  required_version = ">= 1.14"
  backend "s3" {
    bucket = "tf-state-899311789148-us-east-1"
    key   = "lab1_2/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true 
    shared_credentials_files = ["./credentials"]
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  shared_credentials_files = ["./credentials"]
}

