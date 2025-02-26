param (
  [string] $buildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Host "Customize (Start): Core (GPU)"

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
}

if ($gpuProvider -eq "NVIDIA.GRID") {
  Write-Host "Customize (Start): NVIDIA GPU (GRID)"
  $fileType = "nvidia-gpu-grid"
  $fileName = "$fileType.exe"
  $fileLink = "https://go.microsoft.com/fwlink/?linkid=874181"
  DownloadFile $fileName $fileLink
  RunProcess .\$fileName "-s -n -log:$binDirectory\$fileType" $null
  Write-Host "Customize (End): NVIDIA GPU (GRID)"

  Write-Host "Customize (Start): NVIDIA OptiX"
  $version = $buildConfig.version.nvidia_optix
  $fileType = "nvidia-optix"
  $fileName = "NVIDIA-OptiX-SDK-$version-win64.exe"
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

if ($gpuProvider.StartsWith("NVIDIA")) {
  Write-Host "Customize (Start): NVIDIA GPU (CUDA)"
  $version = $buildConfig.version.nvidia_cuda
  $fileType = "nvidia-gpu-cuda"
  $fileName = "cuda_${version}_windows_network.exe"
  $fileLink = "$binHostUrl/NVIDIA/CUDA/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  RunProcess .\$fileName "-s -n -log:$binDirectory\$fileType" $null
  Write-Host "Customize (End): NVIDIA GPU (CUDA)"
}

if ($binPaths -ne "") {
  Write-Host "Customize (PATH): $($binPaths.substring(1))"
  [Environment]::SetEnvironmentVariable("PATH", "$Env:PATH$binPaths", "Machine")
}

Write-Host "Customize (End): Core (GPU)"
