
# Previously, we found AMIs by using the aws_ami data source with a name_regex filter
# and `most_recent = true`. Unfortunately, `most_recent` means most recently created,
# and may not be the most recent Kubernetes version if, for example, a previous version
# had a new `eksbuild`. So instead, we now use the AMI IDs published in SSM.
# See https://docs.aws.amazon.com/eks/latest/userguide/retrieve-ami-id.html
#     https://docs.aws.amazon.com/eks/latest/userguide/retrieve-ami-id-bottlerocket.html

# Amazon Linux: https://docs.aws.amazon.com/eks/latest/userguide/retrieve-ami-id.html
# aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.30/amazon-linux-2/recommended/image_id \
#                --query "Parameter.Value" --output text
# Bottlerocket https://github.com/bottlerocket-os/bottlerocket/blob/develop/QUICKSTART-EKS.md#finding-an-ami
# aws ssm get-parameter --name /aws/service/bottlerocket/aws-k8s-1.30/x86_64/latest/image_id \
#                --query "Parameter.Value" --output text
# Windows: https://docs.aws.amazon.com/eks/latest/userguide/retrieve-windows-ami-id.html
# aws ssm get-parameter --name /aws/service/ami-windows-latest/Windows_Server-2019-English-Core-EKS_Optimized-1.30/image_id \
#                --region region-code --query "Parameter.Value" --output text


locals {
  # Public SSM parameters all start with /aws/service/

  # format string that makes
  #    format(fmt, specifier, k8s_version) the SSM parameter name to retrieve

  ami_ssm_format = {
    AL2_x86_64                 = "/aws/service/eks/optimized-ami/%[2]v/amazon-linux-2/%[1]v/image_id"
    AL2_x86_64_GPU             = "/aws/service/eks/optimized-ami/%[2]v/amazon-linux-2-gpu/%[1]v/image_id"
    AL2_ARM_64                 = "/aws/service/eks/optimized-ami/%[2]v/amazon-linux-2-arm64/%[1]v/image_id"
    AL2023_x86_64_STANDARD     = "/aws/service/eks/optimized-ami/%[2]v/amazon-linux-2023/x86_64/standard/%[1]v/image_id"
    AL2023_ARM_64_STANDARD     = "/aws/service/eks/optimized-ami/%[2]v/amazon-linux-2023/arm64/standard/%[1]v/image_id"
    BOTTLEROCKET_x86_64        = "/aws/service/bottlerocket/aws-k8s-%[2]v/x86_64/%[1]v/image_id"
    BOTTLEROCKET_ARM_64        = "/aws/service/bottlerocket/aws-k8s-%[2]v/arm64/%[1]v/image_id"
    BOTTLEROCKET_x86_64_NVIDIA = "/aws/service/bottlerocket/aws-k8s-%[2]v-nvidia/x86_64/%[1]v/image_id"
    BOTTLEROCKET_ARM_64_NVIDIA = "/aws/service/bottlerocket/aws-k8s-%[2]v-nvidia/arm64/%[1]v/image_id"
    WINDOWS_CORE_2019_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Core-EKS_Optimized-%[2]v/image_id"
    WINDOWS_FULL_2019_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Full-EKS_Optimized-%[2]v/image_id"
    WINDOWS_CORE_2022_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Core-EKS_Optimized-%[2]v/image_id"
    WINDOWS_FULL_2022_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-EKS_Optimized-%[2]v/image_id"
  }

  # AMI specifiers?
  # Specifiers for AL2 and AL2023 are AMI Name from https://github.com/awslabs/amazon-eks-ami/releases
  # AL2
  #   AMI name:      amazon-eks-node-1.29-v20240117
  #   AMI SSM param: /aws/service/eks/optimized-ami/1.29/amazon-linux-2/amazon-eks-node-1.29-v20240117/image_id
  # AL2023
  #   AMI name:      amazon-eks-node-al2023-arm64-standard-1.29-v20240605
  #   AMI SSM param: /aws/service/eks/optimized-ami/1.29/amazon-linux-2023/x86_64/standard/amazon-eks-node-al2023-x86_64-standard-1.29-v20240605/image_id
  # Specifiers for Bottlerocket are the bare release version (e.g. `1.20.0`) or
  #   the release version and the commit hash (e.g. `1.20.0-7c3e9198`)
  # Bottlerocket:
  #   AMI name:      bottlerocket-aws-k8s-1.26-nvidia-x86_64-v1.17.0-53f322c2
  #   AMI SSM param: /aws/service/bottlerocket/aws-k8s-1.26-nvidia/x86_64/1.17.0/image_id # No "v"
  #      /aws/service/bottlerocket/aws-k8s-1.26-nvidia/x86_64/1.17.0--53f322c2/image_id
  # Windows does not allow a specifier.
  ami_specifier = var.ami_specifier == "recommended" && startswith(var.ami_type, "BOTTLEROCKET") ? "latest" : var.ami_specifier

  # Kubernetes version priority (first one to be set wins)
  # 1. var.kubernetes_version
  # 2. data.eks_cluster.this.kubernetes_version
  use_cluster_kubernetes_version  = local.enabled && length(var.kubernetes_version) == 0
  need_cluster_kubernetes_version = local.use_cluster_kubernetes_version

  resolved_kubernetes_version = local.use_cluster_kubernetes_version ? data.aws_eks_cluster.this[0].version : var.kubernetes_version[0]
}

data "aws_ssm_parameter" "ami_id" {
  count = local.enabled && local.need_ami_id ? 1 : 0

  name = format(local.ami_ssm_format[var.ami_type], local.ami_specifier, local.resolved_kubernetes_version)
}
