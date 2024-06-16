region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

vpc_cidr_block = "172.16.0.0/16"

namespace = "eg"

stage = "test"

name = "eks-node-group"

# Keep Kubernetes version in sync with k8s.io packages in test/src/go.mod
kubernetes_version = "1.29"
# Keep the AMI release version in sync with the Kubernetes version
# Get Release Version from https://github.com/awslabs/amazon-eks-ami/releases
# but DO NOT USE THE LATEST VERSION. Use the one before that.
ami_release_version = ["1.29.3-20240531"]

# Use the same architecture for the instance type and the AMI type
instance_types = ["t4g.small"]
ami_type       = "AL2023_ARM_64_STANDARD"


oidc_provider_enabled = true

enabled_cluster_log_types = ["audit"]

cluster_log_retention_period = 7


desired_size = 2

max_size = 2

min_size = 2

kubernetes_labels = {
  terratest = "true"
}

before_cluster_joining_userdata = [
  "echo 1",
  "echo 2",
  "echo \"###\"",
  "printf \"Example output from before_cluster_joining_userdata\n###\n\n\"",
]

kubelet_additional_options = ["--kube-reserved cpu=100m,memory=600Mi,ephemeral-storage=1Gi --system-reserved cpu=100m,memory=200Mi,ephemeral-storage=1Gi --eviction-hard memory.available<200Mi,nodefs.available<10%,imagefs.available<15%"]

update_config = [{ max_unavailable = 2 }]

kubernetes_taints = [
  {
    key    = "test"
    effect = "PREFER_NO_SCHEDULE"
}]

