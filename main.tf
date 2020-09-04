locals {
  enabled = module.this.enabled

  configured_launch_template_name    = var.launch_template_name == null ? "" : var.launch_template_name
  configured_launch_template_version = length(local.configured_launch_template_name) > 0 && length(compact([var.launch_template_version])) > 0 ? var.launch_template_version : ""

  configured_ami_image_id = var.ami_image_id == null ? "" : var.ami_image_id

  # See https://aws.amazon.com/blogs/containers/introducing-launch-template-and-custom-ami-support-in-amazon-eks-managed-node-groups/
  features_require_ami = local.need_bootstrap
  need_ami_id          = local.features_require_ami && length(local.configured_ami_image_id) == 0

  features_require_launch_template = length(var.resources_to_tag) > 0 || local.need_userdata || local.features_require_ami
  generate_launch_template         = local.features_require_launch_template && length(local.configured_launch_template_name) == 0
  use_launch_template              = local.features_require_launch_template || length(local.configured_launch_template_name) > 0

  launch_template_id  = local.use_launch_template ? (length(local.configured_launch_template_name) > 0 ? data.aws_launch_template.this[0].id : aws_launch_template.default[0].id) : ""
  launch_template_ami = length(local.configured_ami_image_id) == 0 ? (local.features_require_ami ? data.aws_ami.selected[0].image_id : null) : local.configured_ami_image_id

  autoscaler_enabled_tags = {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"             = "true"
  }
  autoscaler_kubernetes_label_tags = {
    for label, value in var.kubernetes_labels : format("k8s.io/cluster-autoscaler/node-template/label/%v", label) => value
  }
  autoscaler_kubernetes_taints_tags = {
    for label, value in var.kubernetes_taints : format("k8s.io/cluster-autoscaler/node-template/taint/%v", label) => value
  }
  autoscaler_tags = merge(local.autoscaler_enabled_tags, local.autoscaler_kubernetes_label_tags, local.autoscaler_kubernetes_taints_tags)

  node_tags = merge(
    module.label.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
  node_group_tags = merge(local.node_tags, var.enable_cluster_autoscaler ? local.autoscaler_tags : {})

  aws_policy_prefix = format("arn:%s:iam::aws:policy", join("", data.aws_partition.current.*.partition))

  get_cluster_data = local.enabled && (local.need_cluster_kubernetes_version || local.need_bootstrap)
}

data "aws_eks_cluster" "this" {
  count = local.get_cluster_data ? 1 : 0
  name  = var.cluster_name
}



module "label" {
  source = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.19.2"

  # Using attributes = ["workers"] would put "workers" before any user-specified attributes.
  # While that might be preferable (adding an attribute "blue" would create
  # ...name-workers-blue instead of ...name-blue-workers), historically we forced "workers"
  # to the end of the attribute list, so we do it again here to maintain compatibility.
  attributes = compact(concat(module.this.attributes, ["workers"]))

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
  count = (local.enabled && local.generate_launch_template) ? 1 : 0

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.disk_size
    }
  }

  name_prefix            = module.label.id
  update_default_version = true

  instance_type = var.instance_types[0]
  image_id      = local.launch_template_ami

  dynamic "tag_specifications" {
    for_each = var.resources_to_tag
    content {
      resource_type = tag_specifications.value
      tags          = local.node_tags
    }
  }

  user_data = local.userdata
  tags      = local.node_group_tags
}

data "aws_launch_template" "this" {
  count = local.enabled && length(local.configured_launch_template_name) > 0 ? 1 : 0

  name = local.configured_launch_template_name
}

resource "random_pet" "default" {
  count = local.enabled ? 1 : 0

  separator = module.label.delimiter
  length    = 1

  keepers = {
    ami_type       = var.ami_type
    disk_size      = local.use_launch_template ? null : var.disk_size
    instance_types = join(",", local.use_launch_template ? [] : var.instance_types)
    node_role_arn  = join("", aws_iam_role.default.*.arn)

    ec2_ssh_key               = var.ec2_ssh_key == null ? "" : var.ec2_ssh_key
    source_security_group_ids = join(",", var.source_security_group_ids)
    subnet_ids                = join(",", var.subnet_ids)

    launch_template_id = local.launch_template_id
  }

  depends_on = [var.module_depends_on]
}

resource "aws_eks_node_group" "default" {
  count           = local.enabled ? 1 : 0
  cluster_name    = var.cluster_name
  node_group_name = format("%v%v%v", module.label.id, module.label.delimiter, join("", random_pet.default.*.id))
  node_role_arn   = join("", aws_iam_role.default.*.arn)
  subnet_ids      = var.subnet_ids
  disk_size       = local.use_launch_template ? null : var.disk_size
  instance_types  = local.use_launch_template ? null : var.instance_types
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

  dynamic "launch_template" {
    for_each = local.use_launch_template ? ["true"] : []
    content {
      id = local.launch_template_id
      version = (length(local.configured_launch_template_version) > 0 ? local.configured_launch_template_version :
        length(local.configured_launch_template_name) > 0 ? data.aws_launch_template.this[0].latest_version : aws_launch_template.default[0].latest_version
      )
    }
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
    aws_launch_template.default,
    # Also allow calling module to create an explicit dependency
    # This is useful in conjunction with terraform-aws-eks-cluster to ensure
    # the cluster is fully created and configured before creating any node groups
    var.module_depends_on
  ]

  dynamic "lifecycle" {
    for_each = ["true"]
    content {
      create_before_destroy = var.create_before_destroy
      ignore_changes = [
      scaling_config[0].desired_size]
    }
  }
}
