. C:\AzureData\functions.ps1

if ("${remoteAgentKey}" -ne "") {
  $installFile = "C:\Program Files\Teradici\PCoIP Agent\pcoip-register-host.ps1"
  RunProcess PowerShell.exe "-ExecutionPolicy Unrestricted -File ""$installFile"" -RegistrationCode ${remoteAgentKey}" $binDirectory/pcoip-agent-license
}

SetFileSystem (ConvertFrom-Json -InputObject '${jsonencode(fileSystem)}')

SetActiveDirectory (ConvertFrom-Json -InputObject '${jsonencode(activeDirectory)}')
