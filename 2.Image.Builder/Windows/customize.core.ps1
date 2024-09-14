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
$processType = "chocolatey"
$installFile = "$processType.ps1"
$downloadUrl = "https://community.chocolatey.org/install.ps1"
(New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
RunProcess PowerShell.exe "-ExecutionPolicy Unrestricted -File .\$installFile" "$binDirectory\$processType"
$binPathChoco = "C:\ProgramData\chocolatey"
$binPaths += ";$binPathChoco"
Write-Host "Customize (End): Chocolatey"

Write-Host "Customize (Start): Python"
$processType = "python"
RunProcess "$binPathChoco\choco.exe" "install $processType --confirm --no-progress" "$binDirectory\$processType"
Write-Host "Customize (End): Python"

if ($machineType -eq "Workstation") {
  Write-Host "Customize (Start): Node.js"
  $processType = "nodejs"
  RunProcess "$binPathChoco\choco.exe" "install $processType --confirm --no-progress" "$binDirectory\$processType"
  Write-Host "Customize (End): Node.js"
}

Write-Host "Customize (Start): Git"
$processType = "git"
RunProcess "$binPathChoco\choco.exe" "install $processType --confirm --no-progress" "$binDirectory\$processType"
$binPathGit = "C:\Program Files\Git\bin"
$binPaths += ";$binPathGit"
$env:GIT_BIN_PATH = $binPathGit
Write-Host "Customize (End): Git"

Write-Host "Customize (Start): 7-Zip"
$processType = "7zip"
RunProcess "$binPathChoco\choco.exe" "install $processType --confirm --no-progress" "$binDirectory\$processType"
Write-Host "Customize (End): 7-Zip"

Write-Host "Customize (Start): Visual Studio Build Tools"
$processType = "vsBuildTools"
RunProcess "$binPathChoco\choco.exe" "install visualstudio2022buildtools --package-parameters ""--add Microsoft.VisualStudio.Component.Windows11SDK.22621 --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.Component.MSBuild"" --confirm --no-progress" "$binDirectory\$processType"
$binPathCMake = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
$binPathMSBuild = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64"
$binPaths += ";$binPathCMake;$binPathMSBuild"
$env:CMAKE_BIN_PATH = $binPathCMake
$env:MSBUILD_BIN_PATH = $binPathMSBuild
Write-Host "Customize (End): Visual Studio Build Tools"

Write-Host "Customize (End): Image Build Platform"

if ($gpuProvider -eq "AMD") {
  $processType = "amd-gpu"
  if ($machineType -like "*NG*" -and $machineType -like "*v1*") {
    Write-Host "Customize (Start): AMD GPU (NG v1)"
    $installFile = "$processType.exe"
    $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2248541"
    (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
    RunProcess .\$installFile "-install -log $binDirectory\$processType.log" $null
    Write-Host "Customize (End): AMD GPU (NG v1)"
  } elseif ($machineType -like "*NV*" -and $machineType -like "*v4*") {
    Write-Host "Customize (Start): AMD GPU (NV v4)"
    $installFile = "$processType.exe"
    $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2175154"
    (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
    RunProcess .\$installFile "-install -log $binDirectory\$processType.log" $null
    Write-Host "Customize (End): AMD GPU (NV v4)"
  }
} elseif ($gpuProvider -eq "NVIDIA") {
  Write-Host "Customize (Start): NVIDIA GPU (GRID)"
  $processType = "nvidia-gpu-grid"
  $installFile = "$processType.exe"
  $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=874181"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess .\$installFile "-s -n -log:$binDirectory\$processType" $null
  Write-Host "Customize (End): NVIDIA GPU (GRID)"

  Write-Host "Customize (Start): NVIDIA GPU (CUDA)"
  $versionPath = $buildConfig.versionPath.nvidiaCUDA
  $processType = "nvidia-gpu-cuda"
  $installFile = "cuda_${versionPath}_windows_network.exe"
  $downloadUrl = "$binStorageHost/NVIDIA/CUDA/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess .\$installFile "-s -n -log:$binDirectory\$processType" $null
  Write-Host "Customize (End): NVIDIA GPU (CUDA)"

  Write-Host "Customize (Start): NVIDIA OptiX"
  $versionPath = $buildConfig.versionPath.nvidiaOptiX
  $processType = "nvidia-optix"
  $installFile = "NVIDIA-OptiX-SDK-$versionPath-win64.exe"
  $downloadUrl = "$binStorageHost/NVIDIA/OptiX/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess .\$installFile "/S" $null
  $sdkDirectory = "C:\ProgramData\NVIDIA Corporation\OptiX SDK $versionPath\SDK"
  $buildDirectory = "$sdkDirectory\build"
  New-Item -ItemType Directory $buildDirectory
  $versionPath = ($buildConfig.versionPath.nvidiaCUDA -split '\.')[0..1] -join '.'
  RunProcess "$binPathCMake\cmake.exe" "-B ""$buildDirectory"" -S ""$sdkDirectory"" -D CUDA_TOOLKIT_ROOT_DIR=""C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\v$versionPath""" "$binDirectory\$processType-1"
  RunProcess "$binPathMSBuild\MSBuild.exe" """$buildDirectory\OptiX-Samples.sln"" -p:Configuration=Release" "$binDirectory\$processType-2"
  $binPaths += ";$buildDirectory\bin\Release"
  Write-Host "Customize (End): NVIDIA OptiX"
}

if ($machineType -eq "Storage" -or $machineType -eq "JobManager") {
  Write-Host "Customize (Start): Azure CLI (x64)"
  $processType = "azure-cli"
  $installFile = "$processType.msi"
  $downloadUrl = "https://aka.ms/installazurecliwindowsx64"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess $installFile "/quiet /norestart /log $processType.log" $null
  Write-Host "Customize (End): Azure CLI (x64)"
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
  $versionPath = $buildConfig.versionPath.hpAnywareAgent
  $processType = if ([string]::IsNullOrEmpty($gpuProvider)) {"pcoip-agent-standard"} else {"pcoip-agent-graphics"}
  $installFile = "${processType}_$versionPath.exe"
  $downloadUrl = "$binStorageHost/Teradici/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess .\$installFile "/S /NoPostReboot /Force" "$binDirectory\$processType"
  Write-Host "Customize (End): HP Anyware"
}

if ($machineType -ne "JobManager") {
  Write-Host "Customize (Start): Cinebench"
  $versionPath = "2024"
  $installFile = "Cinebench${versionPath}_win_x86_64.zip"
  $downloadUrl = "$binStorageHost/Maxon/Cinebench/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  Expand-Archive -Path $installFile
  Write-Host "Customize (End): Cinebench"
}

if ($binPaths -ne "") {
  Write-Host "Customize (PATH): $($binPaths.substring(1))"
  setx PATH "$env:PATH$binPaths" /m
}

Write-Host "Customize (End): Core"
