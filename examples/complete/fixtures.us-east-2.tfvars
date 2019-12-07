region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

vpc_cidr_block = "172.16.0.0/16"

namespace = "eg"

stage = "test"

name = "eks-node-group"

instance_types = ["t3.small"]

desired_size = 2

max_size = 3

min_size = 2

disk_size = 20

kubeconfig_path = "/.kube/config"

kubernetes_labels = {}
