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

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  count      = local.create_role && var.node_role_cni_policy_enabled ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEKS_CNI_Policy")
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
