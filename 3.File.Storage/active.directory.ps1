$ErrorActionPreference = "Stop"

netsh advfirewall set allprofiles state off

Install-WindowsFeature -Name "AD-Domain-Services" -IncludeManagementTools

$securePassword = ConvertTo-SecureString ${activeDirectory.machine.adminLogin.userPassword} -AsPlainText -Force
Install-ADDSForest -DomainName "${activeDirectory.domainName}" -SafeModeAdministratorPassword $securePassword -InstallDns -Force
