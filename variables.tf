variable "enable_cluster_autoscaler" {
  type        = bool
  description = "(Deprecated, use `cluster_autoscaler_enabled`) Set true to allow Kubernetes Cluster Auto Scaler to scale the node group"
  default     = null
}

variable "cluster_autoscaler_enabled" {
  type        = bool
  description = "Set true to label the node group so that the [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup) will discover and autoscale it"
  default     = null
}

variable "worker_role_autoscale_iam_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    If true, the worker IAM role will be authorized to perform autoscaling operations. Not recommended.
    Use [EKS IAM role for cluster autoscaler service account](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) instead.
    EOT
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
  description = "SSH key pair name to use to access the worker nodes"
  default     = null
}

variable "source_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Set of EC2 Security Group IDs to allow SSH access (port 22) to the worker nodes. If you specify `ec2_ssh_key`, but do not specify this configuration when you create an EKS Node Group, port 22 on the worker nodes is opened to the Internet (0.0.0.0/0)"
}

variable "additional_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Set of additional EC2 Security Group IDs that will be associated with the EKS Node Group"
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
    Disk size in GiB for worker nodes. Defaults to 20. Ignored when `launch_template_id` is supplied.
    Terraform will only perform drift detection if a configuration value is provided.
    EOT
  default     = 20
}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = <<-EOT
    Instance types to use for this node group (up to 20). Defaults to ["t3.medium"].
    Ignored when `launch_template_id` is supplied.
    EOT
  validation {
    condition = (
      length(var.instance_types) >= 1 && length(var.instance_types) <= 20
    )
    error_message = "Per the EKS API, up to 20 entries are supported."
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
  description = "EKS AMI version to use, e.g. \"1.16.13-20200821\" (no \"v\"). Defaults to latest version for Kubernetes version."
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

variable "module_depends_on" {
  type        = any
  default     = null
  description = "Can be any value desired. Module will wait for this value to be computed before creating node group."
}

variable "launch_template_disk_encryption_enabled" {
  type        = bool
  description = "Enable disk encryption for the created launch template (if we aren't provided with an existing launch template)"
  default     = false
}

variable "launch_template_name" {
  type = string
  # Note: the aws_launch_template data source only accepts name, not ID, to specify the launch template, so we cannot support ID as input.
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
  description = "List of auto-launched resource types to tag. Valid types are \"instance\", \"volume\", \"elastic-gpu\", \"spot-instances-request\"."
  default     = []
  validation {
    condition = (
      length(compact([for r in var.resources_to_tag : r if ! contains(["instance", "volume", "elastic-gpu", "spot-instances-request"], r)])) == 0
    )
    error_message = "Invalid resource type in `resources_to_tag`. Valid types are \"instance\", \"volume\", \"elastic-gpu\", \"spot-instances-request\"."
  }
}

variable "before_cluster_joining_userdata" {
  type        = string
  default     = ""
  description = "Additional `bash` commands to execute on each worker node before joining the EKS cluster (before executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
}

variable "after_cluster_joining_userdata" {
  type        = string
  default     = ""
  description = "Additional `bash` commands to execute on each worker node after joining the EKS cluster (after executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
}

variable "bootstrap_additional_options" {
  type        = string
  default     = ""
  description = "Additional options to bootstrap.sh. DO NOT include `--kubelet-additional-args`, use `kubelet_additional_args` var instead."
}

variable "userdata_override_base64" {
  type        = string
  default     = null
  description = <<-EOT
    Many features of this module rely on the `bootstrap.sh` provided with Amazon Linux, and this module
    may generate "user data" that expects to find that script. If you want to use an AMI that is not
    compatible with the Amazon Linux `bootstrap.sh` initialization, then use `userdata_override_base64` to provide
    your own (Base64 encoded) user data. Use "" to prevent any user data from being set.

    Setting `userdata_override_base64` disables `kubernetes_taints`, `kubelet_additional_options`,
    `before_cluster_joining_userdata`, `after_cluster_joining_userdata`, and `bootstrap_additional_options`.
    EOT
}

variable "permissions_boundary" {
  description = "If provided, all IAM roles will be created with this permissions boundary attached."
  type        = string
  default     = null
}

variable "disk_type" {
  type        = string
  default     = null
  description = "If provided, will be used as volume type of created ebs disk on EC2 instances"
}

variable "launch_template_disk_encryption_kms_key_id" {
  type        = string
  default     = ""
  description = "Custom KMS Key ID to encrypt EBS volumes on EC2 instances, applicable only if `launch_template_disk_encryption_enabled` is set to true"
}

variable "launch_template_http_put_response_hop_limit" {
  type        = number
  default     = 2
  description = "The desired HTTP PUT response hop limit for instance metadata requests"
}
