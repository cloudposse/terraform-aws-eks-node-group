terraform {
  required_version = ">= 1.1.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # retrieve launch template by ID starts at 3.21.0
      # update_config starts at 3.56
      version = ">= 4.14"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
  }
}
