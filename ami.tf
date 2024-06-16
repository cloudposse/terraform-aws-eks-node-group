
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
  given_ami_id = length(var.ami_image_id) > 0

  # Public SSM parameters all start with /aws/service/

  ami_os = split("_", var.ami_type)[0]

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

  release_version_parts              = concat(split("-", try(var.ami_release_version[0], "")), ["", ""])
  amazon_linux_ami_name_release_part = try(join(".", slice(split(".", local.release_version_parts[0]), 0, 2)), "")
  # AMI Public SSM Parameter specifiers?
  # Release versions for AL2 and AL2023 are from https://github.com/awslabs/amazon-eks-ami/releases
  # Amazon Linux Release Version: 1.29.0-20240213
  # AL2
  #   AMI name:      amazon-eks-node-1.29-v20240117
  #   AMI SSM param: /aws/service/eks/optimized-ami/1.29/amazon-linux-2/amazon-eks-node-1.29-v20240117/image_id
  # AL2023
  #   AMI name:      amazon-eks-node-al2023-x86_64-standard-1.29-v20240213
  #   AMI SSM param: /aws/service/eks/optimized-ami/1.29/amazon-linux-2023/x86_64/standard/amazon-eks-node-al2023-x86_64-standard-1.29-v20240213/image_id
  # Specifiers for Bottlerocket are the bare release version (e.g. `1.18.0`) or
  #   the release version and the first 8 characters of the commit hash (e.g. `1.18.0-7452c37e`). NOTE: GitHub commit hash abbreviations are only 7 characters.
  # From:
  # Bottlerocket:
  #   AMI name:      bottlerocket-aws-k8s-1.29-nvidia-x86_64-v1.18.0-7452c37e
  #   AMI SSM param: /aws/service/bottlerocket/aws-k8s-1.26-nvidia/x86_64/1.18.0/image_id # No "v"
  #      /aws/service/bottlerocket/aws-k8s-1.26-nvidia/x86_64/1.18.0-7452c37e/image_id
  # Windows does not allow a specifier for SSM parameters, they only have the latest AMI ID
  ami_specifier_amazon_linux = {
    AL2_x86_64             = format("amazon-eks-node-%v-v%v", local.amazon_linux_ami_name_release_part, local.release_version_parts[1])
    AL2_x86_64_GPU         = format("amazon-eks-gpu-node-%v-v%v", local.amazon_linux_ami_name_release_part, local.release_version_parts[1])
    AL2_ARM_64             = format("amazon-eks-arm64-node-%v-v%v", local.amazon_linux_ami_name_release_part, local.release_version_parts[1])
    AL2023_x86_64_STANDARD = format("amazon-eks-node-al2023-x86_64-standard-%v-v%v", local.amazon_linux_ami_name_release_part, local.release_version_parts[1])
    AL2023_ARM_64_STANDARD = format("amazon-eks-node-al2023-arm64-standard-%v-v%v", local.amazon_linux_ami_name_release_part, local.release_version_parts[1])
  }

  ami_specifier = length(var.ami_release_version) == 0 ? (local.ami_os == "BOTTLEROCKET" ? "latest" : "recommended") : (
    lookup(local.ami_specifier_amazon_linux, var.ami_type, var.ami_release_version[0])
  )

  # As usual, Windows is difficult.
  is_window_version = local.ami_os == "WINDOWS" && local.ami_specifier != "recommended"

  windows_name_base = {
    WINDOWS_CORE_2019_x86_64 = "Windows_Server-2019-English-Core-EKS_Optimized"
    WINDOWS_FULL_2019_x86_64 = "Windows_Server-2019-English-Full-EKS_Optimized"
    WINDOWS_CORE_2022_x86_64 = "Windows_Server-2022-English-Core-EKS_Optimized"
    WINDOWS_FULL_2022_x86_64 = "Windows_Server-2022-English-Full-EKS_Optimized"
  }

  # We do not really need to compute all the names, but it makes debugging easier if we do.
  ami_name_windows = { for k, v in local.windows_name_base : k => format("%s-%s", v, try(var.ami_release_version[0], "")) }

  fetched_ami_id = try(local.is_window_version ? data.aws_ami.windows_ami[0].image_id : data.aws_ssm_parameter.ami_id[0].insecure_value, "")
  ami_id         = local.given_ami_id ? var.ami_image_id[0] : local.fetched_ami_id
}

data "aws_ssm_parameter" "ami_id" {
  count = local.need_to_get_ami_id && !local.is_window_version ? 1 : 0

  name = format(local.ami_ssm_format[var.ami_type], local.ami_specifier, local.resolved_kubernetes_version)

  lifecycle {
    precondition {
      condition     = var.ami_type != "CUSTOM"
      error_message = "The AMI ID must be supplied when AMI type is \"CUSTOM\"."
    }
  }
}

data "aws_ami" "windows_ami" {
  count = local.need_to_get_ami_id && local.is_window_version ? 1 : 0

  owners = ["amazon"]
  filter {
    name   = "name"
    values = [local.ami_name_windows[var.ami_type]]
  }
}

