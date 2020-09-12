output "eks_node_group_role_arn" {
  description = "ARN of the worker nodes IAM role"
  value       = join("", aws_iam_role.default.*.arn)
}

output "eks_node_group_role_name" {
  description = "Name of the worker nodes IAM role"
  value       = join("", aws_iam_role.default.*.name)
}

output "eks_node_group_id" {
  description = "EKS Cluster name and EKS Node Group name separated by a colon"
  value       = join("", aws_eks_node_group.default.*.id, aws_eks_node_group.cbd.*.id)
}

output "eks_node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = join("", aws_eks_node_group.default.*.arn, aws_eks_node_group.cbd.*.arn)
}

output "eks_node_group_resources" {
  description = "List of objects containing information about underlying resources of the EKS Node Group"
  value       = local.enabled ? (var.create_before_destroy ? aws_eks_node_group.cbd.*.resources : aws_eks_node_group.default.*.resources) : []
}

output "eks_node_group_status" {
  description = "Status of the EKS Node Group"
  value       = join("", aws_eks_node_group.default.*.status, aws_eks_node_group.cbd.*.status)
}

output "eks_node_group_remote_access_security_group_id" {
  description = "The ID of the security group generated to allow SSH access to the nodes, if this module generated one"
  value       = join("", aws_security_group.remote_access.*.id)
}
