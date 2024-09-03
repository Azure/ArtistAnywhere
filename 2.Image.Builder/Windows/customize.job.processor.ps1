param (
  [string] $buildConfigEncoded
)

$ErrorActionPreference = "Stop"

Write-Host "Customize (Start): Job Processor"

. C:\AzureData\functions.ps1

if ($jobProcessors -contains "PBRT") {
  Write-Host "Customize (Start): PBRT"
  $versionPath = $buildConfig.versionPath.jobProcessorPBRT
  $processType = "pbrt"
  $installPath = "C:\Program Files\PBRT"
  New-Item -ItemType Directory -Path "$installPath" -Force
  RunProcess "$env:GIT_BIN_PATH\git.exe" "clone --recursive https://github.com/mmp/$processType-$versionPath.git" "$binDirectory\$processType-1"
  RunProcess "$env:CMAKE_BIN_PATH\cmake.exe" "-B ""$installPath"" -S $binDirectory\$processType-$versionPath" "$binDirectory\$processType-2"
  RunProcess "$env:MSBUILD_BIN_PATH\MSBuild.exe" """$installPath\PBRT-$versionPath.sln"" -p:Configuration=Release" "$binDirectory\$processType-3"
  $binPaths += ";$installPath\Release"
  Write-Host "Customize (End): PBRT"
}

if ($jobProcessors -contains "Blender") {
  Write-Host "Customize (Start): Blender"
  $versionPath = $buildConfig.versionPath.jobProcessorBlender
  $processType = "blender"
  $installFile = "$processType-$versionPath-windows-x64.msi"
  $downloadUrl = "$binStorageHost/Blender/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess $installFile "/quiet /norestart /log $processType.log" $null
  $binPaths += ";C:\Program Files\Blender Foundation\Blender $($versionPath.substring(0, 3))"
  Write-Host "Customize (End): Blender"
}

if ($binPaths -ne "") {
  Write-Host "Customize (PATH): $($binPaths.substring(1))"
  setx PATH "$env:PATH$binPaths" /m
}

Write-Host "Customize (End): Job Processor"
