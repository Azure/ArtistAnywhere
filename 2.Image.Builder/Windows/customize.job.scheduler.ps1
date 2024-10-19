param (
  [string] $buildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Host "Customize (Start): Job Scheduler"

if ($machineType -ne "JobScheduler") {
  Write-Host "Customize (Start): NFS Client"
  $fileType = "nfs-client"
  dism /Online /NoRestart /LogPath:"$binDirectory\$fileType" /Enable-Feature /FeatureName:ClientForNFS-Infrastructure /All
  Write-Host "Customize (End): NFS Client"

  Write-Host "Customize (Start): AD Tools"
  $fileType = "ad-tools" # RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
  dism /Online /NoRestart /LogPath:"$binDirectory\$fileType" /Add-Capability /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
  Write-Host "Customize (End): AD Tools"
}

Write-Host "Customize (End): Job Scheduler"
