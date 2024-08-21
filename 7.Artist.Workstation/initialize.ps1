. C:\AzureData\functions.ps1

if ("${remoteAgentKey}" -ne "") {
  $installFile = "C:\Program Files\Teradici\PCoIP Agent\pcoip-register-host.ps1"
  RunProcess PowerShell.exe "-ExecutionPolicy Unrestricted -File ""$installFile"" -RegistrationCode ${remoteAgentKey}" $binDirectory/pcoip-agent-license
}

SetFileSystems (ConvertFrom-Json -InputObject '${jsonencode(fileSystems)}')

Start-ScheduledTask -TaskName $jobManagerTaskName

SetActiveDirectory (ConvertFrom-Json -InputObject '${jsonencode(activeDirectory)}')
