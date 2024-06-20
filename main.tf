locals {
  enabled = module.this.enabled

  # Kubernetes version priority (first one to be set wins)
  # 1. var.kubernetes_version
  # 2. data.eks_cluster.this.kubernetes_version
  use_cluster_kubernetes_version  = local.enabled && length(var.kubernetes_version) == 0
  need_cluster_kubernetes_version = local.use_cluster_kubernetes_version
  resolved_kubernetes_version     = local.use_cluster_kubernetes_version ? data.aws_eks_cluster.this[0].version : var.kubernetes_version[0]

  # By default (var.immediately_apply_lt_changes is null), apply changes immediately only if create_before_destroy is true.
  immediately_apply_lt_changes = coalesce(var.immediately_apply_lt_changes, var.create_before_destroy)

  # See https://aws.amazon.com/blogs/containers/introducing-launch-template-and-custom-ami-support-in-amazon-eks-managed-node-groups/
  features_require_ami = local.enabled && local.suppress_bootstrap
  need_to_get_ami_id   = local.enabled && local.features_require_ami && !local.given_ami_id

  have_ssh_key     = local.enabled && length(var.ec2_ssh_key_name) == 1
  ec2_ssh_key_name = local.have_ssh_key ? var.ec2_ssh_key_name[0] : null

  need_ssh_access_sg = local.enabled && (local.have_ssh_key || length(var.ssh_access_security_group_ids) > 0) && local.generate_launch_template

  get_cluster_data = local.enabled ? (
    local.need_cluster_kubernetes_version ||
    local.suppress_bootstrap ||
    local.associate_cluster_security_group ||
    local.need_ssh_access_sg
  ) : false

  taint_effect_map = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }

  #
  # Set up tags for autoscaler and other resources
  # https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup
  #
  # At the moment, the autoscaler tags are not needed.
  # We leave them here for when they can be applied to the autoscaling group.
  /*
  autoscaler_enabled_tags = {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"             = "true"
  }
  autoscaler_kubernetes_label_tags = {
    for label, value in var.kubernetes_labels : format("k8s.io/cluster-autoscaler/node-template/label/%v", label) => value
  }
  autoscaler_kubernetes_taints_tags = {
    for taint in var.kubernetes_taints : format("k8s.io/cluster-autoscaler/node-template/taint/%v", taint.key) =>
    "${taint.value == null ? "" : taint.value}:${local.taint_effect_map[taint.effect]}"
  }


  node_tags = merge(
    module.label.tags,
    {
      # We no longer need to add this tag to nodes, as it is added by EKS, but it does not hurt to keep it.
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  # It does not help to add the autoscaler tags to the node group tags,
  # because they only matter when applied to the autoscaling group.
  node_group_tags = local.node_tags
  */
  node_tags       = module.label.tags
  node_group_tags = module.label.tags
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["workers"]

  context = module.this.context
}

data "aws_eks_cluster" "this" {
  count = local.get_cluster_data ? 1 : 0
  name  = var.cluster_name
}

# Support keeping 2 node groups in sync by extracting common variable settings
locals {
  ng = {
    cluster_name  = var.cluster_name
    node_role_arn = local.create_role ? join("", aws_iam_role.default[*].arn) : try(var.node_role_arn[0], null)
    # Keep sorted so that change in order does not trigger replacement via random_pet
    subnet_ids = sort(var.subnet_ids)
    # Always supply instance types via the node group, not the launch template,
    # because node group supports up to 20 types but launch template does not.
    # See https://docs.aws.amazon.com/eks/latest/APIReference/API_CreateNodegroup.html#API_CreateNodegroup_RequestSyntax
    instance_types  = var.instance_types
    ami_type        = local.launch_template_ami == "" ? var.ami_type : null
    version         = local.launch_template_ami == "" ? local.resolved_kubernetes_version : null
    release_version = local.launch_template_ami == "" && length(var.ami_release_version) > 0 ? var.ami_release_version[0] : null
    capacity_type   = var.capacity_type
    labels          = var.kubernetes_labels == null ? {} : var.kubernetes_labels

    taints = var.kubernetes_taints

    tags = local.node_group_tags

    scaling_config = {
      desired_size = var.desired_size
      max_size     = var.max_size
      min_size     = var.min_size
    }

    force_update_version = var.force_update_version
  }
}

resource "random_pet" "cbd" {
  count = local.enabled && var.create_before_destroy ? 1 : 0

  separator = module.label.delimiter
  length    = var.random_pet_length

  keepers = merge(
    {
      node_role_arn  = local.ng.node_role_arn
      subnet_ids     = join(",", local.ng.subnet_ids)
      instance_types = join(",", local.ng.instance_types)
      ami_type       = local.ng.ami_type
      capacity_type  = local.ng.capacity_type
      launch_template_id = local.launch_template_configured || !local.immediately_apply_lt_changes ? local.launch_template_id : (
        # If we want changes to the generated launch template to be applied immediately, keep the settings
        jsonencode(local.launch_template_config)
      )
    },
    # If `var.replace_node_group_on_version_update` is set to `true`, the Node Groups will be replaced instead of updated in-place
    var.replace_node_group_on_version_update ?
    {
      version = var.kubernetes_version
    } : {}
  )
}

# Because create_before_destroy is such a dramatic change, we want to make it optional.
# Because lifecycle must be static, the only way to make it optional is to create
# two nearly identical resources and only enable the correct one.
# See https://github.com/hashicorp/terraform/issues/24188
#
# WARNING TO MAINTAINERS: both node groups should be kept exactly in sync
# except for count, lifecycle, and node_group_name.
resource "aws_eks_node_group" "default" {
  count           = local.enabled && !var.create_before_destroy ? 1 : 0
  node_group_name = module.label.id

  lifecycle {
    create_before_destroy = false
    ignore_changes        = [scaling_config[0].desired_size]
  }

  # From here to end of resource should be identical in both node groups
  cluster_name         = local.ng.cluster_name
  node_role_arn        = local.ng.node_role_arn
  subnet_ids           = local.ng.subnet_ids
  instance_types       = local.ng.instance_types
  ami_type             = local.ng.ami_type
  labels               = local.ng.labels
  version              = local.ng.version
  release_version      = local.ng.release_version
  force_update_version = local.ng.force_update_version

  capacity_type = local.ng.capacity_type

  tags = local.ng.tags

  scaling_config {
    desired_size = local.ng.scaling_config.desired_size
    max_size     = local.ng.scaling_config.max_size
    min_size     = local.ng.scaling_config.min_size
  }

  launch_template {
    id      = local.launch_template_id
    version = local.launch_template_version
  }

  dynamic "update_config" {
    for_each = var.update_config

    content {
      max_unavailable            = lookup(update_config.value, "max_unavailable", null)
      max_unavailable_percentage = lookup(update_config.value, "max_unavailable_percentage", null)
    }
  }

  dynamic "taint" {
    for_each = var.kubernetes_taints
    content {
      key    = taint.value["key"]
      value  = taint.value["value"]
      effect = taint.value["effect"]
    }
  }

  dynamic "timeouts" {
    for_each = var.node_group_terraform_timeouts
    content {
      create = timeouts.value["create"]
      update = timeouts.value["update"]
      delete = timeouts.value["delete"]
    }
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.ipv6_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_iam_role_policy_attachment.existing_policies_for_eks_workers_role,
    aws_launch_template.default,
    module.ssh_access,
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
  node_group_name = format("%v%v%v", module.label.id, module.label.delimiter, join("", random_pet.cbd[*].id))

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }

  # From here to end of resource should be identical in both node groups
  cluster_name         = local.ng.cluster_name
  node_role_arn        = local.ng.node_role_arn
  subnet_ids           = local.ng.subnet_ids
  instance_types       = local.ng.instance_types
  ami_type             = local.ng.ami_type
  labels               = local.ng.labels
  version              = local.ng.version
  release_version      = local.ng.release_version
  force_update_version = local.ng.force_update_version

  capacity_type = local.ng.capacity_type

  tags = local.ng.tags

  scaling_config {
    desired_size = local.ng.scaling_config.desired_size
    max_size     = local.ng.scaling_config.max_size
    min_size     = local.ng.scaling_config.min_size
  }

  launch_template {
    id      = local.launch_template_id
    version = local.launch_template_version
  }

  dynamic "update_config" {
    for_each = var.update_config

    content {
      max_unavailable            = lookup(update_config.value, "max_unavailable", null)
      max_unavailable_percentage = lookup(update_config.value, "max_unavailable_percentage", null)
    }
  }

  dynamic "taint" {
    for_each = var.kubernetes_taints
    content {
      key    = taint.value["key"]
      value  = taint.value["value"]
      effect = taint.value["effect"]
    }
  }

  dynamic "timeouts" {
    for_each = var.node_group_terraform_timeouts
    content {
      create = timeouts.value["create"]
      update = timeouts.value["update"]
      delete = timeouts.value["delete"]
    }
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.ipv6_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_launch_template.default,
    module.ssh_access,
    # Also allow calling module to create an explicit dependency
    # This is useful in conjunction with terraform-aws-eks-cluster to ensure
    # the cluster is fully created and configured before creating any node groups
    var.module_depends_on
  ]
}
