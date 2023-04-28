output "eks_node_group_role_arn" {
  description = "ARN of the worker nodes IAM role"
  value       = join("", aws_iam_role.default[*].arn)
}

output "eks_node_group_role_name" {
  description = "Name of the worker nodes IAM role"
  value       = join("", aws_iam_role.default[*].name)
}

output "eks_node_group_id" {
  description = "EKS Cluster name and EKS Node Group name separated by a colon"
  value       = join("", aws_eks_node_group.default[*].id, aws_eks_node_group.cbd[*].id)
}

output "eks_node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = join("", aws_eks_node_group.default[*].arn, aws_eks_node_group.cbd[*].arn)
}

output "eks_node_group_resources" {
  description = "List of objects containing information about underlying resources of the EKS Node Group"
  value       = local.enabled ? (var.create_before_destroy ? aws_eks_node_group.cbd[*].resources : aws_eks_node_group.default[*].resources) : []
}

output "eks_node_group_status" {
  description = "Status of the EKS Node Group"
  value       = join("", aws_eks_node_group.default[*].status, aws_eks_node_group.cbd[*].status)
}

output "eks_node_group_remote_access_security_group_id" {
  description = "The ID of the security group generated to allow SSH access to the nodes, if this module generated one"
  value       = join("", module.ssh_access[*].id)
}

output "eks_node_group_cbd_pet_name" {
  description = "The pet name of this node group, if this module generated one"
  value       = join("", random_pet.cbd[*].id)
}

output "eks_node_group_launch_template_id" {
  description = "The ID of the launch template used for this node group"
  value       = local.launch_template_id
}

output "eks_node_group_launch_template_name" {
  description = "The name of the launch template used for this node group"
  value       = local.enabled ? (local.fetch_launch_template ? join("", data.aws_launch_template.this[*].name) : join("", aws_launch_template.default[*].name)) : null
}

output "eks_node_group_tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider default_tags configuration block."
  value       = local.enabled ? (var.create_before_destroy ? aws_eks_node_group.cbd[0].tags_all : aws_eks_node_group.default[0].tags_all) : {}
}

output "eks_node_group_windows_note" {
  description = "Instructions on changes a user needs to follow or script for a windows node group in the event of a custom ami"
  value       = local.enabled && local.is_windows && local.need_bootstrap ? "When specifying a custom AMI ID for Windows managed node groups, add eks:kube-proxy-windows to your AWS IAM Authenticator configuration map. For more information, see Limits and conditions when specifying an AMI ID. https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html" : ""
}
