variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "create_before_destroy" {
  type        = bool
  default     = false
  description = <<-EOT
    Set true in order to create the new node group before destroying the old one.
    If false, the old node group will be destroyed first, causing downtime.
    Changing this setting will always cause node group to be replaced.
    EOT
}

variable "cluster_autoscaler_enabled" {
  type        = bool
  description = "Set true to label the node group so that the [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup) will discover and autoscale it"
  default     = false
}

variable "ec2_ssh_key_name" {
  type        = list(string)
  default     = []
  description = "SSH key pair name to use to access the worker nodes"
  validation {
    condition = (
      length(var.ec2_ssh_key_name) < 2
    )
    error_message = "You may not specify more than one `ec2_ssh_key_name`."
  }
}

variable "ssh_access_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Set of EC2 Security Group IDs to allow SSH access (port 22) to the worker nodes. If you specify `ec2_ssh_key`, but do not specify this configuration when you create an EKS Node Group, port 22 on the worker nodes is opened to the Internet (0.0.0.0/0)"
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
  description = "A list of subnet IDs to launch resources in"
  type        = list(string)
  validation {
    condition = (
      length(var.subnet_ids) > 0
    )
    error_message = "You must specify at least 1 subnet to launch resources in."
  }
}

variable "associate_cluster_security_group" {
  type        = bool
  default     = true
  description = <<-EOT
    When true, associate the default cluster security group to the nodes. If disabled the EKS managed security group will not
    be associated to the nodes, therefore the communications between pods and nodes will not work. Be aware that if no `associated_security_group_ids`
    nor `ssh_access_security_group_ids` are provided then the nodes will have no inbound or outbound rules. 
  EOT
}

variable "associated_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups to associate the node group with, in addition to the EKS' created security group.
    These security groups will not be modified.
  EOT
}

variable "node_role_cni_policy_enabled" {
  type        = bool
  default     = true
  description = <<-EOT
    When true, the `AmazonEKS_CNI_Policy` will be attached to the node IAM role.
    This used to be required, but it is [now recommended](https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html) that this policy be
    attached only to the `aws-node` Kubernetes service account. However, that
    is difficult to do with Terraform, so this module defaults to the old pattern.
    EOT
}

variable "node_role_arn" {
  type        = list(string)
  default     = []
  description = "If provided, assign workers the given role, which this module will not modify"
  validation {
    condition = (
      length(var.node_role_arn) < 2
    )
    error_message = "You may not specify more than one `node_role_arn`."
  }
}

variable "node_role_policy_arns" {
  type        = list(string)
  default     = []
  description = "List of policy ARNs to attach to the worker role this module creates in addition to the default ones"
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
    Defaults to `AL2_x86_64`. Valid values: `AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64_NVIDIA, BOTTLEROCKET_x86_64_NVIDIA, WINDOWS_CORE_2019_x86_64, WINDOWS_FULL_2019_x86_64, WINDOWS_CORE_2022_x86_64, WINDOWS_FULL_2022_x86_64`.
    EOT
  default     = "AL2_x86_64"
  validation {
    condition = (
      contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64_NVIDIA", "BOTTLEROCKET_x86_64_NVIDIA", "WINDOWS_CORE_2019_x86_64", "WINDOWS_FULL_2019_x86_64", "WINDOWS_CORE_2022_x86_64", "WINDOWS_FULL_2022_x86_64"], var.ami_type)
    )
    error_message = "Var ami_type must be one of \"AL2_x86_64\",\"AL2_x86_64_GPU\",\"AL2_ARM_64\",\"BOTTLEROCKET_ARM_64\",\"BOTTLEROCKET_x86_64\",\"BOTTLEROCKET_ARM_64_NVIDIA\",\"BOTTLEROCKET_x86_64_NVIDIA\",\"WINDOWS_CORE_2019_x86_64\",\"WINDOWS_FULL_2019_x86_64\",\"WINDOWS_CORE_2022_x86_64\",\"WINDOWS_FULL_2022_x86_64\", or \"CUSTOM\"."
  }
}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = <<-EOT
    Instance types to use for this node group (up to 20). Defaults to ["t3.medium"].
    Must be empty if the launch template configured by `launch_template_id` specifies an instance type.
    EOT
  validation {
    condition = (
      length(var.instance_types) <= 20
    )
    error_message = "Per the EKS API, no more than 20 instance types may be specified."
  }
}

variable "capacity_type" {
  type        = string
  default     = null
  description = <<-EOT
    Type of capacity associated with the EKS Node Group. Valid values: "ON_DEMAND", "SPOT", or `null`.
    Terraform will only perform drift detection if a configuration value is provided.
    EOT
  validation {
    condition     = var.capacity_type == null ? true : contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either `null`, \"ON_DEMAND\", or \"SPOT\"."
  }
}

variable "block_device_mappings" {
  type        = list(any)
  description = <<-EOT
    List of block device mappings for the launch template.
    Each list element is an object with a `device_name` key and
    any keys supported by the `ebs` block of `launch_template`.
    EOT
  # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#ebs
  default = [{
    device_name           = "/dev/xvda"
    volume_size           = 20
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }]
}

variable "update_config" {
  type        = list(map(number))
  default     = []
  description = <<-EOT
    Configuration for the `eks_node_group` [`update_config` Configuration Block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group#update_config-configuration-block).
    Specify exactly one of `max_unavailable` (node count) or `max_unavailable_percentage` (percentage of nodes).
    EOT
}

variable "kubernetes_labels" {
  type        = map(string)
  description = <<-EOT
    Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument.
    Other Kubernetes labels applied to the EKS Node Group will not be managed.
    EOT
  default     = {}
}

variable "kubernetes_taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  description = <<-EOT
    List of `key`, `value`, `effect` objects representing Kubernetes taints.
    `effect` must be one of `NO_SCHEDULE`, `NO_EXECUTE`, or `PREFER_NO_SCHEDULE`.
    `key` and `effect` are required, `value` may be null.
    EOT
  default     = []
}

variable "kubelet_additional_options" {
  type        = list(string)
  description = <<-EOT
    Additional flags to pass to kubelet.
    DO NOT include `--node-labels` or `--node-taints`,
    use `kubernetes_labels` and `kubernetes_taints` to specify those."
    EOT
  default     = []
  validation {
    condition = (length(compact(var.kubelet_additional_options)) == 0 ? true :
      length(regexall("--node-labels", join(" ", var.kubelet_additional_options))) == 0 &&
      length(regexall("--node-taints", join(" ", var.kubelet_additional_options))) == 0
    )
    error_message = "Var kubelet_additional_options must not contain \"--node-labels\" or \"--node-taints\".  Use `kubernetes_labels` and `kubernetes_taints` to specify labels and taints."
  }
}

variable "ami_image_id" {
  type        = list(string)
  default     = []
  description = "AMI to use. Ignored if `launch_template_id` is supplied."
  validation {
    condition = (
      length(var.ami_image_id) < 2
    )
    error_message = "You may not specify more than one `ami_image_id`."
  }
}

variable "ami_release_version" {
  type        = list(string)
  default     = []
  description = "EKS AMI version to use, e.g. For AL2 \"1.16.13-20200821\" or for bottlerocket \"1.2.0-ccf1b754\" (no \"v\") or  for Windows \"2023.02.14\". For AL2, bottlerocket and Windows, it defaults to latest version for Kubernetes version."
  validation {
    condition = (
      length(var.ami_release_version) == 0 ? true : length(regexall("(^\\d+\\.\\d+\\.\\d+-[\\da-z]+$)|(^\\d+\\.\\d+\\.\\d+$)", var.ami_release_version[0])) == 1
    )
    error_message = "Var ami_release_version, if supplied, must be like for AL2 \"1.16.13-20200821\" or for bottlerocket \"1.2.0-ccf1b754\" (no \"v\") or for Windows \"2023.02.14\"."
  }
}

variable "kubernetes_version" {
  type        = list(string)
  default     = []
  description = "Kubernetes version. Defaults to EKS Cluster Kubernetes version. Terraform will only perform drift detection if a configuration value is provided"
  validation {
    condition = (
      length(var.kubernetes_version) == 0 ? true : length(regexall("^\\d+\\.\\d+$", var.kubernetes_version[0])) == 1
    )
    error_message = "Var kubernetes_version, if supplied, must be like \"1.16\" (no patch level)."
  }
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
  default     = []
  description = "The ID (not name) of a custom launch template to use for the EKS node group. If provided, it must specify the AMI image ID."
  validation {
    condition = (
      length(var.launch_template_id) < 2
    )
    error_message = "You may not specify more than one `launch_template_id`."
  }
}

variable "launch_template_version" {
  type        = list(string)
  default     = []
  description = "The version of the specified launch template to use. Defaults to latest version."
  validation {
    condition = (
      length(var.launch_template_version) < 2
    )
    error_message = "You may not specify more than one `launch_template_version`."
  }
}

variable "resources_to_tag" {
  type        = list(string)
  description = "List of auto-launched resource types to tag. Valid types are \"instance\", \"volume\", \"elastic-gpu\", \"spot-instances-request\", \"network-interface\"."
  default     = ["instance", "volume", "network-interface"]
  validation {
    condition = (
      length(compact([for r in var.resources_to_tag : r if !contains(["instance", "volume", "elastic-gpu", "spot-instances-request", "network-interface"], r)])) == 0
    )
    error_message = "Invalid resource type in `resources_to_tag`. Valid types are \"instance\", \"volume\", \"elastic-gpu\", \"spot-instances-request\", \"network-interface\"."
  }
}

variable "before_cluster_joining_userdata" {
  type        = list(string)
  default     = []
  description = "Additional `bash` commands to execute on each worker node before joining the EKS cluster (before executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
  validation {
    condition = (
      length(var.before_cluster_joining_userdata) < 2
    )
    error_message = "You may not specify more than one `before_cluster_joining_userdata`."
  }
}

variable "after_cluster_joining_userdata" {
  type        = list(string)
  default     = []
  description = "Additional `bash` commands to execute on each worker node after joining the EKS cluster (after executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
  validation {
    condition = (
      length(var.after_cluster_joining_userdata) < 2
    )
    error_message = "You may not specify more than one `after_cluster_joining_userdata`."
  }
}

variable "bootstrap_additional_options" {
  type        = list(string)
  default     = []
  description = "Additional options to bootstrap.sh. DO NOT include `--kubelet-additional-args`, use `kubelet_additional_options` var instead."
  validation {
    condition = (
      length(var.bootstrap_additional_options) < 2
    )
    error_message = "You may not specify more than one `bootstrap_additional_options`."
  }
}

variable "userdata_override_base64" {
  type        = list(string)
  default     = []
  description = <<-EOT
    Many features of this module rely on the `bootstrap.sh` provided with Amazon Linux, and this module
    may generate "user data" that expects to find that script. If you want to use an AMI that is not
    compatible with the Amazon Linux `bootstrap.sh` initialization, then use `userdata_override_base64` to provide
    your own (Base64 encoded) user data. Use "" to prevent any user data from being set.

    Setting `userdata_override_base64` disables `kubernetes_taints`, `kubelet_additional_options`,
    `before_cluster_joining_userdata`, `after_cluster_joining_userdata`, and `bootstrap_additional_options`.
    EOT
  validation {
    condition = (
      length(var.userdata_override_base64) < 2
    )
    error_message = "You may not specify more than one `userdata_override_base64`."
  }
}

variable "metadata_http_endpoint_enabled" {
  type        = bool
  default     = true
  description = "Set false to disable the Instance Metadata Service."
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  default     = 2
  description = <<-EOT
    The desired HTTP PUT response hop limit (between 1 and 64) for Instance Metadata Service requests.
    The default is `2` to allows containerized workloads assuming the instance profile, but it's not really recomended. You should use OIDC service accounts instead.
    EOT
  validation {
    condition = (
      var.metadata_http_put_response_hop_limit >= 1
    )
    error_message = "IMDS hop limit must be at least 1 to work."
  }
}

variable "metadata_http_tokens_required" {
  type        = bool
  default     = true
  description = "Set true to require IMDS session tokens, disabling Instance Metadata Service Version 1."
}

variable "placement" {
  type        = list(any)
  default     = []
  description = <<-EOT
    Configuration for the [`placement` Configuration Block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#placement) of the launch template.
    Leave list empty for defaults. Pass list with single object with attributes matching the `placement` block to configure it.
    Note that this configures the launch template only. Some elements will be ignored by the Auto Scaling Group
    that actually launches instances. Consult AWS documentation for details.
    EOT
}

variable "enclave_enabled" {
  type        = bool
  default     = false
  description = "Set to `true` to enable Nitro Enclaves on the instance."
}

variable "node_group_terraform_timeouts" {
  type = list(object({
    create = string
    update = string
    delete = string
  }))
  default     = []
  description = <<-EOT
    Configuration for the Terraform [`timeouts` Configuration Block](https://www.terraform.io/docs/language/resources/syntax.html#operation-timeouts) of the node group resource.
    Leave list empty for defaults. Pass list with single object with attributes matching the `timeouts` block to configure it.
    Leave attribute values `null` to preserve individual defaults while setting others.
    EOT
}

variable "detailed_monitoring_enabled" {
  type        = bool
  default     = false
  description = "The launched EC2 instance will have detailed monitoring enabled. Defaults to false"
}
