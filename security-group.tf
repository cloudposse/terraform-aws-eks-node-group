# https://docs.aws.amazon.com/eks/latest/APIReference/API_RemoteAccessConfig.html

module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "0.3.1"

  use_name_prefix = var.security_group_use_name_prefix
  rules           = var.security_group_rules
  description     = var.security_group_description
  vpc_id          = local.vpc_id

  enabled    = local.need_remote_access_sg
  attributes = ["remote", "access"]
  context    = module.label.context
}
