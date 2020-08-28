region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

vpc_cidr_block = "172.16.0.0/16"

namespace = "eg"

stage = "test"

name = "eks-node-group"

kubernetes_version = "1.15"

oidc_provider_enabled = true

enabled_cluster_log_types = ["audit"]

cluster_log_retention_period = 7

instance_type = "t3.small"

desired_size = 2

max_size = 3

min_size = 2

disk_size = 20

kubernetes_labels = {}
