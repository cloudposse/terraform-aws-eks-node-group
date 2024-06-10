variable "ami_release_version" {
  type        = list(string)
  description = <<-EOT
    OBSOLETE: Use `ami_specifier` instead. Note that it has a different format.
    Historical description: EKS AMI version to use, e.g. For AL2 \"1.16.13-20200821\" or for bottlerocket \"1.2.0-ccf1b754\" (no \"v\") or  for Windows \"2023.02.14\". For AL2, bottlerocket and Windows, it defaults to latest version for Kubernetes version."
    EOT
  default     = []
  nullable    = false
  validation {
    condition     = length(var.ami_release_version) == 0
    error_message = "variable `ami_release_version` is obsolete. Use `ami_specifier` instead."
  }
}

# Include the warning output message to quite the linter about unused variables.
output "WARNING_ami_release_version" {
  value = length(var.ami_release_version) == 0 ? null : "WARNING: variable `ami_release_version` is obsolete and has been ignored."
}

variable "cluster_autoscaler_enabled" {
  type        = bool
  description = <<-EOT
    OBSOLETE. Used to add support for the Kubernetes Cluster Autoscaler, but additional support is no longer needed.
    EOT
  default     = null
}

output "WARNING_cluster_autoscaler_enabled" {
  value = var.cluster_autoscaler_enabled == null ? null : "WARNING: variable `cluster_autoscaler_enabled` is obsolete and has been ignored."
}

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
