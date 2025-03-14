param (
  [string] $buildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Host "Customize (Start): Job Scheduler"

if ($jobSchedulers -contains "Deadline") {
  $version = $buildConfig.version.job_scheduler_deadline
  $databaseHost = $(hostname)
  $databasePath = "C:\DeadlineData"
  $deadlinePath = "C:\DeadlineServer"
  $deadlineCertificate = "Deadline10Client.pfx"
  $binPathJobScheduler = "$deadlinePath\bin"

  Write-Host "Customize (Start): Deadline Download"
  $fileName = "Deadline-$version-windows-installers.zip"
  $fileLink = "${blobStorage.endpointUrl}/Deadline/$version/$fileName"
  DownloadFile $fileName $fileLink
  Expand-Archive -Path $fileName
  Write-Host "Customize (End): Deadline Download"

  Set-Location -Path Deadline*
  if ($machineType -eq "Scheduler") {
    Write-Host "Customize (Start): Deadline Server"
    $fileType = "deadline-repository"
    $fileName = "DeadlineRepository-$version-windows-installer.exe"
    RunProcess .\$fileName "--mode unattended --dbLicenseAcceptance accept --prefix $deadlinePath --dbhost $databaseHost --mongodir $databasePath --installmongodb true" "$binDirectory\$fileType"
    Move-Item -Path $Env:TMP\installbuilder_installer.log -Destination $binDirectory\$fileType.log
    Copy-Item -Path $databasePath\certs\$deadlineCertificate -Destination $deadlinePath\$deadlineCertificate
    New-NfsShare -Name "Deadline" -Path $deadlinePath -Permission ReadWrite
    Write-Host "Customize (End): Deadline Server"
  }

  Write-Host "Customize (Start): Deadline Client"
  $fileType = "deadline-client"
  $fileName = "DeadlineClient-$version-windows-installer.exe"
  $fileArgs = "--mode unattended --prefix $deadlinePath"
  $workerService = "false"
  $workerStartup = "false"
  if ($machineType -eq "Cluster") {
    $workerService = "true"
    $workerStartup = "true"
    $securePassword = ConvertTo-SecureString $servicePassword -AsPlainText -Force
    New-LocalUser -Name $serviceUsername -Password $securePassword -PasswordNeverExpires
    $fileArgs = "$fileArgs --serviceuser $serviceUsername --servicepassword $servicePassword"
  }
  $fileArgs = "$fileArgs --launcherservice $workerService --slavestartup $workerStartup"
  RunProcess .\$fileName $fileArgs "$binDirectory\$fileType"
  Move-Item -Path $Env:TMP\installbuilder_installer.log -Destination $binDirectory\$fileType.log
  Set-Location -Path $binDirectory
  Write-Host "Customize (End): Deadline Client"

  Write-Host "Customize (Start): Deadline Repository"
  $taskName = "AAA Deadline Repository"
  if ($machineType -eq "Scheduler") {
    $taskAction = New-ScheduledTaskAction -Execute "$binPathJobScheduler\deadlinecommand.exe" -Argument "-ChangeRepository Direct $deadlinePath $deadlinePath\$deadlineCertificate"
  } else {
    $taskAction = New-ScheduledTaskAction -Execute "$binPathJobScheduler\deadlinecommand.exe" -Argument "-ChangeRepository Direct S:\ S:\$deadlineCertificate"
  }
  $taskTrigger = New-ScheduledTaskTrigger -AtLogOn
  $taskPrincipal = New-ScheduledTaskPrincipal -GroupId "Users"
  $task = New-ScheduledTask -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal
  Register-ScheduledTask -TaskName $taskName -InputObject $task
  Write-Host "Customize (End): Deadline Repository"

  Write-Host "Customize (Start): Deadline Monitor"
  $shortcutPath = "$Env:AllUsersProfile\Desktop\Deadline Monitor.lnk"
  $scriptShell = New-Object -ComObject WScript.Shell
  $shortcut = $scriptShell.CreateShortcut($shortcutPath)
  $shortcut.WorkingDirectory = $binPathJobScheduler
  $shortcut.TargetPath = "$binPathJobScheduler\deadlinemonitor.exe"
  $shortcut.Save()
  Write-Host "Customize (End): Deadline Monitor"

  $binPaths += ";$binPathJobScheduler"
}

if ($binPaths -ne "") {
  Write-Host "Customize (PATH): $($binPaths.substring(1))"
  [Environment]::SetEnvironmentVariable("PATH", "$Env:PATH$binPaths", "Machine")
}

Write-Host "Customize (End): Job Scheduler"
