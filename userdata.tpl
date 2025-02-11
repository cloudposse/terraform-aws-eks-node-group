MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="/:/+++"

--/:/+++
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash

# In multipart MIME format to support EKS appending to it

${before_cluster_joining_userdata}

%{ if length(kubelet_extra_args) > 0 }
export KUBELET_EXTRA_ARGS="${kubelet_extra_args}"
%{ endif }
%{ if length(kubelet_extra_args) > 0 || length (bootstrap_extra_args) > 0 || length (after_cluster_joining_userdata) > 0 }

${bootstrap_script}

${after_cluster_joining_userdata}
%{ endif }

--/:/+++--
