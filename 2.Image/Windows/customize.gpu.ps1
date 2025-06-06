param (
  [string] $imageBuildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Information "(AAA Start): Core (GPU)"

if ($gpuProvider -eq "AMD") {
  $fileType = "amd-gpu"
  if ($machineType -like "*NG*" -and $machineType -like "*v1*") {
    Write-Information "(AAA Start): AMD GPU (NG v1)"
    $fileName = "$fileType.exe"
    $fileLink = "https://go.microsoft.com/fwlink/?linkid=2248541"
    DownloadFile $fileName $fileLink $false
    RunProcess .\$fileName "-install -log $aaaRoot\$fileType.log" $null
    Write-Information "(AAA End): AMD GPU (NG v1)"
  } elseif ($machineType -like "*NV*" -and $machineType -like "*v4*") {
    Write-Information "(AAA Start): AMD GPU (NV v4)"
    $fileName = "$fileType.exe"
    $fileLink = "https://go.microsoft.com/fwlink/?linkid=2175154"
    DownloadFile $fileName $fileLink $false
    RunProcess .\$fileName "-install -log $aaaRoot\$fileType.log" $null
    Write-Information "(AAA End): AMD GPU (NV v4)"
  }
}

if ($gpuProvider -eq "NVIDIA.GRID") {
  Write-Information "(AAA Start): NVIDIA GPU (GRID)"
  $fileType = "nvidia-gpu-grid"
  $fileName = "$fileType.exe"
  $fileLink = "https://go.microsoft.com/fwlink/?linkid=874181"
  DownloadFile $fileName $fileLink $false
  RunProcess .\$fileName "-s -n -log:$aaaRoot\$fileType" $null
  Write-Information "(AAA End): NVIDIA GPU (GRID)"
}

if ($gpuProvider.StartsWith("NVIDIA")) {
  Write-Information "(AAA Start): NVIDIA GPU (CUDA)"
  $appVersion = $imageBuildConfig.appVersion.nvidiaCUDAWindows
  $fileType = "nvidia-gpu-cuda"
  $fileName = "cuda_${appVersion}_windows_network.exe"
  $fileLink = "$($blobStorage.endpointUrl)/NVIDIA/CUDA/$appVersion/$fileName"
  DownloadFile $fileName $fileLink $true
  RunProcess .\$fileName "-s -n -log:$aaaRoot\$fileType" $null
  Write-Information "(AAA End): NVIDIA GPU (CUDA)"
}

if ($aaaPath -ne "") {
  Write-Information "(AAA Path): $($aaaPath.substring(1))"
  [Environment]::SetEnvironmentVariable("PATH", "$Env:PATH$aaaPath", "Machine")
}

Write-Information "(AAA End): Core (GPU)"
