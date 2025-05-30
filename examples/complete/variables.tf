variable "region" {
  type        = string
  description = "AWS Region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR for the VPC"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.20"
  description = "Desired Kubernetes master version. If you do not specify a value, the latest available version is used"
}

variable "enabled_cluster_log_types" {
  type        = list(string)
  default     = []
  description = "A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`]"
}

variable "cluster_log_retention_period" {
  type        = number
  default     = 0
  description = "Number of days to retain cluster logs. Requires `enabled_cluster_log_types` to be set. See https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html."
}

variable "oidc_provider_enabled" {
  type        = bool
  default     = true
  description = "Create an IAM OIDC identity provider for the cluster, then you can create IAM roles to associate with a service account in the cluster, instead of using `kiam` or `kube2iam`. For more information, see https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html"
}

variable "local_exec_interpreter" {
  type        = list(string)
  default     = ["/bin/sh", "-c"]
  description = "shell to use for local_exec"
}

variable "instance_types" {
  type        = list(string)
  description = "Set of instance types associated with the EKS Node Group. Defaults to [\"t3.medium\"]. Terraform will only perform drift detection if a configuration value is provided"
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
  type        = list(any)
  description = <<-EOT
    List of `key`, `value`, `effect` objects representing Kubernetes taints.
    `effect` must be one of `NO_SCHEDULE`, `NO_EXECUTE`, or `PREFER_NO_SCHEDULE`.
    `key` and `effect` are required, `value` may be null.
    EOT
  default     = []
}

variable "kubelet_additional_options" {
  type        = list(string)
  description = "Command-line flags to pass to kubelet"
}

variable "desired_size" {
  type        = number
  description = "Desired number of worker nodes"
}

variable "max_size" {
  type        = number
  description = "The maximum size of the AutoScaling Group"
}

variable "min_size" {
  type        = number
  description = "The minimum size of the AutoScaling Group"
}

variable "before_cluster_joining_userdata" {
  type        = list(string)
  default     = []
  description = "Additional commands to execute on each worker node before joining the EKS cluster (before executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
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

variable "ami_type" {
  type        = string
  description = <<-EOT
    Type of Amazon Machine Image (AMI) associated with the EKS Node Group.
    Defaults to `AL2_x86_64`. Valid values: `AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64_FIPS, BOTTLEROCKET_x86_64_FIPS, BOTTLEROCKET_ARM_64_NVIDIA, BOTTLEROCKET_x86_64_NVIDIA, WINDOWS_CORE_2019_x86_64, WINDOWS_FULL_2019_x86_64, WINDOWS_CORE_2022_x86_64, WINDOWS_FULL_2022_x86_64, AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD, AL2023_x86_64_NEURON, AL2023_x86_64_NVIDIA`.
    EOT
  default     = "AL2_x86_64"
  validation {
    condition = (
      contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64_FIPS", "BOTTLEROCKET_x86_64_FIPS", "BOTTLEROCKET_ARM_64_NVIDIA", "BOTTLEROCKET_x86_64_NVIDIA", "WINDOWS_CORE_2019_x86_64", "WINDOWS_FULL_2019_x86_64", "WINDOWS_CORE_2022_x86_64", "WINDOWS_FULL_2022_x86_64", "AL2023_x86_64_STANDARD", "AL2023_ARM_64_STANDARD", "AL2023_x86_64_NEURON", "AL2023_x86_64_NVIDIA"], var.ami_type)
    )
    error_message = "Var ami_type must be one of \"AL2_x86_64\",\"AL2_x86_64_GPU\",\"AL2_ARM_64\",\"BOTTLEROCKET_ARM_64\",\"BOTTLEROCKET_x86_64\",\"BOTTLEROCKET_ARM_64_FIPS\",\"BOTTLEROCKET_x86_64_FIPS\",\"BOTTLEROCKET_ARM_64_NVIDIA\",\"BOTTLEROCKET_x86_64_NVIDIA\",\"WINDOWS_CORE_2019_x86_64\",\"WINDOWS_FULL_2019_x86_64\",\"WINDOWS_CORE_2022_x86_64\",\"WINDOWS_FULL_2022_x86_64\", \"AL2023_x86_64_STANDARD\", \"AL2023_ARM_64_STANDARD\", \"AL2023_x86_64_NEURON\", \"AL2023_x86_64_NVIDIA\", or \"CUSTOM\"."
  }
}

variable "ami_release_version" {
  type        = list(string)
  description = <<-EOT
    The EKS AMI "release version" to use. Defaults to the latest recommended version.
    For Amazon Linux, get it from [Amazon AMI Releases](https://github.com/awslabs/amazon-eks-ami/releases)
    For Bottlerocket, get it from [Bottlerocket Releases](https://github.com/bottlerocket-os/bottlerocket/releases).
    For Windows, get it from [AWS docs](https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html).
    Note that unlike AMI names, release versions never include the "v" prefix.
    Examples:
      AL2: 1.29.3-20240531
      Bottlerocket: 1.2.0 or 1.2.0-ccf1b754
      Windows: 1.29-2024.04.09
    EOT
  default     = []
  nullable    = false
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

variable "force_update_version" {
  type        = bool
  default     = false
  description = "When updating the Kubernetes version, force Pods to be removed even if PodDisruptionBudget or taint/toleration issues would otherwise prevent them from being removed (and cause the update to fail)"
}

variable "replace_node_group_on_version_update" {
  type        = bool
  default     = false
  description = "Force Node Group replacement when updating to a new Kubernetes version. If set to `false` (the default), the Node Groups will be updated in-place"
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
