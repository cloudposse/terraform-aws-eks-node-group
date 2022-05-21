# https://docs.aws.amazon.com/eks/latest/APIReference/API_RemoteAccessConfig.html

module "ssh_access" {
  count   = local.need_ssh_access_sg ? 1 : 0
  source  = "cloudposse/security-group/aws"
  version = "1.0.1"

  attributes = ["ssh"]

  security_group_description = "Allow SSH access to nodes"
  create_before_destroy      = true

  rule_matrix = [{
    key                       = "ssh"
    source_security_group_ids = var.ssh_access_security_group_ids
    #bridgecrew:skip=BC_AWS_NETWORKING_1:Skipping `Port Security 0.0.0.0:0 to 22` check because we want to allow SSH access to all nodes in the nodeGroup
    cidr_blocks = length(var.ssh_access_security_group_ids) == 0 ? ["0.0.0.0/0"] : []
    rules = [{
      key         = "ssh"
      type        = "ingress"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      description = "Allow SSH ingress"
      },
      {
        key         = "ssh-egress"
        type        = "egress"
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        description = "Allow SSH egress"
    }]
  }]

  vpc_id = data.aws_eks_cluster.this[0].vpc_config[0].vpc_id

  context = module.this.context
}
