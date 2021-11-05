
locals {
  # "amazon-eks-gpu-node-",
  arch_label_map = {
    "AL2_x86_64" : "",
    "AL2_x86_64_GPU" : "-gpu",
    "AL2_ARM_64" : "-arm64",
    "BOTTLEROCKET_x86_64" : "x86_64",
    "BOTTLEROCKET_ARM_64" : "aarch64"
  }

  ami_format = {
    # amazon-eks{arch_label}-node-{ami_kubernetes_version}-v{ami_version}
    # e.g. amazon-eks-arm64-node-1.21-v20211013
    "AL2" : "amazon-eks%s-node-%s"
    # bottlerocket-aws-k8s-{ami_kubernetes_version}-{arch_label}-v{ami_version}
    # e.g. bottlerocket-aws-k8s-1.21-x86_64-v1.2.0-ccf1b754
    "BOTTLEROCKET" : "bottlerocket-aws-k8s-%s-%s-%s"
  }

  ami_type_kind = split("_", var.ami_type)[0]

  # Kubernetes version priority (first one to be set wins)
  # 1. prefix of var.ami_release_version
  # 2. var.kubernetes_version
  # 3. data.eks_cluster.this.kubernetes_version
  need_cluster_kubernetes_version = local.enabled ? local.need_ami_id && length(concat(var.ami_release_version, var.kubernetes_version)) == 0 : false

  ami_kubernetes_version = local.need_ami_id ? {
    "AL2" : (local.need_cluster_kubernetes_version ? data.aws_eks_cluster.this[0].version :
    regex("^(\\d+\\.\\d+)", coalesce(try(var.ami_release_version[0], null), try(var.kubernetes_version[0], null)))[0]
  ),
    "BOTTLEROCKET" : var.kubernetes_version[0],
  } : {}

  # if ami_release_version is provided
  ami_version_regex = local.need_ami_id ? {
    # if ami_release_version = "1.21-20211013"
    #   insert the letter v prior to the ami_version so it becomes 1.21-v20211013
    # if not, use the kubernetes version
    "AL2" : (length(var.ami_release_version) == 1 ?
      replace(var.ami_release_version[0], "/^(\\d+\\.\\d+)\\.\\d+-(\\d+)$/", "$1-v$2") :
    "${local.ami_kubernetes_version[local.ami_type_kind]}-*"),
    # if ami_release_version = "1.2.0-ccf1b754"
    #   prefex the ami release version with the letter v
    # if not, use an asterisk
    "BOTTLEROCKET" : (length(var.ami_release_version) == 1 ?
      format("v%s", var.ami_release_version[0]) : "*"),
  } : {}

  ami_regex = local.need_ami_id ? {
    "AL2" : format(local.ami_format["AL2"], local.arch_label_map[var.ami_type], local.ami_version_regex[local.ami_type_kind]),
    "BOTTLEROCKET" : format(local.ami_format["BOTTLEROCKET"], local.ami_kubernetes_version[local.ami_type_kind], local.arch_label_map[var.ami_type], local.ami_version_regex[local.ami_type_kind]),
  } : {}
}

data "aws_ami" "selected" {
  count = local.enabled && local.need_ami_id ? 1 : 0

  most_recent = true
  name_regex  = local.ami_regex[local.ami_type_kind]

  owners = ["amazon"]
}
