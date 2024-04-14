$binDirectory = "C:\Users\Public\Downloads"
Set-Location -Path $binDirectory

Import-Module -Name C:\AzureData\functions.psm1 -Function * -Variable *

if ("${pcoipLicenseKey}" -ne "") {
  $installFile = "C:\Program Files\Teradici\PCoIP Agent\pcoip-register-host.ps1"
  RunProcess PowerShell.exe "-ExecutionPolicy Unrestricted -File ""$installFile"" -RegistrationCode ${pcoipLicenseKey}" $binDirectory/pcoip-agent-license
}

SetFileSystems (ConvertFrom-Json -InputObject '${jsonencode(fileSystems)}')

Start-ScheduledTask -TaskName $jobSchedulerTaskName

SetActiveDirectory (ConvertFrom-Json -InputObject '${jsonencode(activeDirectory)}')
