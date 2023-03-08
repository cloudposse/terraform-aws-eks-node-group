<powershell>
try{
${before_cluster_joining_userdata}
}catch{
    Write-Host "An error occurred in pre-script" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
}
Write-Host -Foreground Red -Background Black ($formatstring -f $fields)

# Deal with extra new disks
$disks_to_adjust = Get-Disk | Select-Object Number,Size,PartitionStyle | Where-Object PartitionStyle -Match RAW
if ($disks_to_adjust -ne $null) {
  [int64] $partition_mbr_max_size = 2199023255552
  $partition_style = "MBR"
  foreach ($disk in $disks_to_adjust) {
    if ($disk.Size -gt $partition_mbr_max_size) {
      $partition_style = "GPT"
    }

    Initialize-Disk -Number $disk.Number -PartitionStyle $partition_style
    New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS
  }
}

[string]$EKSBinDir = "$env:ProgramFiles\Amazon\EKS"
[string]$EKSBootstrapScriptName = 'Start-EKSBootstrap.ps1'
[string]$EKSBootstrapScriptFile = "$EKSBinDir\$EKSBootstrapScriptName"

& $EKSBootstrapScriptFile -EKSClusterName "${cluster_name}" -APIServerEndpoint "${cluster_endpoint}" -Base64ClusterCA "${certificate_authority_data}" ${bootstrap_extra_args} -KubeletExtraArgs "${kubelet_extra_args}" 3>&1 4>&1 5>&1 6>&1

try{
${after_cluster_joining_userdata}
}catch{
  Write-Host "An error occurred in post-script" -ForegroundColor Red
  Write-Host $_.ScriptStackTrace
}
</powershell>
