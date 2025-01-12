param (
  [string] $buildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Host "Customize (Start): Core"

Write-Host "Customize (Start): Resize Root Partition"
$osDriveLetter = "C"
$partitionSizeActive = (Get-Partition -DriveLetter $osDriveLetter).Size
$partitionSizeRange = Get-PartitionSupportedSize -DriveLetter $osDriveLetter
if ($partitionSizeActive -lt $partitionSizeRange.SizeMax) {
  Resize-Partition -DriveLetter $osDriveLetter -Size $partitionSizeRange.SizeMax
}
Write-Host "Customize (End): Resize Root Partition"

Write-Host "Customize (Start): Image Build Platform"
netsh advfirewall set allprofiles state off

Write-Host "Customize (Start): Chocolatey"
$fileType = "chocolatey"
$fileName = "$fileType.ps1"
$fileLink = "https://community.chocolatey.org/install.ps1"
DownloadFile $fileName $fileLink
RunProcess PowerShell.exe "-ExecutionPolicy Unrestricted -File .\$fileName" "$binDirectory\$fileType"
$binPathChoco = "C:\ProgramData\chocolatey"
$binPaths += ";$binPathChoco"
Write-Host "Customize (End): Chocolatey"

Write-Host "Customize (Start): Python"
$fileType = "python"
RunProcess "$binPathChoco\choco.exe" "install $fileType --confirm --no-progress" "$binDirectory\$fileType"
Write-Host "Customize (End): Python"

Write-Host "Customize (Start): Git"
$fileType = "git"
RunProcess "$binPathChoco\choco.exe" "install $fileType --confirm --no-progress" "$binDirectory\$fileType"
$binPathGit = "C:\Program Files\Git\bin"
$binPaths += ";$binPathGit"
$Env:GIT_BIN_PATH = $binPathGit
Write-Host "Customize (End): Git"

Write-Host "Customize (Start): 7-Zip"
$fileType = "7zip"
RunProcess "$binPathChoco\choco.exe" "install $fileType --confirm --no-progress" "$binDirectory\$fileType"
Write-Host "Customize (End): 7-Zip"

Write-Host "Customize (Start): Visual Studio Build Tools"
$fileType = "vsBuildTools"
RunProcess "$binPathChoco\choco.exe" "install visualstudio2022buildtools --package-parameters ""--add Microsoft.VisualStudio.Component.Windows11SDK.22621 --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.Component.MSBuild"" --confirm --no-progress" "$binDirectory\$fileType"
$binPathCMake = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
$binPathMSBuild = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64"
$binPaths += ";$binPathCMake;$binPathMSBuild"
$Env:CMAKE_BIN_PATH = $binPathCMake
$Env:MSBUILD_BIN_PATH = $binPathMSBuild
Write-Host "Customize (End): Visual Studio Build Tools"

Write-Host "Customize (End): Image Build Platform"

if ($gpuProvider -eq "AMD") {
  $fileType = "amd-gpu"
  if ($machineType -like "*NG*" -and $machineType -like "*v1*") {
    Write-Host "Customize (Start): AMD GPU (NG v1)"
    $fileName = "$fileType.exe"
    $fileLink = "https://go.microsoft.com/fwlink/?linkid=2248541"
    DownloadFile $fileName $fileLink
    RunProcess .\$fileName "-install -log $binDirectory\$fileType.log" $null
    Write-Host "Customize (End): AMD GPU (NG v1)"
  } elseif ($machineType -like "*NV*" -and $machineType -like "*v4*") {
    Write-Host "Customize (Start): AMD GPU (NV v4)"
    $fileName = "$fileType.exe"
    $fileLink = "https://go.microsoft.com/fwlink/?linkid=2175154"
    DownloadFile $fileName $fileLink
    RunProcess .\$fileName "-install -log $binDirectory\$fileType.log" $null
    Write-Host "Customize (End): AMD GPU (NV v4)"
  }
} elseif ($gpuProvider -eq "NVIDIA") {
  Write-Host "Customize (Start): NVIDIA GPU (GRID)"
  $fileType = "nvidia-gpu-grid"
  $fileName = "$fileType.exe"
  $fileLink = "https://go.microsoft.com/fwlink/?linkid=874181"
  DownloadFile $fileName $fileLink
  RunProcess .\$fileName "-s -n -log:$binDirectory\$fileType" $null
  Write-Host "Customize (End): NVIDIA GPU (GRID)"

  Write-Host "Customize (Start): NVIDIA GPU (CUDA)"
  $version = $buildConfig.version.nvidia_cuda
  $fileType = "nvidia-gpu-cuda"
  $fileName = "cuda_${version}_windows_network.exe"
  $fileLink = "$binHostUrl/NVIDIA/CUDA/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  RunProcess .\$fileName "-s -n -log:$binDirectory\$fileType" $null
  Write-Host "Customize (End): NVIDIA GPU (CUDA)"

  Write-Host "Customize (Start): NVIDIA OptiX"
  $version = $buildConfig.version.nvidia_optix
  $fileType = "nvidia-optix"
  $fileName = "NVIDIA-OptiX-SDK-$version-win64$($buildConfig.version.nvidia_optix_suffix).exe"
  $fileLink = "$binHostUrl/NVIDIA/OptiX/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  RunProcess .\$fileName "/S" $null
  $sdkDirectory = "C:\ProgramData\NVIDIA Corporation\OptiX SDK $version\SDK"
  $buildDirectory = "$sdkDirectory\build"
  New-Item -ItemType Directory $buildDirectory
  $version = ($buildConfig.version.nvidia_cuda -split '\.')[0..1] -join '.'
  RunProcess "$binPathCMake\cmake.exe" "-B ""$buildDirectory"" -S ""$sdkDirectory"" -D CUDA_TOOLKIT_ROOT_DIR=""C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\v$version""" "$binDirectory\$fileType-1"
  RunProcess "$binPathMSBuild\MSBuild.exe" """$buildDirectory\OptiX-Samples.sln"" -p:Configuration=Release" "$binDirectory\$fileType-2"
  $binPaths += ";$buildDirectory\bin\Release"
  Write-Host "Customize (End): NVIDIA OptiX"
}

if ($machineType -eq "JobScheduler") {
  Write-Host "Customize (Start): Azure CLI (x64)"
  $fileType = "azure-cli"
  $fileName = "$fileType.msi"
  $fileLink = "https://aka.ms/installazurecliwindowsx64"
  DownloadFile $fileName $fileLink
  RunProcess $fileName "/quiet /norestart /log $fileType.log" $null
  Write-Host "Customize (End): Azure CLI (x64)"
} else {
  Write-Host "Customize (Start): NFS Client"
  $fileType = "nfs-client"
  dism /Online /NoRestart /LogPath:"$binDirectory\$fileType" /Enable-Feature /FeatureName:ClientForNFS-Infrastructure /All
  Write-Host "Customize (End): NFS Client"

  Write-Host "Customize (Start): AD Tools"
  $fileType = "ad-tools" # RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
  dism /Online /NoRestart /LogPath:"$binDirectory\$fileType" /Add-Capability /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
  Write-Host "Customize (End): AD Tools"
}

if ($machineType -eq "Farm") {
  Write-Host "Customize (Start): Privacy Experience"
  $registryKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE"
  New-Item -ItemType Directory -Path $registryKeyPath -Force
  New-ItemProperty -Path $registryKeyPath -PropertyType DWORD -Name "DisablePrivacyExperience" -Value 1 -Force
  Write-Host "Customize (End): Privacy Experience"
}

if ($machineType -eq "Workstation") {
  Write-Host "Customize (Start): HP Anyware"
  $version = $buildConfig.version.hp_anyware_agent
  $fileType = if ([string]::IsNullOrEmpty($gpuProvider)) {"pcoip-agent-standard"} else {"pcoip-agent-graphics"}
  $fileName = "${fileType}_$version.exe"
  $fileLink = "$binHostUrl/Teradici/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  RunProcess .\$fileName "/S /NoPostReboot /Force" "$binDirectory\$fileType"
  Write-Host "Customize (End): HP Anyware"
}

if ($machineType -ne "JobScheduler") {
  Write-Host "Customize (Start): Cinebench"
  $version = "2024"
  $fileName = "Cinebench${version}_win_x86_64.zip"
  $fileLink = "$binHostUrl/Maxon/Cinebench/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  Expand-Archive -Path $fileName
  Write-Host "Customize (End): Cinebench"
}

if ($binPaths -ne "") {
  Write-Host "Customize (PATH): $($binPaths.substring(1))"
  [Environment]::SetEnvironmentVariable("PATH", "$Env:PATH$binPaths", "Machine")
}

Write-Host "Customize (End): Core"
