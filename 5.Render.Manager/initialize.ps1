$binDirectory = "C:\Users\Public\Downloads"
Set-Location -Path $binDirectory

sc start Deadline10DatabaseService

if ("${activeDirectory.enable}" -eq $true) {
  $securePassword = ConvertTo-SecureString ${adminPassword} -AsPlainText -Force
  Install-ADDSForest -DomainName "${activeDirectory.domainName}" -SafeModeAdministratorPassword $securePassword -InstallDns -Force
}
