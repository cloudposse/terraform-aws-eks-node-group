locals {
  enabled = module.this.enabled

  # See https://aws.amazon.com/blogs/containers/introducing-launch-template-and-custom-ami-support-in-amazon-eks-managed-node-groups/
  features_require_ami    = local.enabled && local.need_bootstrap
  configured_ami_image_id = var.ami_image_id == null ? "" : var.ami_image_id
  need_ami_id             = local.enabled ? local.features_require_ami && length(local.configured_ami_image_id) == 0 : false

  features_require_launch_template = local.enabled ? length(var.resources_to_tag) > 0 || local.need_userdata || local.features_require_ami : false

  have_ssh_key = var.ec2_ssh_key != null && var.ec2_ssh_key != ""

  need_remote_access_sg = local.enabled && local.have_ssh_key && local.generate_launch_template

  get_cluster_data = local.enabled ? (local.need_cluster_kubernetes_version || local.need_bootstrap || local.need_remote_access_sg) : false

  autoscaler_enabled = var.enable_cluster_autoscaler != null ? var.enable_cluster_autoscaler : var.cluster_autoscaler_enabled == true
  #
  # Set up tags for autoscaler and other resources
  #
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
  node_group_tags = merge(local.node_tags, local.autoscaler_enabled ? local.autoscaler_tags : {})
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.22.0"

  # Using attributes = ["workers"] would put "workers" before any user-specified attributes.
  # While that might be preferable (adding an attribute "blue" would create
  # ...name-workers-blue instead of ...name-blue-workers), historically we forced "workers"
  # to the end of the attribute list, so we do it again here to maintain compatibility.
  attributes = compact(concat(module.this.attributes, ["workers"]))

  context = module.this.context
}

data "aws_eks_cluster" "this" {
  count = local.get_cluster_data ? 1 : 0
  name  = var.cluster_name
}

# Support keeping 2 node groups in sync by extracting common variable settings
locals {
  ng_needs_remote_access = local.have_ssh_key && ! local.use_launch_template
  ng = {
    cluster_name    = var.cluster_name
    node_role_arn   = join("", aws_iam_role.default.*.arn)
    subnet_ids      = var.subnet_ids
    disk_size       = local.use_launch_template ? null : var.disk_size
    instance_types  = local.use_launch_template ? null : var.instance_types
    ami_type        = local.launch_template_ami == "" ? var.ami_type : null
    capacity_type   = var.capacity_type
    labels          = var.kubernetes_labels == null ? {} : var.kubernetes_labels
    release_version = local.launch_template_ami == "" ? var.ami_release_version : null
    version         = length(compact([local.launch_template_ami, var.ami_release_version])) == 0 ? var.kubernetes_version : null

    tags = local.node_group_tags

    scaling_config = {
      desired_size = var.desired_size
      max_size     = var.max_size
      min_size     = var.min_size
    }

    # Configure remote access via Launch Template if we are using one
    need_remote_access        = local.ng_needs_remote_access
    ec2_ssh_key               = local.have_ssh_key ? var.ec2_ssh_key : "none"
    source_security_group_ids = local.ng_needs_remote_access ? var.source_security_group_ids : []
  }
}

resource "random_pet" "cbd" {
  count = local.enabled && var.create_before_destroy ? 1 : 0

  separator = module.label.delimiter
  length    = 1

  keepers = {
    node_role_arn   = local.ng.node_role_arn
    subnet_ids      = join(",", local.ng.subnet_ids)
    disk_size       = local.ng.disk_size
    instance_types  = local.ng.instance_types == null ? "" : local.ng.instance_types[0]
    ami_type        = local.ng.ami_type
    release_version = local.ng.release_version
    version         = local.ng.version
    capacity_type   = local.ng.capacity_type

    need_remote_access = local.ng.need_remote_access
    ec2_ssh_key        = local.ng.need_remote_access ? local.ng.ec2_ssh_key : "handled by launch template"
    # Any change in security groups requires a new node group, because you cannot delete a security group while it is in use
    # and it will not automatically disassociate itself from instances or network interfaces.
    #
    # TODO: Once https://github.com/hashicorp/terraform/issues/25631 is fixed,
    #       actually track security groups by using
    #       source_security_group_ids = join(",", local.ng.source_security_group_ids, aws_security_group.remote_access.*.id)
    #
    source_security_group_ids = local.need_remote_access_sg ? "generated for launch template" : join(",", local.ng.source_security_group_ids)

    launch_template_id = local.use_launch_template ? local.launch_template_id : "none"
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

  capacity_type = local.ng.capacity_type

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
    for_each = local.ng.need_remote_access ? ["true"] : []
    content {
      ec2_ssh_key               = local.ng.ec2_ssh_key
      source_security_group_ids = local.ng.source_security_group_ids
    }
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_worker_node_autoscale_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_security_group.remote_access,
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

  capacity_type = local.ng.capacity_type

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
    for_each = local.ng.need_remote_access ? ["true"] : []
    content {
      ec2_ssh_key               = local.ng.ec2_ssh_key
      source_security_group_ids = local.ng.source_security_group_ids
    }
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_worker_node_autoscale_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_security_group.remote_access,
    # Also allow calling module to create an explicit dependency
    # This is useful in conjunction with terraform-aws-eks-cluster to ensure
    # the cluster is fully created and configured before creating any node groups
    var.module_depends_on
  ]
}
