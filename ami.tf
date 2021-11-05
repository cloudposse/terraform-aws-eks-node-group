
locals {
  # "amazon-eks-gpu-node-",
  arch_label_map = {
    "AL2_x86_64" : "",
    "AL2_x86_64_GPU" : "-gpu",
    "AL2_ARM_64" : "-arm64",
    "BOTTLEROCKET_x86_64" : "x86_64"
    "BOTTLEROCKET_ARM_64" : "aarch64"
  }
  
  ami_format = {
    # amazon-eks{arch_label}-node-{ami_kubernetes_version}-v{ami_version}
    # e.g. amazon-eks-arm64-node-1.21-v20211013
    "AL2" : "amazon-eks%s-node-%s-%s"
    # bottlerocket-aws-k8s-{ami_kubernetes_version}-{arch_label}-v{ami_version}
    # e.g. bottlerocket-aws-k8s-1.21-x86_64-v1.3.0
    "BOTTLETROCKET" : "bottlerocket-aws-k8s-%s-%s"
  }
  
  ami_type_kind = split("_", var.ami_type)[0]

  # Kubernetes version priority (first one to be set wins)
  # 1. prefix of var.ami_release_version
  # 2. var.kubernetes_version
  # 3. data.eks_cluster.this.kubernetes_version
  need_cluster_kubernetes_version = local.enabled ? local.need_ami_id && length(concat(var.ami_release_version, var.kubernetes_version)) == 0 : false

  ami_kubernetes_version = local.need_ami_id ? (local.need_cluster_kubernetes_version ? data.aws_eks_cluster.this[0].version :
    regex("^(\\d+\\.\\d+)", coalesce(try(var.ami_release_version[0], null), try(var.kubernetes_version[0], null)))[0]
  ) : ""

  ami_version_regex = local.need_ami_id ? (length(var.ami_release_version) == 1 ?
    replace(var.ami_release_version[0], "/^(\\d+\\.\\d+)\\.\\d+-(\\d+)$/", "$1-v$2") :
    "${local.ami_kubernetes_version}-*"
  ) : ""

  ami_regex = local.need_ami_id ? format(local.ami_format[local.ami_type_kind], local.arch_label_map[var.ami_type], local.ami_version_regex) : ""
}

data "aws_ami" "selected" {
  count = local.enabled && local.need_ami_id ? 1 : 0

  most_recent = true
  name_regex  = length(var.ami_name_regex) > 0 ? var.ami_name_regex[0] : local.ami_regex

  owners = ["amazon"]
}
