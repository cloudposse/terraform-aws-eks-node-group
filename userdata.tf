# The userdata is built from the `userdata.tpl` file. It is limited to ~16k bytes,
# so comments about the userdata (~1k bytes) are here, not in the tpl file.
#
# We use '>-' to handle quoting and escaping values in the YAML.
#
# userdata for EKS worker nodes to configure Kubernetes applications on EC2 instances
# In multipart MIME format so EKS can append to it. See:
#     https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-user-data
#     https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
# If you just provide a #!/bin/bash script like you can do when you provide the entire userdata you get
# an error at deploy time: Ec2LaunchTemplateInvalidConfiguration: User data was not in the MIME multipart format
#
# We use a small boundary ("/:/+++") to save space.
# The format is
#   --boundary
#   Mime Type
#   <mandatory blank line>
#   <content>
#   <mandatory blank line>
#   --boundary
#   ## repeat
#   ## end with
#  --boundary--

# See also:
# https://aws.amazon.com/premiumsupport/knowledge-center/execute-user-data-ec2/
# https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
# https://aws.amazon.com/blogs/opensource/improvements-eks-worker-node-provisioning/
# https://github.com/awslabs/amazon-eks-ami/blob/master/files/bootstrap.sh
#

locals {
  # We need to suppress the EKS-supplied bootstrap if and only if we are running bootstrap.sh ourselves.
  # We need to run bootstrap.sh ourselves if:
  #  - We are running Amazon Linux 2 or Windows (the other OSes do not use bootstrap.sh) and either:
  #    - We explicitly are given extra args for bootstrap via bootstrap_additional_options or
  #    - We are given extra args for kubelet via kubelet_additional_options, which are passed to bootstrap.sh
  #    - We are given a script to run after bootstrap, which means we have to run bootstrap ourselves, because
  #      otherwise EKS will run boostrap a second time after our bootstrap and "after bootstrap"

  suppress_bootstrap = local.enabled && (local.ami_os == "AL2" || local.ami_os == "WINDOWS") ? (
    length(var.bootstrap_additional_options) > 0 || length(var.kubelet_additional_options) > 0 || length(var.after_cluster_joining_userdata) > 0
  ) : false

  userdata_template_file = {
    AL2          = "${path.module}/userdata.tpl"
    AL2023       = "${path.module}/userdata_al2023.tpl"
    BOTTLEROCKET = "${path.module}/userdata.tpl"
    WINDOWS      = "${path.module}/userdata_nt.tpl"
  }



  # When suppressing EKS bootstrap, add --register-with-taints to kubelet_extra_args,
  #   e.g. --register-with-taints=test=:PreferNoSchedule
  kubernetes_taint_argv = [
    for taint in var.kubernetes_taints :
    "${taint.key}=${taint.value == null ? "" : taint.value}:${local.taint_effect_map[taint.effect]}"
  ]
  kubernetes_taint_arg = (local.suppress_bootstrap && length(var.kubernetes_taints) > 0 &&
    # Do not add to or override --register-with-taints if it is already set
    !strcontains(local.kubelet_explicit_extra_args, "--register-with-taints=")) ? (
    " --register-with-taints=${join(",", local.kubernetes_taint_argv)}"
  ) : ""
  # We use '>-' to handle quoting and escaping values in the YAML.

  kubelet_explicit_extra_args = join(" ", var.kubelet_additional_options)
  kubelet_extra_args          = "${local.kubelet_explicit_extra_args}${local.kubernetes_taint_arg}"

  kubelet_extra_args_yaml = replace(local.kubelet_extra_args, "--", "\n      - >-\n        --")

  userdata_vars = {
    before_cluster_joining_userdata = length(var.before_cluster_joining_userdata) == 0 ? "" : join("\n", var.before_cluster_joining_userdata)
    kubelet_extra_args              = local.kubelet_extra_args
    kubelet_extra_args_yaml         = local.kubelet_extra_args_yaml
    bootstrap_extra_args            = length(var.bootstrap_additional_options) == 0 ? "" : join(" ", var.bootstrap_additional_options)
    after_cluster_joining_userdata  = length(var.after_cluster_joining_userdata) == 0 ? "" : join("\n", var.after_cluster_joining_userdata)

    cluster_endpoint           = local.get_cluster_data ? data.aws_eks_cluster.this[0].endpoint : null
    certificate_authority_data = local.get_cluster_data ? data.aws_eks_cluster.this[0].certificate_authority[0].data : null
    cluster_name               = local.get_cluster_data ? data.aws_eks_cluster.this[0].name : null
    cluster_cidr = local.get_cluster_data ? coalesce(concat(
      # prefer ipv4 address in dual stack
      [for net in data.aws_eks_cluster.this[0].kubernetes_network_config : net.service_ipv4_cidr if net.ip_family == "ipv4"],
      [for net in data.aws_eks_cluster.this[0].kubernetes_network_config : net.service_ipv6_cidr if net.ip_family == "ipv6"]
    )...) : null
  }

  # If var.userdata_override_base64[0] is present then we use it rather than generating userdata
  generate_userdata = local.enabled && length(var.userdata_override_base64) == 0 ? (
    length(var.before_cluster_joining_userdata) > 0 ||
    length(var.kubelet_additional_options) > 0 ||
    length(var.bootstrap_additional_options) > 0 ||
    length(var.after_cluster_joining_userdata) > 0
  ) : false

  userdata = local.generate_userdata ? (
    base64encode(
    templatefile(local.userdata_template_file[local.ami_os], local.userdata_vars))
    ) : (
    try(var.userdata_override_base64[0], null)
  )
}
