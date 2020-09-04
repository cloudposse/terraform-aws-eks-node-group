variable "enable_cluster_autoscaler" {
  type        = bool
  description = "Set true to allow Kubernetes Cluster Auto Scaler to scale the node group"
  default     = false
}

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

variable "ec2_ssh_key" {
  type        = string
  description = "SSH key name that should be used to access the worker nodes"
  default     = null
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
}

variable "existing_workers_role_policy_arns" {
  type        = list(string)
  default     = []
  description = "List of existing policy ARNs that will be attached to the workers default role on creation"
}

variable "existing_workers_role_policy_arns_count" {
  type        = number
  default     = 0
  description = "Obsolete and ignored. Allowed for backward compatibility."
}

variable "ami_type" {
  type        = string
  description = <<-EOT
    Type of Amazon Machine Image (AMI) associated with the EKS Node Group.
    Defaults to `AL2_x86_64`. Valid values: `AL2_x86_64`, `AL2_x86_64_GPU`, and `AL2_ARM_64`.
    EOT
  default     = "AL2_x86_64"
  validation {
    condition = (
      contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64"], var.ami_type)
    )
    error_message = "Var ami_type must be one of \"AL2_x86_64\", \"AL2_x86_64_GPU\", and \"AL2_ARM_64\"."
  }
}

variable "disk_size" {
  type        = number
  description = <<-EOT
    Disk size in GiB for worker nodes. Defaults to 20. Ignored it `launch_template_id` is supplied.
    Terraform will only perform drift detection if a configuration value is provided.
    EOT
  default     = 20
}

variable "instance_types" {
  type        = list(string)
  description = "Set of instance types associated with the EKS Node Group. Defaults to [\"t3.medium\"]. Terraform will only perform drift detection if a configuration value is provided"
  default     = ["t3.medium"]

  validation {
    condition = (
      length(var.instance_types) == 1
    )
    error_message = "Per the EKS API, only a single instance type value is currently supported."
  }
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
  type        = map(string)
  description = "Key-value mapping of Kubernetes taints."
  default     = {}
}

variable "kubelet_additional_options" {
  type        = string
  description = <<-EOT
    Additional flags to pass to kubelet.
    DO NOT include `--node-labels` or `--node-taints`,
    use `kubernetes_labels` and `kubernetes_taints` to specify those."
    EOT
  default     = ""
  validation {
    condition = (length(compact([var.kubelet_additional_options])) == 0 ? true :
      length(regexall("--node-labels", var.kubelet_additional_options)) == 0 &&
      length(regexall("--node-taints", var.kubelet_additional_options)) == 0
    )
    error_message = "Var kubelet_additional_options must not contain \"--node-labels\" or \"--node-taints\".  Use `kubernetes_labels` and `kubernetes_taints` to specify labels and taints."
  }
}

variable "ami_image_id" {
  type        = string
  description = "AMI to use. Ignored of `launch_template_id` is supplied."
  default     = null
}

variable "ami_release_version" {
  type        = string
  description = "AMI version to use, e.g. \"1.16.13-20200821\" (no \"v\"). Defaults to latest version for Kubernetes version."
  default     = null
  validation {
    condition = (
      length(compact([var.ami_release_version])) == 0 ? true : length(regexall("^\\d+\\.\\d+\\.\\d+-\\d+$", var.ami_release_version)) == 1
    )
    error_message = "Var ami_release_version, if supplied, must be like  \"1.16.13-20200821\" (no \"v\")."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version. Defaults to EKS Cluster Kubernetes version. Terraform will only perform drift detection if a configuration value is provided"
  default     = null
  validation {
    condition = (
      length(compact([var.kubernetes_version])) == 0 ? true : length(regexall("^\\d+\\.\\d+$", var.kubernetes_version)) == 1
    )
    error_message = "Var kubernetes_version, if supplied, must be like \"1.16\" (no patch level)."
  }
}

variable "source_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Set of EC2 Security Group IDs to allow SSH access (port 22) from on the worker nodes. If you specify `ec2_ssh_key`, but do not specify this configuration when you create an EKS Node Group, port 22 on the worker nodes is opened to the Internet (0.0.0.0/0)"
}

variable "module_depends_on" {
  type        = any
  default     = null
  description = "Can be any value desired. Module will wait for this value to be computed before creating node group."
}

variable "launch_template_name" {
  type = string
  // Note: the aws_launch_template data source only accepts name, not ID, to specify the launch template, so we cannot support ID as input.
  description = "The name (not ID) of a custom launch template to use for the EKS node group. If provided, it must specify the AMI image id."
  default     = null
}

variable "launch_template_version" {
  type        = string
  description = "The version of the specified launch template to use. Defaults to latest version."
  default     = null
}

variable "resources_to_tag" {
  type        = list(string)
  description = "List of auto-launched resource types to tag. Valid types are \"instance\", \"volume\", \"elastic-gpu\", \"spot-instance-request\"."
  default     = []
  validation {
    condition = (
      length(compact([for r in var.resources_to_tag : r if ! contains(["instance", "volume", "elastic-gpu", "spot-instance-request"], r)])) == 0
    )
    error_message = "Invalid resource type in `resources_to_tag`. Valid types are \"instance\", \"volume\", \"elastic-gpu\", \"spot-instance-request\"."
  }
}

variable "before_cluster_joining_userdata" {
  type        = string
  default     = ""
  description = "Additional commands to execute on each worker node before joining the EKS cluster (before executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
}

variable "after_cluster_joining_userdata" {
  type        = string
  default     = ""
  description = "Additional commands to execute on each worker node after joining the EKS cluster (after executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
}

variable "bootstrap_additional_options" {
  type        = string
  default     = ""
  description = "Additional options to bootstrap.sh. DO NOT include `--kubelet-additional-args`, use `kubelet_additional_args` var instead."
}

variable "userdata_override" {
  type        = string
  default     = null
  description = <<-EOT
    Many features of this module rely on the `bootstrap.sh` provided with Amazon Linux, and this module
    may generate "user data" that expects to find that script. If you want to use an AMI that does is not
    compatible with the Amazon Linux `bootstrap.sh` initialization, then use `userdata_override` to provide
    your own (Base64 encoded) user data. Use "" to prevent any user data from being set.

    Setting `userdata_override` disables `kubernetes_taints`, `kubelet_additional_options`,
    `before_cluster_joining_userdata`, `after_cluster_joining_userdata`, and `bootstrap_additional_options`.
    EOT
}
