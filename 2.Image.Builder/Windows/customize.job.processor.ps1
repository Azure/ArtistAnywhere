param (
  [string] $buildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Host "Customize (Start): Job Processor"

if ($jobProcessors -contains "PBRT") {
  Write-Host "Customize (Start): PBRT"
  $appVersion = $buildConfig.appVersion.jobProcessorPBRT
  $fileType = "pbrt"
  $filePath = "C:\Program Files\PBRT"
  New-Item -ItemType Directory -Path "$filePath" -Force
  RunProcess "$Env:GIT_BIN_PATH\git.exe" "clone --recursive https://github.com/mmp/$fileType-$appVersion.git" "$binDirectory\$fileType-1"
  RunProcess "$Env:CMAKE_BIN_PATH\cmake.exe" "-B ""$filePath"" -S $binDirectory\$fileType-$appVersion" "$binDirectory\$fileType-2"
  RunProcess "$Env:MSBUILD_BIN_PATH\MSBuild.exe" """$filePath\PBRT-$appVersion.sln"" -p:Configuration=Release" "$binDirectory\$fileType-3"
  $binPaths += ";$filePath\Release"
  Write-Host "Customize (End): PBRT"
}

if ($jobProcessors -contains "Blender") {
  Write-Host "Customize (Start): Blender"
  $appVersion = $buildConfig.appVersion.jobProcessorBlender
  $fileType = "blender"
  $fileName = "$fileType-$appVersion-windows-x64.msi"
  $fileLink = "$($blobStorage.endpointUrl)/Blender/$appVersion/$fileName"
  DownloadFile $fileName $fileLink $true
  RunProcess $fileName "/quiet /norestart /log $fileType.log" $null
  $binPaths += ";C:\Program Files\Blender Foundation\Blender $($appVersion.substring(0, 3))"
  Write-Host "Customize (End): Blender"
}

if ($binPaths -ne "") {
  Write-Host "Customize (PATH): $($binPaths.substring(1))"
  [Environment]::SetEnvironmentVariable("PATH", "$Env:PATH$binPaths", "Machine")
}

Write-Host "Customize (End): Job Processor"
