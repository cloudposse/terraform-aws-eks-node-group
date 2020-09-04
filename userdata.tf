locals {
  kubelet_label_settings = [for k, v in var.kubernetes_labels : format("%v=%v", k, v)]
  kubelet_taint_settings = [for k, v in var.kubernetes_taints : format("%v=%v", k, v)]
  kubelet_label_args = (length(local.kubelet_label_settings) == 0 ? "" :
    "--node-labels=${join(",", local.kubelet_label_settings)}"
  )
  kubelet_taint_args = (length(local.kubelet_taint_settings) == 0 ? "" :
    "--register-with-taints=${join(",", local.kubelet_taint_settings)}"
  )

  kubelet_extra_args = join(" ", compact([local.kubelet_label_args, local.kubelet_taint_args, var.kubelet_additional_options]))

  userdata_vars = {
    before_cluster_joining_userdata = var.before_cluster_joining_userdata == null ? "" : var.before_cluster_joining_userdata
    kubelet_extra_args              = local.kubelet_extra_args
    bootstrap_extra_args            = var.bootstrap_additional_options == null ? "" : var.bootstrap_additional_options
    after_cluster_joining_userdata  = var.after_cluster_joining_userdata == null ? "" : var.after_cluster_joining_userdata
  }

  cluster_data = {
    cluster_endpoint           = local.get_cluster_data ? data.aws_eks_cluster.this[0].endpoint : null
    certificate_authority_data = local.get_cluster_data ? data.aws_eks_cluster.this[0].certificate_authority[0].data : null
    cluster_name               = local.get_cluster_data ? data.aws_eks_cluster.this[0].name : null
  }

  need_bootstrap = length(compact([local.kubelet_taint_args, var.kubelet_additional_options,
    local.userdata_vars.bootstrap_extra_args,
    local.userdata_vars.after_cluster_joining_userdata]
  )) > 0

  need_userdata = (var.userdata_override == null) && (length(local.userdata_vars.before_cluster_joining_userdata) > 0) || local.need_bootstrap

  userdata = local.need_userdata ? base64encode(templatefile("${path.module}/userdata.tpl", merge(local.userdata_vars, local.cluster_data))) : var.userdata_override
}