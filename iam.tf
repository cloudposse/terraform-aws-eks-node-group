locals {
  create_role           = local.enabled && length(var.node_role_arn) == 0
  aws_policy_prefix     = local.create_role ? format("arn:%s:iam::aws:policy", join("", data.aws_partition.current.*.partition)) : ""
  node_role_policy_arns = sort(var.node_role_policy_arns)
}

data "aws_partition" "current" {
  count = local.create_role ? 1 : 0
}

data "aws_iam_policy_document" "assume_role" {
  count = local.create_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "default" {
  count                = local.create_role ? 1 : 0
  name                 = module.label.id
  assume_role_policy   = join("", data.aws_iam_policy_document.assume_role.*.json)
  permissions_boundary = var.node_role_permissions_boundary
  tags                 = module.label.tags
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  count      = local.create_role ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEKSWorkerNodePolicy")
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  count      = local.create_role ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEC2ContainerRegistryReadOnly")
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "existing_policies_for_eks_workers_role" {
  count      = local.create_role ? length(var.node_role_policy_arns) : 0
  policy_arn = local.node_role_policy_arns[count.index]
  role       = join("", aws_iam_role.default.*.name)
}

# Create a CNI policy that is a merger of AmazonEKS_CNI_Policy and required IPv6 permissions
# https://github.com/SummitRoute/aws_managed_policies/blob/master/policies/AmazonEKS_CNI_Policy
# https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html#cni-iam-role-create-ipv6-policy
# https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html
data "aws_iam_policy_document" "ipv6_eks_cni_policy" {
  count = local.create_role && var.node_role_cni_policy_enabled || local.create_role && can(regex("WINDOWS", var.ami_type)) ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ec2:AssignIpv6Addresses",
      "ec2:AssignPrivateIpAddresses",
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeTags",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = [
      "arn:${join("", data.aws_partition.current.*.partition)}:ec2:*:*:network-interface/*"
    ]
  }
}

resource "aws_iam_policy" "ipv6_eks_cni_policy" {
  count = local.create_role && var.node_role_cni_policy_enabled ? 1 : 0

  name   = "${module.this.id}-CNI_Policy"
  policy = join("", data.aws_iam_policy_document.ipv6_eks_cni_policy.*.json)
}

resource "aws_iam_role_policy_attachment" "ipv6_eks_cni_policy" {
  count = local.create_role && var.node_role_cni_policy_enabled ? 1 : 0

  policy_arn = join("", aws_iam_policy.ipv6_eks_cni_policy.*.arn)
  role       = join("", aws_iam_role.default.*.name)
}

