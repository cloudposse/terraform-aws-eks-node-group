terraform {
  required_version = ">= 0.13.3"
  experiments = [variable_validation]

  required_providers {
    aws      = ">= 3.0"
    template = ">= 2.0"
    local    = ">= 1.3"
    random   = ">= 2.0"
  }
}
