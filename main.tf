locals {
  enabled = module.this.enabled

  # The heavy use of the ternary operator `? :` is because it is one of the few ways to avoid
  # evaluating expressions. The unused expression is not evaluated and so it does not have to be valid.
  # This allows us to refer to resources that are only conditionally created and avoid creating
  # dependencies on them that would not be avoided by using expressions like `join("",expr)`.
  #
  # We use this pattern with enabled for every boolean that begins with `need_` even though
  # it is sometimes redundant, to ensure that ever `need_` is false and every dependent
  # expression is not evaluated when enabled is false. Avoiding expression evaluations
  # is also why, even for boolean expressions, we use
  #   local.enabled ? expression : false
  # rather than
  #   local.enabled && expression
  #
  # The expression
  #   length(compact([var.launch_template_version])) > 0
  # is a shorter way of accomplishing the same test as
  #   var.launch_template_version != null && var.launch_template_version != ""
  # and as an idiom has the added benefit of being extensible:
  #   length(compact([x, y])) > 0
  # is the same as
  #   x != null && x != "" && y != null && y != ""

  configured_launch_template_name    = var.launch_template_name == null ? "" : var.launch_template_name
  configured_launch_template_version = length(local.configured_launch_template_name) > 0 && length(compact([var.launch_template_version])) > 0 ? var.launch_template_version : ""

  configured_ami_image_id = var.ami_image_id == null ? "" : var.ami_image_id

  # See https://aws.amazon.com/blogs/containers/introducing-launch-template-and-custom-ami-support-in-amazon-eks-managed-node-groups/
  features_require_ami = local.enabled && local.need_bootstrap
  need_ami_id          = local.enabled ? local.features_require_ami && length(local.configured_ami_image_id) == 0 : false

  features_require_launch_template = local.enabled ? length(var.resources_to_tag) > 0 || local.need_userdata || local.features_require_ami : false
  generate_launch_template         = local.enabled ? local.features_require_launch_template && length(local.configured_launch_template_name) == 0 : false
  use_launch_template              = local.enabled ? local.features_require_launch_template || length(local.configured_launch_template_name) > 0 : false

  launch_template_id = local.use_launch_template ? (length(local.configured_launch_template_name) > 0 ? data.aws_launch_template.this[0].id : aws_launch_template.default[0].id) : ""
  launch_template_version = local.use_launch_template ? (
    length(local.configured_launch_template_version) > 0 ? local.configured_launch_template_version :
    (
      length(local.configured_launch_template_name) > 0 ? data.aws_launch_template.this[0].latest_version : aws_launch_template.default[0].latest_version
    )
  ) : ""

  launch_template_ami = length(local.configured_ami_image_id) == 0 ? (local.features_require_ami ? data.aws_ami.selected[0].image_id : "") : local.configured_ami_image_id

  launch_template_create_remote_access_sg = local.enabled && var.ec2_ssh_key != null && local.generate_launch_template
  launch_template_vpc_security_group_ids = (local.enabled && local.generate_launch_template) ? concat(
    list(data.aws_eks_cluster.this[0].vpc_config[0].cluster_security_group_id),
    aws_security_group.remote_access.*.id,
  ) : null

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

  get_cluster_data = local.enabled ? (local.need_cluster_kubernetes_version || local.need_bootstrap || local.launch_template_create_remote_access_sg) : false
}

data "aws_eks_cluster" "this" {
  count = local.get_cluster_data ? 1 : 0
  name  = var.cluster_name
}

data "aws_subnet" "default" {
  count = local.launch_template_create_remote_access_sg ? 1 : 0
  id    = var.subnet_ids[0]
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
  for_each   = local.enabled ? toset(var.existing_workers_role_policy_arns) : []
  policy_arn = each.value
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
  image_id      = local.launch_template_ami == "" ? null : local.launch_template_ami
  key_name      = var.ec2_ssh_key

  dynamic "tag_specifications" {
    for_each = var.resources_to_tag
    content {
      resource_type = tag_specifications.value
      tags          = local.node_tags
    }
  }

  # See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html
  # and https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html
  # Note in particular:
  #     If any containers that you deploy to the node group use the Instance Metadata Service Version 2,
  #     then make sure to set the Metadata response hop limit to 2 in your launch template.
  metadata_options {
    http_put_response_hop_limit = 2
    # Despite being documented as "Optional", `http_endpoint` is required when `http_put_response_hop_limit` is set.
    # We set it to the default setting of "enabled".
    http_endpoint = "enabled"
  }

  vpc_security_group_ids = local.launch_template_vpc_security_group_ids
  user_data              = local.userdata
  tags                   = local.node_group_tags
}

data "aws_launch_template" "this" {
  count = local.enabled && length(local.configured_launch_template_name) > 0 ? 1 : 0

  name = local.configured_launch_template_name
}

resource "random_pet" "cbd" {
  count = local.enabled && var.create_before_destroy ? 1 : 0

  separator = module.label.delimiter
  length    = 1

  keepers = {
    ami_type            = var.ami_type
    ami_release_version = var.ami_release_version
    kubernetes_version  = var.kubernetes_version
    disk_size           = local.use_launch_template ? null : var.disk_size
    instance_types      = join(",", local.use_launch_template ? [] : var.instance_types)
    node_role_arn       = join("", aws_iam_role.default.*.arn)

    ec2_ssh_key               = var.ec2_ssh_key == null ? "" : var.ec2_ssh_key
    source_security_group_ids = join(",", var.source_security_group_ids)
    subnet_ids                = join(",", var.subnet_ids)

    launch_template_id  = local.launch_template_id
    launch_template_ami = local.launch_template_ami
  }

  depends_on = [var.module_depends_on]
}


# Support keeping 2 node groups in sync by extracting common variable settings
locals {
  ng = {
    cluster_name    = var.cluster_name
    node_role_arn   = join("", aws_iam_role.default.*.arn)
    subnet_ids      = var.subnet_ids
    disk_size       = local.use_launch_template ? null : var.disk_size
    instance_types  = local.use_launch_template ? null : var.instance_types
    ami_type        = local.launch_template_ami == "" ? var.ami_type : null
    labels          = var.kubernetes_labels
    release_version = local.launch_template_ami == "" ? var.ami_release_version : null
    version         = length(compact([local.launch_template_ami, var.ami_release_version])) == 0 ? var.kubernetes_version : null

    tags = local.node_group_tags

    scaling_config = {
      desired_size = var.desired_size
      max_size     = var.max_size
      min_size     = var.min_size
    }

    ec2_ssh_key               = var.ec2_ssh_key == null ? "" : var.ec2_ssh_key
    source_security_group_ids = var.source_security_group_ids
  }
}

# Because create_before_destroy is such a dramatic change, we want to make it optional.
# Because lifecycle must be static, the only way to make it optional is to create
# two nearly identical resources and only enable the correct one.
# See https://github.com/hashicorp/terraform/issues/24188
#
# WARNING TO MAINTAINERS: both node groups should be kept exactly in sync
# except for count, lifecycle, and node_group_name.
resource "aws_eks_node_group" "default" {
  count           = local.enabled && ! var.create_before_destroy ? 1 : 0
  node_group_name = module.label.id

  lifecycle {
    create_before_destroy = false
    ignore_changes        = [scaling_config[0].desired_size]
  }

  # From here to end of resource should be identical in both node groups
  cluster_name    = local.ng.cluster_name
  node_role_arn   = local.ng.node_role_arn
  subnet_ids      = local.ng.subnet_ids
  disk_size       = local.ng.disk_size
  instance_types  = local.ng.instance_types
  ami_type        = local.ng.ami_type
  labels          = local.ng.labels
  release_version = local.ng.release_version
  version         = local.ng.version

  tags = local.ng.tags

  scaling_config {
    desired_size = local.ng.scaling_config.desired_size
    max_size     = local.ng.scaling_config.max_size
    min_size     = local.ng.scaling_config.min_size
  }

  dynamic "launch_template" {
    for_each = local.use_launch_template ? ["true"] : []
    content {
      id      = local.launch_template_id
      version = local.launch_template_version
    }
  }

  dynamic "remote_access" {
    for_each = length(local.ng.ec2_ssh_key) > 0 && ! local.use_launch_template ? ["true"] : []
    content {
      ec2_ssh_key               = local.ng.ec2_ssh_key
      source_security_group_ids = local.ng.source_security_group_ids
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
}

# WARNING TO MAINTAINERS: both node groups should be kept exactly in sync
# except for count, lifecycle, and node_group_name.
resource "aws_eks_node_group" "cbd" {
  count           = local.enabled && var.create_before_destroy ? 1 : 0
  node_group_name = format("%v%v%v", module.label.id, module.label.delimiter, join("", random_pet.cbd.*.id))

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }

  # From here to end of resource should be identical in both node groups
  cluster_name    = local.ng.cluster_name
  node_role_arn   = local.ng.node_role_arn
  subnet_ids      = local.ng.subnet_ids
  disk_size       = local.ng.disk_size
  instance_types  = local.ng.instance_types
  ami_type        = local.ng.ami_type
  labels          = local.ng.labels
  release_version = local.ng.release_version
  version         = local.ng.version

  tags = local.ng.tags

  scaling_config {
    desired_size = local.ng.scaling_config.desired_size
    max_size     = local.ng.scaling_config.max_size
    min_size     = local.ng.scaling_config.min_size
  }

  dynamic "launch_template" {
    for_each = local.use_launch_template ? ["true"] : []
    content {
      id      = local.launch_template_id
      version = local.launch_template_version
    }
  }

  dynamic "remote_access" {
    for_each = length(local.ng.ec2_ssh_key) > 0 && ! local.use_launch_template ? ["true"] : []
    content {
      ec2_ssh_key               = local.ng.ec2_ssh_key
      source_security_group_ids = local.ng.source_security_group_ids
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
}
