terraform {
  required_version = ">= 0.13.3"

  required_providers {
    aws      = ">= 2.0, < 4.0"
    template = ">= 2.0"
    local    = ">= 1.3"
    random   = ">= 2.0"
  }
}
