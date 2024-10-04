param (
  [string] $buildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Host "Customize (Start): Job Scheduler"

if ($binPaths -ne "") {
  Write-Host "Customize (PATH): $($binPaths.substring(1))"
  setx PATH "$env:PATH$binPaths" /m
}

Write-Host "Customize (End): Job Scheduler"
