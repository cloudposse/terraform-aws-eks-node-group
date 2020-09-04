#!/bin/bash

# userdata for EKS worker nodes to properly configure Kubernetes applications on EC2 instances
# https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
# https://aws.amazon.com/blogs/opensource/improvements-eks-worker-node-provisioning/
# https://github.com/awslabs/amazon-eks-ami/blob/master/files/bootstrap.sh#L97

${before_cluster_joining_userdata}

%{ if length(kubelet_extra_args) > 0 }
export KUBELET_EXTRA_ARGS="${kubelet_extra_args}"
%{ endif }
%{ if length(kubelet_extra_args) > 0 || length (bootstrap_extra_args) > 0 || length (after_cluster_joining_userdata) > 0 }

/etc/eks/bootstrap.sh --apiserver-endpoint '${cluster_endpoint}' --b64-cluster-ca '${certificate_authority_data}' ${bootstrap_extra_args} '${cluster_name}'

${after_cluster_joining_userdata}
%{ endif }