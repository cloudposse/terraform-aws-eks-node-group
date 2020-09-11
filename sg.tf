# https://docs.aws.amazon.com/eks/latest/APIReference/API_RemoteAccessConfig.html

resource "aws_security_group" "remote_access" {
  count       = local.launch_template_create_remote_access_sg ? 1 : 0
  name        = "eks-${var.cluster_name}-${module.label.id}-remote-access"
  description = "Security group for all nodes in the nodeGroup to allow SSH access"
  vpc_id      = data.aws_subnet.default[0].vpc_id
  tags        = module.label.tags
}

resource "aws_security_group_rule" "remote_access_public_ssh" {
  count             = local.launch_template_create_remote_access_sg && length(var.source_security_group_ids) < 1 ? 1 : 0
  from_port         = 22
  protocol          = "tcp"
  security_group_id = join("", aws_security_group.remote_access.*.id)
  to_port           = 22
  type              = "ingress"

  cidr_blocks = [
    "0.0.0.0/0"
  ]
}

resource "aws_security_group_rule" "remote_access_source_sgs_ssh" {
  count                    = local.launch_template_create_remote_access_sg ? length(var.source_security_group_ids) : 0
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.remote_access[0].id
  to_port                  = 22
  source_security_group_id = var.source_security_group_ids[count.index]
  type                     = "ingress"
}
