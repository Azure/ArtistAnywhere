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
    DownloadFile $fileName $fileLink $false
    RunProcess .\$fileName "-install -log $binDirectory\$fileType.log" $null
    Write-Host "Customize (End): AMD GPU (NG v1)"
  } elseif ($machineType -like "*NV*" -and $machineType -like "*v4*") {
    Write-Host "Customize (Start): AMD GPU (NV v4)"
    $fileName = "$fileType.exe"
    $fileLink = "https://go.microsoft.com/fwlink/?linkid=2175154"
    DownloadFile $fileName $fileLink $false
    RunProcess .\$fileName "-install -log $binDirectory\$fileType.log" $null
    Write-Host "Customize (End): AMD GPU (NV v4)"
  }
}

if ($gpuProvider -eq "NVIDIA.GRID") {
  Write-Host "Customize (Start): NVIDIA GPU (GRID)"
  $fileType = "nvidia-gpu-grid"
  $fileName = "$fileType.exe"
  $fileLink = "https://go.microsoft.com/fwlink/?linkid=874181"
  DownloadFile $fileName $fileLink $false
  RunProcess .\$fileName "-s -n -log:$binDirectory\$fileType" $null
  Write-Host "Customize (End): NVIDIA GPU (GRID)"
}

if ($gpuProvider.StartsWith("NVIDIA")) {
  Write-Host "Customize (Start): NVIDIA GPU (CUDA)"
  $appVersion = $buildConfig.appVersion.nvidiaCUDAWindows
  $fileType = "nvidia-gpu-cuda"
  $fileName = "cuda_${appVersion}_windows_network.exe"
  $fileLink = "$($blobStorage.endpointUrl)/NVIDIA/CUDA/$appVersion/$fileName"
  DownloadFile $fileName $fileLink $true
  RunProcess .\$fileName "-s -n -log:$binDirectory\$fileType" $null
  Write-Host "Customize (End): NVIDIA GPU (CUDA)"
}

if ($binPaths -ne "") {
  Write-Host "Customize (PATH): $($binPaths.substring(1))"
  [Environment]::SetEnvironmentVariable("PATH", "$Env:PATH$binPaths", "Machine")
}

Write-Host "Customize (End): Core (GPU)"
