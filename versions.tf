terraform {
  required_version = ">= 0.15.00"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
  }
}
