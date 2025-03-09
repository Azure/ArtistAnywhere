$scriptFile = "C:\AzureData\functions.ps1"
Copy-Item -Path "C:\AzureData\CustomData.bin" -Destination $scriptFile
. $scriptFile

$fileType = "ad-tools" # RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
dism /Online /NoRestart /LogPath:"$binDirectory\$fileType" /Add-Capability /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

$domainName   = "${activeDirectoryClient.domainName}"
$serverName   = "${activeDirectoryClient.serverName}"
$userName     = "${activeDirectoryClient.machine.adminLogin.userName}"
$userPassword = "${activeDirectoryClient.machine.adminLogin.userPassword}"

JoinActiveDirectory -domainName $domainName -serverName $serverName -userName $userName -userPassword $userPassword
