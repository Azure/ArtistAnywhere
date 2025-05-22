$ErrorActionPreference = "Stop"

if ("${machineType}" -eq "WinServer") {
  Install-WindowsFeature -Name "AD-Domain-Services" -IncludeManagementTools

  $securePassword = ConvertTo-SecureString ${activeDirectory.machine.adminLogin.userPassword} -AsPlainText -Force
  Install-ADDSForest -DomainName "${activeDirectory.domainName}" -SafeModeAdministratorPassword $securePassword -InstallDns -Force
} else {
  $scriptFile = "C:\AzureData\functions.ps1"
  Copy-Item -Path "C:\AzureData\CustomData.bin" -Destination $scriptFile
  . $scriptFile

  $fileType = "ad-tools" # RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
  dism /Online /NoRestart /LogPath:"$binDirectory\$fileType" /Add-Capability /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

  JoinActiveDirectory -activeDirectory (ConvertFrom-Json -InputObject '${jsonencode(activeDirectory)}')
}
