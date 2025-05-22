param (
  [string] $buildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Information "(AAA Start): Core"

Write-Information "(AAA Start): Resize Root Partition"
$osDriveLetter = "C"
$partitionSizeActive = (Get-Partition -DriveLetter $osDriveLetter).Size
$partitionSizeRange = Get-PartitionSupportedSize -DriveLetter $osDriveLetter
if ($partitionSizeActive -lt $partitionSizeRange.SizeMax) {
  Resize-Partition -DriveLetter $osDriveLetter -Size $partitionSizeRange.SizeMax
}
Write-Information "(AAA End): Resize Root Partition"

Write-Information "(AAA Start): Image Build Platform"

Write-Information "(AAA Start): Chocolatey"
$fileType = "chocolatey"
$fileName = "$fileType.ps1"
$fileLink = "https://community.chocolatey.org/install.ps1"
DownloadFile $fileName $fileLink $false
RunProcess PowerShell.exe "-ExecutionPolicy Unrestricted -File .\$fileName" "$binDirectory\$fileType"
$binPathChoco = "C:\ProgramData\chocolatey"
$binPaths += ";$binPathChoco"
Write-Information "(AAA End): Chocolatey"

Write-Information "(AAA Start): Python"
$fileType = "python"
RunProcess "$binPathChoco\choco.exe" "install $fileType --confirm --no-progress" "$binDirectory\$fileType"
Write-Information "(AAA End): Python"

Write-Information "(AAA Start): Git"
$fileType = "git"
RunProcess "$binPathChoco\choco.exe" "install $fileType --confirm --no-progress" "$binDirectory\$fileType"
$binPathGit = "C:\Program Files\Git\bin"
$binPaths += ";$binPathGit"
$Env:GIT_BIN_PATH = $binPathGit
Write-Information "(AAA End): Git"

Write-Information "(AAA Start): 7-Zip"
$fileType = "7zip"
RunProcess "$binPathChoco\choco.exe" "install $fileType --confirm --no-progress" "$binDirectory\$fileType"
Write-Information "(AAA End): 7-Zip"

Write-Information "(AAA Start): Visual Studio Build Tools"
$fileType = "vsBuildTools"
RunProcess "$binPathChoco\choco.exe" "install visualstudio2022buildtools --package-parameters ""--add Microsoft.VisualStudio.Component.Windows11SDK.22621 --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.Component.MSBuild"" --confirm --no-progress" "$binDirectory\$fileType"
$binPathCMake = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
$binPathMSBuild = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64"
$binPaths += ";$binPathCMake;$binPathMSBuild"
$Env:CMAKE_BIN_PATH = $binPathCMake
$Env:MSBUILD_BIN_PATH = $binPathMSBuild
Write-Information "(AAA End): Visual Studio Build Tools"

Write-Information "(AAA End): Image Build Platform"

if ($machineType -eq "JobManager") {
  Write-Information "(AAA Start): NFS Server"
  Install-WindowsFeature -Name "FS-NFS-Service"
  Write-Information "(AAA End): NFS Server"

  Write-Information "(AAA Start): Azure CLI (x64)"
  $fileType = "az-cli"
  $fileName = "$fileType.msi"
  $fileLink = "https://aka.ms/installazurecliwindowsx64"
  DownloadFile $fileName $fileLink $false
  RunProcess $fileName "/quiet /norestart /log $fileType.log" $null
  Write-Information "(AAA End): Azure CLI (x64)"
} else {
  Write-Information "(AAA Start): NFS Client"
  $fileType = "nfs-client"
  dism /Online /NoRestart /LogPath:"$binDirectory\$fileType" /Enable-Feature /FeatureName:ClientForNFS-Infrastructure /All
  Write-Information "(AAA End): NFS Client"

  Write-Information "(AAA Start): AD Tools"
  $fileType = "ad-tools" # RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
  dism /Online /NoRestart /LogPath:"$binDirectory\$fileType" /Add-Capability /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
  Write-Information "(AAA End): AD Tools"

  Write-Information "(AAA Start): Cinebench"
  $appVersion = "2024"
  $fileName = "Cinebench${appVersion}_win_x86_64.zip"
  $fileLink = "$($blobStorage.endpointUrl)/Benchmark/Cinebench/$appVersion/$fileName"
  DownloadFile $fileName $fileLink $true
  Expand-Archive -Path $fileName
  Write-Information "(AAA End): Cinebench"
}

if ($machineType -eq "Cluster") {
  Write-Information "(AAA Start): Privacy Experience"
  $registryKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE"
  New-Item -ItemType Directory -Path $registryKeyPath -Force
  New-ItemProperty -Path $registryKeyPath -PropertyType DWORD -Name "DisablePrivacyExperience" -Value 1 -Force
  Write-Information "(AAA End): Privacy Experience"
}

if ($machineType -eq "VDI") {
  Write-Information "(AAA Start): HP Anyware"
  $appVersion = $buildConfig.appVersion.hpAnywareAgent
  $fileType = if ([string]::IsNullOrEmpty($gpuProvider)) {"pcoip-agent-standard"} else {"pcoip-agent-graphics"}
  $fileName = "${fileType}_$appVersion.exe"
  $fileLink = "$($blobStorage.endpointUrl)/Teradici/$appVersion/$fileName"
  DownloadFile $fileName $fileLink $true
  RunProcess .\$fileName "/S /NoPostReboot /Force" "$binDirectory\$fileType"
  Write-Information "(AAA End): HP Anyware"
}

if ($binPaths -ne "") {
  Write-Information "(AAA Path): $($binPaths.substring(1))"
  [Environment]::SetEnvironmentVariable("PATH", "$Env:PATH$binPaths", "Machine")
}

Write-Information "(AAA End): Core"
