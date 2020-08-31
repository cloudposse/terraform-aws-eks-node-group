Content-Type: text/x-shellscript
Content-Type: charset="us-ascii"

/etc/eks/bootstrap.sh ${cluster_name} --kubelet-extra-args "--node-labels=eks.amazonaws.com/nodegroup=${node_group_name},eks.amazonaws.com/nodegroup-image=${ami_id}"
--//