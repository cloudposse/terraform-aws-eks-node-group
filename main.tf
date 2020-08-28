locals {
  enabled = module.this.enabled

  node_group_tags = merge(
    module.label.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
    {
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    },
    {
      "k8s.io/cluster-autoscaler/enabled" = "${var.enable_cluster_autoscaler}"
    }
  )
  aws_policy_prefix = format("arn:%s:iam::aws:policy", join("", data.aws_partition.current.*.partition))

  # Use a custom launch_template if one was passed as an input
  # Otherwise, use the default in this project
  launch_template = {
    id             = coalesce(var.launch_template_id, aws_launch_template.default[0].id)
    latest_version = coalesce(var.launch_template_version, aws_launch_template.default[0].latest_version)
  }
}

module "label" {
  source = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.19.2"

  # Using attributes = ["workers"] would put "workers" before any user-specified attributes.
  # While that might be preferable (adding an attribute "blue" would create
  # ...name-workers-blue instead of ...name-blue-workers), historically we forced "workers"
  # to the end of the attribute list, so we do it again here to maintain compatibility.
  attributes = compact(concat(module.this.attributes, ["workers"]))
  tags       = var.tags

  context = module.this.context
}

data "aws_partition" "current" {
  count = local.enabled ? 1 : 0
}

data "aws_iam_policy_document" "assume_role" {
  count = local.enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "amazon_eks_worker_node_autoscaler_policy" {
  count = (local.enabled && var.enable_cluster_autoscaler) ? 1 : 0
  statement {
    sid = "AllowToScaleEKSNodeGroupAutoScalingGroup"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "amazon_eks_worker_node_autoscaler_policy" {
  count  = (local.enabled && var.enable_cluster_autoscaler) ? 1 : 0
  name   = "${module.label.id}-autoscaler"
  path   = "/"
  policy = join("", data.aws_iam_policy_document.amazon_eks_worker_node_autoscaler_policy.*.json)
}

resource "aws_iam_role" "default" {
  count              = local.enabled ? 1 : 0
  name               = module.label.id
  assume_role_policy = join("", data.aws_iam_policy_document.assume_role.*.json)
  tags               = module.label.tags
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  count      = local.enabled ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEKSWorkerNodePolicy")
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_autoscaler_policy" {
  count      = (local.enabled && var.enable_cluster_autoscaler) ? 1 : 0
  policy_arn = join("", aws_iam_policy.amazon_eks_worker_node_autoscaler_policy.*.arn)
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  count      = local.enabled ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEKS_CNI_Policy")
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  count      = local.enabled ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEC2ContainerRegistryReadOnly")
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "existing_policies_for_eks_workers_role" {
  count      = local.enabled ? var.existing_workers_role_policy_arns_count : 0
  policy_arn = var.existing_workers_role_policy_arns[count.index]
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_launch_template" "default" {
  # We'll use this default if we aren't provided with a launch template during invocation
  count = (var.enabled && (var.launch_template_id == null)) ? 1 : 0
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.disk_size
    }
  }

  instance_type = var.instance_type

  dynamic "tag_specifications" {
    for_each = ["instance", "volume", "elastic-gpu"]
    content {
      resource_type = tag_specifications.value
      tags          = local.node_group_tags
    }
  }

  # Override the default userdata if input is provided
  # If none is provided, this value defaults to 'null', which defaults to the typical EKS node group userdata
  user_data = var.launch_template_user_data
}

resource "aws_eks_node_group" "default" {
  count           = local.enabled ? 1 : 0
  cluster_name    = var.cluster_name
  node_group_name = module.label.id
  node_role_arn   = join("", aws_iam_role.default.*.arn)
  subnet_ids      = var.subnet_ids
  ami_type        = var.ami_type
  labels          = var.kubernetes_labels
  release_version = var.ami_release_version
  version         = var.kubernetes_version

  tags = local.node_group_tags

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  launch_template {
    id      = local.launch_template.id
    version = local.launch_template.latest_version
  }

  dynamic "remote_access" {
    for_each = var.ec2_ssh_key != null && var.ec2_ssh_key != "" ? ["true"] : []
    content {
      ec2_ssh_key               = var.ec2_ssh_key
      source_security_group_ids = var.source_security_group_ids
    }
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_worker_node_autoscaler_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    # Also allow calling module to create an explicit dependency
    # This is useful in conjunction with terraform-aws-eks-cluster to ensure
    # the cluster is fully created and configured before creating any node groups
    var.module_depends_on
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
