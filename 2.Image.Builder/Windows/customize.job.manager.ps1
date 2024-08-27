param (
  [string] $buildConfigEncoded
)

$ErrorActionPreference = "Stop"

Write-Host "Customize (Start): Job Manager"

. C:\AzureData\functions.ps1

if ($machineType -ne "JobManager") {
  Write-Host "Customize (Start): NFS Client"
  $processType = "nfs-client"
  dism /Online /NoRestart /LogPath:"$binDirectory\$processType" /Enable-Feature /FeatureName:ClientForNFS-Infrastructure /All
  Write-Host "Customize (End): NFS Client"

  Write-Host "Customize (Start): AD Tools"
  $processType = "ad-tools" # RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
  dism /Online /NoRestart /LogPath:"$binDirectory\$processType" /Add-Capability /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
  Write-Host "Customize (End): AD Tools"
}

if ($machineType -ne "Storage") {
  $versionPath = $buildConfig.versionPath.jobManager
  $installRoot = "C:\Deadline"
  $databaseHost = $(hostname)
  $databasePath = "C:\DeadlineData"
  $certificateFile = "Deadline10Client.pfx"
  $binPathJobManager = "$installRoot\bin"

  Write-Host "Customize (Start): Deadline Download"
  $installFile = "Deadline-$versionPath-windows-installers.zip"
  $downloadUrl = "$binStorageHost/Deadline/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  Expand-Archive -Path $installFile
  Write-Host "Customize (End): Deadline Download"

  Set-Location -Path Deadline*
  if ($machineType -eq "JobManager") {
    Write-Host "Customize (Start): Deadline Server"
    $processType = "deadline-repository"
    $installFile = "DeadlineRepository-$versionPath-windows-installer.exe"
    RunProcess .\$installFile "--mode unattended --dbLicenseAcceptance accept --prefix $installRoot --dbhost $databaseHost --mongodir $databasePath --installmongodb true" "$binDirectory\$processType"
    Move-Item -Path $env:TMP\installbuilder_installer.log -Destination $binDirectory\$processType.log
    Copy-Item -Path $databasePath\certs\$certificateFile -Destination $installRoot\$certificateFile
    New-NfsShare -Name "Deadline" -Path $installRoot -Permission ReadWrite
    Write-Host "Customize (End): Deadline Server"
  }

  Write-Host "Customize (Start): Deadline Client"
  $processType = "deadline-client"
  $installFile = "DeadlineClient-$versionPath-windows-installer.exe"
  $installArgs = "--mode unattended --prefix $installRoot"
  if ($machineType -eq "JobManager") {
    $installArgs = "$installArgs --slavestartup false --launcherservice false"
  } else {
    if ($machineType -eq "Farm") {
      $workerStartup = "true"
    } else {
      $workerStartup = "false"
    }
    $installArgs = "$installArgs --slavestartup $workerStartup --launcherservice true"
  }
  RunProcess .\$installFile $installArgs "$binDirectory\$processType"
  Move-Item -Path $env:TMP\installbuilder_installer.log -Destination $binDirectory\$processType.log
  Set-Location -Path $binDirectory
  Write-Host "Customize (End): Deadline Client"

  Write-Host "Customize (Start): Deadline Scheduled Task"
  $taskTrigger = New-ScheduledTaskTrigger -AtLogOn
  $taskAction = New-ScheduledTaskAction -Execute "deadlinecommand" -Argument "-ChangeRepository Direct S:\ S:\Deadline10Client.pfx"
  if ($machineType -eq "JobManager") {
    $taskAction = New-ScheduledTaskAction -Execute "deadlinecommand" -Argument "-ChangeRepository Direct $installRoot $installRoot\$certificateFile"
  }
  Register-ScheduledTask -TaskName $jobManagerTaskName -Trigger $taskTrigger -Action $taskAction -User System -Force
  Write-Host "Customize (End): Deadline Scheduled Task"

  Write-Host "Customize (Start): Deadline Monitor"
  $shortcutPath = "$env:AllUsersProfile\Desktop\Deadline Monitor.lnk"
  $scriptShell = New-Object -ComObject WScript.Shell
  $shortcut = $scriptShell.CreateShortcut($shortcutPath)
  $shortcut.WorkingDirectory = $binPathJobManager
  $shortcut.TargetPath = "$binPathJobManager\deadlinemonitor.exe"
  $shortcut.Save()
  Write-Host "Customize (End): Deadline Monitor"

  $binPaths += ";$binPathJobManager"
}

Write-Host "Customize (PATH): $($binPaths.substring(1))"
setx PATH "$env:PATH$binPaths" /m

Write-Host "Customize (End): Job Manager"
