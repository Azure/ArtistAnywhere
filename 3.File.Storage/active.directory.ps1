$ErrorActionPreference = "Stop"

$securePassword = ConvertTo-SecureString ${activeDirectory.machine.adminLogin.userPassword} -AsPlainText -Force
Install-ADDSForest -DomainName "${activeDirectory.domainName}" -SafeModeAdministratorPassword $securePassword -InstallDns -Force

Add-DnsServerForwarder -IPAddress ${join(",", dnsResolver.ipAddresses)} -PassThru
