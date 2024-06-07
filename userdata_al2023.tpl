MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex

# In multipart MIME format to support EKS appending to it

/etc/eks/bootstrap.sh ipv4-prefix-delegation  --apiserver-endpoint '${cluster_endpoint}' --b64-cluster-ca '${certificate_authority_data}' --container-runtime containerd  --dns-cluster-ip 172.20.0.10 


--==MYBOUNDARY==
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${cluster_name}
    apiServerEndpoint: ${cluster_endpoint}
    certificateAuthority: ${certificate_authority_data}
  {{ if .kubelet_extra_args }}
  kubelet:
    flags: ${kubelet_extra_args}
  {{ end }}


--==MYBOUNDARY==--    
