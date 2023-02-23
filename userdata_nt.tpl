<powershell>
[string]$EKSBootstrapScriptFile = "$env:ProgramFiles\Amazon\EKS\Start-EKSBootstrap.ps1"

try{
${before_cluster_joining_userdata}
}catch{
    Write-Host "An error occurred in pre-script" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
}
Write-Host -Foreground Red -Background Black ($formatstring -f $fields)

& $EKSBootstrapScriptFile -EKSClusterName "${cluster_name}" -APIServerEndpoint "${cluster_endpoint}" -Base64ClusterCA "${certificate_authority_data}" --register-with-taints="OS=Windows:NoSchedule" -DNSClusterIP "${dns_address}" -KubeletExtraArgs "${bootstrap_extra_args}"

try{
${after_cluster_joining_userdata}
}catch{
  Write-Host "An error occurred in post-script" -ForegroundColor Red
  Write-Host $_.ScriptStackTrace
}
</powershell>
