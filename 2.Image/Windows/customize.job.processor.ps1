param (
  [string] $imageBuildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Information "(AAA Start): Job Processor"

if ($jobProcessors -contains "PBRT") {
  Write-Information "(AAA Start): PBRT"
  $appVersion = $imageBuildConfig.appVersion.jobProcessorPBRT
  $fileType = "pbrt"
  $filePath = "C:\Program Files\PBRT"
  New-Item -ItemType Directory -Path "$filePath" -Force
  RunProcess "$Env:GIT_BIN_PATH\git.exe" "clone --recursive https://github.com/mmp/$fileType-$appVersion.git" $fileType-1
  RunProcess "$Env:CMAKE_BIN_PATH\cmake.exe" "-B ""$filePath"" -S $aaaRoot\$fileType-$appVersion" $fileType-2
  RunProcess "$Env:MSBUILD_BIN_PATH\MSBuild.exe" """$filePath\PBRT-$appVersion.sln"" -p:Configuration=Release" $fileType-3
  $aaaPath += ";$filePath\Release"
  Write-Information "(AAA End): PBRT"
}

if ($jobProcessors -contains "Blender") {
  Write-Information "(AAA Start): Blender"
  $appVersion = $imageBuildConfig.appVersion.jobProcessorBlender
  $fileType = "blender"
  $fileName = "$fileType-$appVersion-windows-x64.msi"
  $fileLink = "$($blobStorage.endpointUrl)/Blender/$appVersion/$fileName"
  DownloadFile $fileName $fileLink $true
  RunProcess $fileName "/quiet /norestart /log $fileType.log" $null
  $aaaPath += ";C:\Program Files\Blender Foundation\Blender $($appVersion.substring(0, 3))"
  Write-Information "(AAA End): Blender"
}

if ($aaaPath -ne "") {
  Write-Information "(AAA Path): $($aaaPath.substring(1))"
  [Environment]::SetEnvironmentVariable("PATH", "$Env:PATH$aaaPath", "Machine")
}

Write-Information "(AAA End): Job Processor"
