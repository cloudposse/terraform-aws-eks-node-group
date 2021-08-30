terraform {
  required_version = ">= 0.14.11"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # retrieve launch template by ID starts at 3.21.0
      # update_config starts at 3.56
      version = ">= 3.56"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 1.3"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
  }
}
