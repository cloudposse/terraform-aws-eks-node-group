variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "create_before_destroy" {
  type        = bool
  description = <<-EOT
    If `true` (default), a new node group will be created before destroying the old one.
    If `false`, the old node group will be destroyed first, causing downtime.
    Changing this setting will always cause node group to be replaced.
    EOT
  default     = true
  nullable    = false
}

variable "random_pet_length" {
  type        = number
  description = <<-EOT
    In order to support "create before destroy" behavior, this module uses the `random_pet`
    resource to generate a unique pet name for the node group, since the node group name
    must be unique, meaning the new node group must have a different name than the old one.
    This variable controls the length of the pet name, meaning the number of pet names
    concatenated together. This module defaults to 1, but there are only 452 names available,
    so users with large numbers of node groups may want to increase this value.
    EOT
  default     = 1
  nullable    = false
}

variable "immediately_apply_lt_changes" {
  type        = bool
  description = <<-EOT
    When `true`, any change to the launch template will be applied immediately.
    When `false`, the changes will only affect new nodes when they are launched.
    When `null` (default) this input takes the value of `create_before_destroy`.
    **NOTE:** Setting this to `false` does not guarantee that other changes,
    such as `ami_type`, will not cause changes to be applied immediately.
    EOT
  default     = null
}

variable "ec2_ssh_key_name" {
  type        = list(string)
  description = "SSH key pair name to use to access the worker nodes"
  default     = []
  nullable    = false
  validation {
    condition = (
      length(var.ec2_ssh_key_name) < 2
    )
    error_message = "You may not specify more than one `ec2_ssh_key_name`."
  }
}

variable "ssh_access_security_group_ids" {
  type        = list(string)
  description = "Set of EC2 Security Group IDs to allow SSH access (port 22) to the worker nodes. If you specify `ec2_ssh_key`, but do not specify this configuration when you create an EKS Node Group, port 22 on the worker nodes is opened to the Internet (0.0.0.0/0)"
  default     = []
  nullable    = false
}

variable "desired_size" {
  type        = number
  description = "Initial desired number of worker nodes (external changes ignored)"
}

variable "max_size" {
  type        = number
  description = "Maximum number of worker nodes"
}

variable "min_size" {
  type        = number
  description = "Minimum number of worker nodes"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs to launch resources in"
  validation {
    condition = (
      length(var.subnet_ids) > 0
    )
    error_message = "You must specify at least 1 subnet to launch resources in."
  }
}

variable "associate_cluster_security_group" {
  type        = bool
  description = <<-EOT
    When true, associate the default cluster security group to the nodes. If disabled the EKS managed security group will not
    be associated to the nodes and you will need to provide another security group that allows the nodes to communicate with
    the EKS control plane. Be aware that if no `associated_security_group_ids` or `ssh_access_security_group_ids` are provided,
    then the nodes will have no inbound or outbound rules.
  EOT
  default     = true
  nullable    = false
}

variable "associated_security_group_ids" {
  type        = list(string)
  description = <<-EOT
    A list of IDs of Security Groups to associate the node group with, in addition to the EKS' created security group.
    These security groups will not be modified.
  EOT
  default     = []
  nullable    = false
}

variable "node_role_cni_policy_enabled" {
  type        = bool
  description = <<-EOT
    When true, the `AmazonEKS_CNI_Policy` will be attached to the node IAM role.
    This used to be required, but it is [now recommended](https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html) that this policy be
    attached only to the `aws-node` Kubernetes service account. However, that
    is difficult to do with Terraform, so this module defaults to the old pattern.
    EOT
  default     = true
  nullable    = false
}

variable "node_role_arn" {
  type        = list(string)
  description = "If provided, assign workers the given role, which this module will not modify"
  default     = []
  nullable    = false
  validation {
    condition = (
      length(var.node_role_arn) < 2
    )
    error_message = "You may not specify more than one `node_role_arn`."
  }
}

variable "node_role_policy_arns" {
  type        = list(string)
  description = "List of policy ARNs to attach to the worker role this module creates in addition to the default ones"
  default     = []
  nullable    = false
}

variable "node_role_permissions_boundary" {
  description = "If provided, all IAM roles will be created with this permissions boundary attached."
  type        = string
  default     = null
}

variable "ami_type" {
  type        = string
  description = <<-EOT
    Type of Amazon Machine Image (AMI) associated with the EKS Node Group.
    Defaults to `AL2_x86_64`. Valid values: `AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64_NVIDIA, BOTTLEROCKET_x86_64_NVIDIA, WINDOWS_CORE_2019_x86_64, WINDOWS_FULL_2019_x86_64, WINDOWS_CORE_2022_x86_64, WINDOWS_FULL_2022_x86_64, AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD`.
    EOT
  default     = "AL2_x86_64"
  nullable    = false
  validation {
    condition = (
      contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64_NVIDIA", "BOTTLEROCKET_x86_64_NVIDIA", "WINDOWS_CORE_2019_x86_64", "WINDOWS_FULL_2019_x86_64", "WINDOWS_CORE_2022_x86_64", "WINDOWS_FULL_2022_x86_64", "AL2023_x86_64_STANDARD", "AL2023_ARM_64_STANDARD"], var.ami_type)
    )
    error_message = "Var ami_type must be one of \"AL2_x86_64\",\"AL2_x86_64_GPU\",\"AL2_ARM_64\",\"BOTTLEROCKET_ARM_64\",\"BOTTLEROCKET_x86_64\",\"BOTTLEROCKET_ARM_64_NVIDIA\",\"BOTTLEROCKET_x86_64_NVIDIA\",\"WINDOWS_CORE_2019_x86_64\",\"WINDOWS_FULL_2019_x86_64\",\"WINDOWS_CORE_2022_x86_64\",\"WINDOWS_FULL_2022_x86_64\", \"AL2023_x86_64_STANDARD\", \"AL2023_ARM_64_STANDARD\", or \"CUSTOM\"."
  }
}

variable "ami_image_id" {
  type        = list(string)
  description = "AMI to use, overriding other AMI specifications, but must match `ami_type`. Ignored if `launch_template_id` is supplied."
  default     = []
  nullable    = false
  validation {
    condition = (
      length(var.ami_image_id) < 2
    )
    error_message = "You may not specify more than one `ami_image_id`."
  }
}

variable "ami_release_version" {
  type        = list(string)
  description = <<-EOT
    The EKS AMI "release version" to use. Defaults to the latest recommended version.
    For Amazon Linux, it is the "Release version" from [Amazon AMI Releases](https://github.com/awslabs/amazon-eks-ami/releases)
    For Bottlerocket, it is the release tag from [Bottlerocket Releases](https://github.com/bottlerocket-os/bottlerocket/releases) without the "v" prefix.
    For Windows, it is "AMI version" from [AWS docs](https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html).
    Note that unlike AMI names, release versions never include the "v" prefix.
    Examples:
      AL2: 1.29.3-20240531
      Bottlerocket: 1.2.0 or 1.2.0-ccf1b754
      Windows: 1.29-2024.04.09
    EOT
  # Normally we would not validate this input and instead allow the AWS API to validate it,
  # but in this case, our AMI selection logic depends on it being in a format we expect,
  # so even if AWS adds options in the future, we need to ensure it is in a format we can handle.
  validation {
    condition = (
      length(var.ami_release_version) == 0 ? true : length(
        # 1.2.3 with optional -20240531 or -7452c37e   or 1.2.3               or 1.2-2024.04.09
      regexall("(^\\d+\\.\\d+\\.\\d+(-[\\da-f]{8})?$)|(^\\d+\\.\\d+\\.\\d+$)|(^\\d+\\.\\d+-\\d+\\.\\d+\\.\\d+$)", var.ami_release_version[0])) == 1
    )
    error_message = <<-EOT
        Var ami_release_version, if supplied, must be like
          Amazon Linux 2 or 2023: 1.29.3-20240531
          Bottlerocket: 1.18.0 or 1.18.0-7452c37e # note commit hash prefix is 8 characters, not GitHub's default 7
          Windows: 1.29-2024.04.09
        EOT
  }
  default  = []
  nullable = false
}

variable "instance_types" {
  type        = list(string)
  description = <<-EOT
    Instance types to use for this node group (up to 20). Defaults to ["t3.medium"].
    Must be empty if the launch template configured by `launch_template_id` specifies an instance type.
    EOT
  default     = ["t3.medium"]
  nullable    = false
}

variable "capacity_type" {
  type        = string
  description = <<-EOT
    Type of capacity associated with the EKS Node Group. Valid values: "ON_DEMAND", "SPOT", or `null`.
    Terraform will only perform drift detection if a configuration value is provided.
    EOT
  default     = null
}

variable "block_device_map" {
  type = map(object({
    no_device    = optional(bool, null)
    virtual_name = optional(string, null)
    ebs = optional(object({
      delete_on_termination = optional(bool, true)
      encrypted             = optional(bool, true)
      iops                  = optional(number, null)
      kms_key_id            = optional(string, null)
      snapshot_id           = optional(string, null)
      throughput            = optional(number, null)
      volume_size           = optional(number, 20)
      volume_type           = optional(string, "gp3")
    }))
  }))

  description = <<-EOT
    Map of block device name specification, see [launch_template.block-devices](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#block-devices).
    EOT
  # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#ebs
  default  = { "/dev/xvda" = { ebs = {} } }
  nullable = false
}

variable "update_config" {
  type        = list(map(number))
  description = <<-EOT
    Configuration for the `eks_node_group` [`update_config` Configuration Block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group#update_config-configuration-block).
    Specify exactly one of `max_unavailable` (node count) or `max_unavailable_percentage` (percentage of nodes).
    EOT
  default     = []
  nullable    = false
}

variable "kubernetes_labels" {
  type        = map(string)
  description = <<-EOT
    Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument.
    Other Kubernetes labels applied to the EKS Node Group will not be managed.
    EOT
  default     = {}
  nullable    = false
}

variable "kubernetes_taints" {
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  description = <<-EOT
    List of `key`, `value`, `effect` objects representing Kubernetes taints.
    `effect` must be one of `NO_SCHEDULE`, `NO_EXECUTE`, or `PREFER_NO_SCHEDULE`.
    `key` and `effect` are required, `value` may be null.
    EOT
  default     = []
  nullable    = false
}

variable "kubelet_additional_options" {
  type        = list(string)
  description = <<-EOT
    Additional flags to pass to kubelet.
    DO NOT include `--node-labels` or `--node-taints`,
    use `kubernetes_labels` and `kubernetes_taints` to specify those."
    EOT
  validation {
    condition = (length(compact(var.kubelet_additional_options)) == 0 ? true :
      length(regexall("--node-labels", join(" ", var.kubelet_additional_options))) == 0 &&
      length(regexall("--node-taints", join(" ", var.kubelet_additional_options))) == 0
    )
    error_message = "Var kubelet_additional_options must not contain \"--node-labels\" or \"--node-taints\".  Use `kubernetes_labels` and `kubernetes_taints` to specify labels and taints."
  }
  default  = []
  nullable = false
}

variable "kubernetes_version" {
  type        = list(string)
  description = "Kubernetes version. Defaults to EKS Cluster Kubernetes version. Terraform will only perform drift detection if a configuration value is provided"
  validation {
    condition = (
      length(var.kubernetes_version) == 0 ? true : length(regexall("^\\d+\\.\\d+$", var.kubernetes_version[0])) == 1
    )
    error_message = "Var kubernetes_version, if supplied, must be like \"1.16\" (no patch level)."
  }
  default  = []
  nullable = false
}

variable "module_depends_on" {
  type        = any
  default     = null
  description = "Can be any value desired. Module will wait for this value to be computed before creating node group."
}

variable "ebs_optimized" {
  type        = bool
  default     = true
  description = "Set `false` to disable EBS optimization"
}

variable "launch_template_id" {
  type        = list(string)
  description = "The ID (not name) of a custom launch template to use for the EKS node group. If provided, it must specify the AMI image ID."
  validation {
    condition = (
      length(var.launch_template_id) < 2
    )
    error_message = "You may not specify more than one `launch_template_id`."
  }
  default  = []
  nullable = false
}

variable "launch_template_version" {
  type        = list(string)
  description = "The version of the specified launch template to use. Defaults to latest version."
  validation {
    condition = (
      length(var.launch_template_version) < 2
    )
    error_message = "You may not specify more than one `launch_template_version`."
  }
  default  = []
  nullable = false
}

variable "resources_to_tag" {
  type        = list(string)
  description = "List of auto-launched resource types to tag. Valid types are \"instance\", \"volume\", \"elastic-gpu\", \"spot-instances-request\", \"network-interface\"."
  default     = ["instance", "volume", "network-interface"]
  nullable    = false
}

variable "before_cluster_joining_userdata" {
  type        = list(string)
  description = "Additional `bash` commands to execute on each worker node before joining the EKS cluster (before executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
  default     = []
  nullable    = false
}

variable "after_cluster_joining_userdata" {
  type        = list(string)
  description = "Additional `bash` commands to execute on each worker node after joining the EKS cluster (after executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
  default     = []
  nullable    = false
}

variable "bootstrap_additional_options" {
  type        = list(string)
  description = "Additional options to bootstrap.sh. DO NOT include `--kubelet-additional-args`, use `kubelet_additional_options` var instead. Not used with AL2023 AMI types."
  default     = []
  nullable    = false
}

variable "userdata_override_base64" {
  type        = list(string)
  description = <<-EOT
    Many features of this module rely on the `bootstrap.sh` provided with Amazon Linux, and this module
    may generate "user data" that expects to find that script. If you want to use an AMI that is not
    compatible with the userdata generated by this module, then use `userdata_override_base64` to provide
    your own (Base64 encoded) user data. Use "" to prevent any user data from being set.

    Setting `userdata_override_base64` disables `kubernetes_taints`, `kubelet_additional_options`,
    `before_cluster_joining_userdata`, `after_cluster_joining_userdata`, and `bootstrap_additional_options`.
    EOT
  default     = []
  nullable    = false
  validation {
    condition = (
      length(var.userdata_override_base64) < 2
    )
    error_message = "You may not specify more than one `userdata_override_base64`."
  }
}

variable "metadata_http_endpoint_enabled" {
  type        = bool
  description = "Set false to disable the Instance Metadata Service."
  default     = true
  nullable    = false
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  description = <<-EOT
    The desired HTTP PUT response hop limit (between 1 and 64) for Instance Metadata Service requests.
    The default is `2` to allows containerized workloads assuming the instance profile, but it's not really recomended. You should use OIDC service accounts instead.
    EOT
  default     = 2
  nullable    = false
  validation {
    condition = (
      var.metadata_http_put_response_hop_limit >= 1
    )
    error_message = "IMDS hop limit must be at least 1 to work."
  }
}

variable "metadata_http_tokens_required" {
  type        = bool
  description = "Set true to require IMDS session tokens, disabling Instance Metadata Service Version 1."
  default     = true
  nullable    = false
}

variable "placement" {
  type        = list(any)
  description = <<-EOT
    Configuration for the [`placement` Configuration Block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#placement) of the launch template.
    Leave list empty for defaults. Pass list with single object with attributes matching the `placement` block to configure it.
    Note that this configures the launch template only. Some elements will be ignored by the Auto Scaling Group
    that actually launches instances. Consult AWS documentation for details.
    EOT
  default     = []
  nullable    = false
}

variable "cpu_options" {
  type        = list(any)
  description = <<-EOT
    Configuration for the [`cpu_options` Configuration Block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#cpu_options) of the launch template.
    Leave list empty for defaults. Pass list with single object with attributes matching the `cpu_options` block to configure it.
    Note that this configures the launch template only. Some elements will be ignored by the Auto Scaling Group
    that actually launches instances. Consult AWS documentation for details.
    EOT
  default     = []
  nullable    = false
}

variable "enclave_enabled" {
  type        = bool
  description = "Set to `true` to enable Nitro Enclaves on the instance."
  default     = false
  nullable    = false
}

variable "node_group_terraform_timeouts" {
  type = list(object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  }))
  description = <<-EOT
    Configuration for the Terraform [`timeouts` Configuration Block](https://www.terraform.io/docs/language/resources/syntax.html#operation-timeouts) of the node group resource.
    Leave list empty for defaults. Pass list with single object with attributes matching the `timeouts` block to configure it.
    Leave attribute values `null` to preserve individual defaults while setting others.
    EOT
  default     = []
  nullable    = false
}

variable "detailed_monitoring_enabled" {
  type        = bool
  description = "The launched EC2 instance will have detailed monitoring enabled. Defaults to false"
  default     = false
  nullable    = false
}

variable "force_update_version" {
  type        = bool
  description = "When updating the Kubernetes version, force Pods to be removed even if PodDisruptionBudget or taint/toleration issues would otherwise prevent them from being removed (and cause the update to fail)"
  default     = false
  nullable    = false
}

variable "replace_node_group_on_version_update" {
  type        = bool
  description = "Force Node Group replacement when updating to a new Kubernetes version. If set to `false` (the default), the Node Groups will be updated in-place"
  default     = false
  nullable    = false
}
