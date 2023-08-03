variable "block_device_mappings" {
  type        = list(any)
  description = <<-EOT
    DEPRECATED: Use `block_device_map` instead.
    List of block device mappings for the launch template.
    Each list element is an object with a `device_name` key and
    any keys supported by the `ebs` block of `launch_template`.
    EOT
  # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#ebs
  default = null
  /* default was:
  [{
    device_name           = "/dev/xvda"
    volume_size           = 20
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }]
  */
}

locals {
  block_device_map = var.block_device_mappings == null ? var.block_device_map : {
    for mapping in var.block_device_mappings : mapping.device_name => {
      no_device    = null
      virtual_name = null
      ebs = {
        delete_on_termination = lookup(mapping, "delete_on_termination", null)
        encrypted             = lookup(mapping, "encrypted", null)
        iops                  = lookup(mapping, "iops", null)
        kms_key_id            = lookup(mapping, "kms_key_id", null)
        snapshot_id           = lookup(mapping, "snapshot_id", null)
        throughput            = lookup(mapping, "throughput", null)
        volume_size           = lookup(mapping, "volume_size", null)
        volume_type           = lookup(mapping, "volume_type", null)
      }
    }
  }
}
