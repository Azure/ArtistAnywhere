$fileSystemsPath = "C:\AzureData\fileSystems.bat"

function SetFileSystems ($binDirectory, $fileSystemsJson) {
  $fileSystems = ConvertFrom-Json -InputObject $fileSystemsJson
  foreach ($fileSystem in $fileSystems) {
    if ($fileSystem.enable) {
      SetFileSystemMount $fileSystem.mount
    }
  }
  RegisterFileSystemMounts $binDirectory
}

function SetFileSystemMount ($fileSystemMount) {
  if (!(FileExists $fileSystemsPath)) {
    New-Item -ItemType File -Path $fileSystemsPath
  }
  $mountScript = Get-Content -Path $fileSystemsPath
  if ($mountScript -eq $null -or $mountScript -notlike "*$($fileSystemMount.path)*") {
    $mount = "mount $($fileSystemMount.options) $($fileSystemMount.source) $($fileSystemMount.path)"
    Add-Content -Path $fileSystemsPath -Value $mount
  }
}

function RegisterFileSystemMounts ($binDirectory) {
  if (FileExists $fileSystemsPath) {
    StartProcess $fileSystemsPath $null "$binDirectory\file-system-mount"
    $taskName = "AAA File System Mount"
    $taskAction = New-ScheduledTaskAction -Execute $fileSystemsPath
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -User System -Force
  }
}
