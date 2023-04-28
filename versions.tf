terraform {
  required_version = ">= 0.14.11"

  required_providers {
    aws = {
      # retrieve launch template by ID starts at 3.21.0
      # update_config starts at 3.56
      # Windows support starts at 4.48 https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md#4480-december-19-2022
      source  = "hashicorp/aws"
      version = ">= 4.48"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
  }
}
