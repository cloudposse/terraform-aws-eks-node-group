# The userdata is built from the `userdata.tpl` file. It is limited to ~16k bytes,
# so comments about the userdata (~1k bytes) are here, not in the tpl file.
#
# userdata for EKS worker nodes to configure Kubernetes applications on EC2 instances
# In multipart MIME format so EKS can append to it. See:
#     https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-user-data
#     https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
# If you  just provide a #!/bin/bash script like you can do when you provide the entire userdata you get
# an error at deploy time: Ec2LaunchTemplateInvalidConfiguration: User data was not in the MIME multipart format
#
# See also:
# https://aws.amazon.com/premiumsupport/knowledge-center/execute-user-data-ec2/
# https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
# https://aws.amazon.com/blogs/opensource/improvements-eks-worker-node-provisioning/
# https://github.com/awslabs/amazon-eks-ami/blob/master/files/bootstrap.sh
#

locals {

  kubelet_extra_args = join(" ", var.kubelet_additional_options)

  userdata_vars = {
    before_cluster_joining_userdata = length(var.before_cluster_joining_userdata) == 0 ? "" : var.before_cluster_joining_userdata[0]
    kubelet_extra_args              = local.kubelet_extra_args
    bootstrap_extra_args            = length(var.bootstrap_additional_options) == 0 ? "" : var.bootstrap_additional_options[0]
    after_cluster_joining_userdata  = length(var.after_cluster_joining_userdata) == 0 ? "" : var.after_cluster_joining_userdata[0]
  }

  cluster_data = {
    cluster_endpoint           = local.get_cluster_data ? data.aws_eks_cluster.this[0].endpoint : null
    certificate_authority_data = local.get_cluster_data ? data.aws_eks_cluster.this[0].certificate_authority[0].data : null
    cluster_name               = local.get_cluster_data ? data.aws_eks_cluster.this[0].name : null
  }

  need_bootstrap = local.enabled ? length(concat(var.kubelet_additional_options,
    var.bootstrap_additional_options, var.after_cluster_joining_userdata
  )) > 0 : false

  # If var.userdata_override_base64[0] = "" then we explicitly set userdata to ""
  need_userdata = local.enabled && length(var.userdata_override_base64) == 0 ? (
  (length(var.before_cluster_joining_userdata) > 0) || local.need_bootstrap) : false

  userdata = local.need_userdata ? (
    base64encode(templatefile(can(regex("WINDOWS", var.ami_type)) ? "${path.module}/userdata_nt.tpl" : "${path.module}/userdata.tpl", merge(local.userdata_vars, local.cluster_data)))) : (
    try(var.userdata_override_base64[0], null)
  )
}
