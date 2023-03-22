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

  # We now always use a launch template. The only question is whether or not we generate one.
  launch_template_configured = length(var.launch_template_id) == 1
  generate_launch_template   = local.enabled && local.launch_template_configured == false
  fetch_launch_template      = local.enabled && local.launch_template_configured

  launch_template_id = local.enabled ? (local.fetch_launch_template ? var.launch_template_id[0] : aws_launch_template.default[0].id) : ""
  launch_template_version = local.enabled ? (length(var.launch_template_version) == 1 ? var.launch_template_version[0] : (
    local.fetch_launch_template ? data.aws_launch_template.this[0].latest_version : aws_launch_template.default[0].latest_version
  )) : null

  launch_template_ami = length(var.ami_image_id) == 0 ? (local.features_require_ami ? data.aws_ami.selected[0].image_id : "") : var.ami_image_id[0]

  associate_cluster_security_group = local.enabled && var.associate_cluster_security_group
  launch_template_vpc_security_group_ids = sort(compact(concat(
    local.associate_cluster_security_group ? data.aws_eks_cluster.this[*].vpc_config[0].cluster_security_group_id : [],
    module.ssh_access[*].id,
    var.associated_security_group_ids
  )))
}

resource "aws_launch_template" "default" {
  # We'll use this default if we aren't provided with a launch template during invocation.
  # We would like to generate a new launch template every time the security group list changes
  # so that we can detach the network interfaces from the security groups that we no
  # longer need, so that the security groups can then be deleted, but we cannot guarantee
  # that because the security group IDs are not available at plan time. So instead
  # we have to rely on `create_before_destroy` and `depends_on` to arrange things properly.

  count = local.generate_launch_template ? 1 : 0

  ebs_optimized = var.ebs_optimized

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings

    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        delete_on_termination = lookup(block_device_mappings.value, "delete_on_termination", null)
        encrypted             = lookup(block_device_mappings.value, "encrypted", null)
        iops                  = lookup(block_device_mappings.value, "iops", null)
        kms_key_id            = lookup(block_device_mappings.value, "kms_key_id", null)
        snapshot_id           = lookup(block_device_mappings.value, "snapshot_id", null)
        throughput            = lookup(block_device_mappings.value, "throughput", null)
        volume_size           = lookup(block_device_mappings.value, "volume_size", null)
        volume_type           = lookup(block_device_mappings.value, "volume_type", null)
      }
    }
  }

  name_prefix            = module.label.id
  update_default_version = true

  # Never include instance type in launch template because it is limited to just one
  # https://docs.aws.amazon.com/eks/latest/APIReference/API_CreateNodegroup.html#API_CreateNodegroup_RequestSyntax
  image_id = local.launch_template_ami == "" ? null : local.launch_template_ami
  key_name = local.ec2_ssh_key_name

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
  #     then make sure to set the Metadata response hop limit to at least 2 in your launch template.
  metadata_options {
    # Despite being documented as "Optional", `http_endpoint` is required when `http_put_response_hop_limit` is set.
    # We set it to the default setting of "enabled".

    http_endpoint               = var.metadata_http_endpoint_enabled ? "enabled" : "disabled"
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    http_tokens                 = var.metadata_http_tokens_required ? "required" : "optional"
  }

  vpc_security_group_ids = local.launch_template_vpc_security_group_ids
  user_data              = local.userdata
  tags                   = local.node_group_tags

  dynamic "placement" {
    for_each = var.placement

    content {
      affinity                = lookup(placement.value, "affinity", null)
      availability_zone       = lookup(placement.value, "availability_zone", null)
      group_name              = lookup(placement.value, "group_name", null)
      host_id                 = lookup(placement.value, "host_id", null)
      host_resource_group_arn = lookup(placement.value, "host_resource_group_arn", null)
      spread_domain           = lookup(placement.value, "spread_domain", null)
      tenancy                 = lookup(placement.value, "tenancy", null)
      partition_number        = lookup(placement.value, "partition_number", null)
    }
  }

  dynamic "enclave_options" {
    for_each = var.enclave_enabled ? ["true"] : []

    content {
      enabled = true
    }
  }

  monitoring {
    enabled = var.detailed_monitoring_enabled
  }

}

data "aws_launch_template" "this" {
  count = local.fetch_launch_template ? 1 : 0

  id = var.launch_template_id[0]
}
