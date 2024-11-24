param (
  [string] $buildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Host "Customize (Start): Job Scheduler (LSF)"

if ($machineType -ne "Storage") {
  $version = $buildConfig.version.job_scheduler_lsf
  # $installRoot = "C:\LSF"

  Write-Host "Customize (Start): LSF Download"
  $fileName = "pacdesktop_client${version}_win-x64.msi"
  $fileLink = "$binHostUrl/LSF/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  Write-Host "Customize (End): LSF Download"
}

if ($binPaths -ne "") {
  Write-Host "Customize (PATH): $($binPaths.substring(1))"
  setx PATH "$env:PATH$binPaths" /m
}

Write-Host "Customize (End): Job Scheduler (LSF)"
