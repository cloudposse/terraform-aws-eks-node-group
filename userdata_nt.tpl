<powershell>
[string]$EKSBootstrapScriptFile = "$env:ProgramFiles\Amazon\EKS\Start-EKSBootstrap.ps1"

${before_cluster_joining_userdata}

& $EKSBootstrapScriptFile -EKSClusterName "${cluster_name}" -APIServerEndpoint "${cluster_endpoint}" -Base64ClusterCA "${certificate_authority_data}" -KubeletExtraArgs "${bootstrap_extra_args}" 3>&1 4>&1 5>&1 6>&1
$LastError = if ($?) { 0 } else { $Error[0].Exception.HResult }

${after_cluster_joining_userdata}
</powershell>