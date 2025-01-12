param (
  [string] $buildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Host "Customize (Start): Job Scheduler (LSF)"

$version = $buildConfig.version.job_scheduler_lsf
# $installRoot = "C:\LSF"

Write-Host "Customize (Start): LSF Download"
$fileName = "pacdesktop_client${version}_win-x64.msi"
$fileLink = "$binHostUrl/LSF/$version/$fileName"
DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
Write-Host "Customize (End): LSF Download"

if ($binPaths -ne "") {
  Write-Host "Customize (PATH): $($binPaths.substring(1))"
  [Environment]::SetEnvironmentVariable("PATH", "$Env:PATH$binPaths", "Machine")
}

Write-Host "Customize (End): Job Scheduler (LSF)"
