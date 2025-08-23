[string]$EKSBinDir = "$env:ProgramFiles\Amazon\EKS"
[string]$EKSBootstrapScriptName = 'Start-EKSBootstrap.ps1'
[string]$EKSBootstrapScriptFile = "$EKSBinDir\$EKSBootstrapScriptName"

& $EKSBootstrapScriptFile -EKSClusterName "${cluster_name}" -APIServerEndpoint "${cluster_endpoint}" -Base64ClusterCA "${certificate_authority_data}" ${bootstrap_extra_args} -KubeletExtraArgs "${kubelet_extra_args}" 3>&1 4>&1 5>&1 6>&1
