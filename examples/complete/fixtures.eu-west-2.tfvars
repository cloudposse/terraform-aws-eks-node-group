region = "eu-west-2"

availability_zones = ["eu-west-2a", "eu-west-2b"]

vpc_cidr_block = "172.16.0.0/16"

namespace = "eg"

stage = "test"

name = "eks-node-group"

kubernetes_version = "1.25"

oidc_provider_enabled = true

enabled_cluster_log_types = ["audit"]

cluster_log_retention_period = 7

instance_types = ["t3.small"]

desired_size = 1

max_size = 1

min_size = 1

disk_size = 90

kubernetes_labels = {
  terratest = "true"
}

before_cluster_joining_userdata = <<-EOT
  printf "\n\n###\nExample output from before_cluster_joining_userdata\n###\n\n"
  EOT

update_config = [{ max_unavailable = 1 }]

kubernetes_taints = [
  {
    key    = "test"
    value  = null
    effect = "PREFER_NO_SCHEDULE"
}]
