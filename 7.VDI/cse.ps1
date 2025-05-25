. C:\AzureData\functions.ps1

if ("${remoteAgentKey}" -ne "") {
  $fileType = "pcoip-register-host"
  $fileName = "$fileType.ps1"
  $filePath = "C:\Program Files\Teradici\PCoIP Agent"
  RunProcess PowerShell.exe "-ExecutionPolicy Unrestricted -File ""$filePath\$fileName"" -RegistrationCode ${remoteAgentKey}" $fileType
}

SetFileSystem (ConvertFrom-Json -InputObject '${jsonencode(fileSystem)}')

JoinActiveDirectory -activeDirectory (ConvertFrom-Json -InputObject '${jsonencode(activeDirectory)}')
