param (
  [string] $buildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Host "Customize (Start): Job Processor"

if ($jobProcessors -contains "PBRT") {
  Write-Host "Customize (Start): PBRT"
  $version = $buildConfig.version.jobProcessorPBRT
  $fileType = "pbrt"
  $filePath = "C:\Program Files\PBRT"
  New-Item -ItemType Directory -Path "$filePath" -Force
  RunProcess "$env:GIT_BIN_PATH\git.exe" "clone --recursive https://github.com/mmp/$fileType-$version.git" "$binDirectory\$fileType-1"
  RunProcess "$env:CMAKE_BIN_PATH\cmake.exe" "-B ""$filePath"" -S $binDirectory\$fileType-$version" "$binDirectory\$fileType-2"
  RunProcess "$env:MSBUILD_BIN_PATH\MSBuild.exe" """$filePath\PBRT-$version.sln"" -p:Configuration=Release" "$binDirectory\$fileType-3"
  $binPaths += ";$filePath\Release"
  Write-Host "Customize (End): PBRT"
}

if ($jobProcessors -contains "Blender") {
  Write-Host "Customize (Start): Blender"
  $version = $buildConfig.version.jobProcessorBlender
  $fileType = "blender"
  $fileName = "$fileType-$version-windows-x64.msi"
  $fileHost = "$binHostUrl/Blender/$version"
  DownloadFile $fileName $fileHost $tenantId $clientId $clientSecret $storageVersion
  RunProcess $fileName "/quiet /norestart /log $fileType.log" $null
  $binPaths += ";C:\Program Files\Blender Foundation\Blender $($version.substring(0, 3))"
  Write-Host "Customize (End): Blender"
}

if ($binPaths -ne "") {
  Write-Host "Customize (PATH): $($binPaths.substring(1))"
  setx PATH "$env:PATH$binPaths" /m
}

Write-Host "Customize (End): Job Processor"