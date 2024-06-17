MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

%{ if length(before_cluster_joining_userdata) > 0 ~}
--//
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash

${before_cluster_joining_userdata}

%{ endif ~}
%{~ if length(kubelet_extra_args_yaml) > 0 }
--//
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  kubelet:
    flags: ${kubelet_extra_args_yaml}

%{~ endif }

--//--
