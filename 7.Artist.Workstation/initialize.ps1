$binDirectory = "C:\Users\Public\Downloads"
Set-Location -Path $binDirectory

. C:\AzureData\functions.ps1

if ("${pcoipLicenseKey}" -ne "") {
  $installFile = "C:\Program Files\Teradici\PCoIP Agent\pcoip-register-host.ps1"
  RunProcess PowerShell.exe "-ExecutionPolicy Unrestricted -File ""$installFile"" -RegistrationCode ${pcoipLicenseKey}" $binDirectory/pcoip-agent-license
}

SetFileSystems (ConvertFrom-Json -InputObject '${jsonencode(fileSystems)}')

Start-ScheduledTask -TaskName $jobSchedulerTaskName

SetActiveDirectory (ConvertFrom-Json -InputObject '${jsonencode(activeDirectory)}')
