locals {
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

  generate_launch_template = local.enabled ? local.features_require_launch_template && length(local.configured_launch_template_name) == 0 : false
  use_launch_template      = local.enabled ? local.features_require_launch_template || length(local.configured_launch_template_name) > 0 : false

  launch_template_id = local.use_launch_template ? (length(local.configured_launch_template_name) > 0 ? data.aws_launch_template.this[0].id : aws_launch_template.default[0].id) : ""
  launch_template_version = local.use_launch_template ? (
    length(local.configured_launch_template_version) > 0 ? local.configured_launch_template_version :
    (
      length(local.configured_launch_template_name) > 0 ? data.aws_launch_template.this[0].latest_version : aws_launch_template.default[0].latest_version
    )
  ) : ""

  launch_template_ami = length(local.configured_ami_image_id) == 0 ? (local.features_require_ami ? data.aws_ami.selected[0].image_id : "") : local.configured_ami_image_id

  launch_template_vpc_security_group_ids = (
    concat(
      local.ng.additional_security_group_ids,
      local.get_cluster_data ? data.aws_eks_cluster.this[0].vpc_config[*].cluster_security_group_id : [],
      local.need_remote_access_sg ? aws_security_group.remote_access.*.id : []
    )
  )

  # launch_template_key = join(":", coalescelist(local.launch_template_vpc_security_group_ids, ["closed"]))
}

resource "aws_launch_template" "default" {
  # We'll use this default if we aren't provided with a launch template during invocation
  # We need to generate a new launch template every time the security group list changes
  # so that we can detach the network interfaces from the security groups that we no
  # longer need, so that the security groups can then be deleted.

  # As a workaround for https://github.com/hashicorp/terraform/issues/26166 we
  # always create a launch template. Commented out code will be restored when the bug is fixed.
  count = local.enabled ? 1 : 0
  #count = (local.enabled && local.generate_launch_template) ? 1 : 0
  #for_each = (local.enabled && local.generate_launch_template) ? toset([local.launch_template_key]) : toset([])

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.disk_size
      volume_type = var.disk_type
      kms_key_id  = var.launch_template_disk_encryption_enabled && length(var.launch_template_disk_encryption_kms_key_id) > 0 ? var.launch_template_disk_encryption_kms_key_id : null
      encrypted   = var.launch_template_disk_encryption_enabled
    }
  }

  name_prefix            = module.label.id
  update_default_version = true

  # Never include instance type in launch template because it is limited to just one
  # https://docs.aws.amazon.com/eks/latest/APIReference/API_CreateNodegroup.html#API_CreateNodegroup_RequestSyntax
  image_id = local.launch_template_ami == "" ? null : local.launch_template_ami
  key_name = local.have_ssh_key ? var.ec2_ssh_key : null

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
    http_put_response_hop_limit = var.launch_template_http_put_response_hop_limit
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
