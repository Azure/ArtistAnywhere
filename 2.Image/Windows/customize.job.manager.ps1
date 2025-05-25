param (
  [string] $imageBuildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Information "(AAA Start): Job Manager"

if ($jobManagers -contains "Deadline") {
  $appVersion = $imageBuildConfig.appVersion.jobManagerDeadline
  $databaseHost = $(hostname)
  $databasePath = "C:\DeadlineData"
  $deadlinePath = "C:\DeadlineServer"
  $deadlineCertificate = "Deadline10Client.pfx"
  $aaaPathJobManager = "$deadlinePath\bin"

  Write-Information "(AAA Start): Deadline Download"
  $fileName = "Deadline-$appVersion-windows-installers.zip"
  $fileLink = "$($blobStorage.endpointUrl)/Deadline/$appVersion/$fileName"
  DownloadFile $fileName $fileLink $true
  Expand-Archive -Path $fileName
  Write-Information "(AAA End): Deadline Download"

  Set-Location -Path Deadline*
  if ($machineType -eq "JobManager") {
    Write-Information "(AAA Start): Deadline Server"
    $fileType = "deadline-repository"
    $fileName = "DeadlineRepository-$appVersion-windows-installer.exe"
    RunProcess .\$fileName "--mode unattended --dbLicenseAcceptance accept --prefix $deadlinePath --dbhost $databaseHost --mongodir $databasePath --installmongodb true" "$aaaRoot\$fileType"
    Move-Item -Path $Env:TMP\installbuilder_installer.log -Destination $aaaRoot\$fileType.log
    Copy-Item -Path $databasePath\certs\$deadlineCertificate -Destination $deadlinePath\$deadlineCertificate
    New-NfsShare -Name "Deadline" -Path $deadlinePath -Permission ReadWrite
    Write-Information "(AAA End): Deadline Server"
  }

  Write-Information "(AAA Start): Deadline Client"
  $fileType = "deadline-client"
  $fileName = "DeadlineClient-$appVersion-windows-installer.exe"
  $fileArgs = "--mode unattended --prefix $deadlinePath"
  $workerService = "false"
  $workerStartup = "false"
  if ($machineType -eq "JobCluster") {
    $workerService = "true"
    $workerStartup = "true"
    $securePassword = ConvertTo-SecureString $servicePassword -AsPlainText -Force
    New-LocalUser -Name $serviceUsername -Password $securePassword -PasswordNeverExpires
    $fileArgs = "$fileArgs --serviceuser $serviceUsername --servicepassword $servicePassword"
  }
  $fileArgs = "$fileArgs --launcherservice $workerService --slavestartup $workerStartup"
  RunProcess .\$fileName $fileArgs "$aaaRoot\$fileType"
  Move-Item -Path $Env:TMP\installbuilder_installer.log -Destination $aaaRoot\$fileType.log
  Set-Location -Path $aaaRoot
  Write-Information "(AAA End): Deadline Client"

  Write-Information "(AAA Start): Deadline Repository"
  $taskName = "AAA Deadline Repository"
  if ($machineType -eq "JobManager") {
    $taskAction = New-ScheduledTaskAction -Execute "$aaaPathJobManager\deadlinecommand.exe" -Argument "-ChangeRepository Direct $deadlinePath $deadlinePath\$deadlineCertificate"
  } else {
    $taskAction = New-ScheduledTaskAction -Execute "$aaaPathJobManager\deadlinecommand.exe" -Argument "-ChangeRepository Direct S:\ S:\$deadlineCertificate"
  }
  $taskTrigger = New-ScheduledTaskTrigger -AtLogOn
  $taskPrincipal = New-ScheduledTaskPrincipal -GroupId "Users"
  $task = New-ScheduledTask -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal
  Register-ScheduledTask -TaskName $taskName -InputObject $task
  Write-Information "(AAA End): Deadline Repository"

  Write-Information "(AAA Start): Deadline Monitor"
  $shortcutPath = "$Env:AllUsersProfile\Desktop\Deadline Monitor.lnk"
  $scriptShell = New-Object -ComObject WScript.Shell
  $shortcut = $scriptShell.CreateShortcut($shortcutPath)
  $shortcut.WorkingDirectory = $aaaPathJobManager
  $shortcut.TargetPath = "$aaaPathJobManager\deadlinemonitor.exe"
  $shortcut.Save()
  Write-Information "(AAA End): Deadline Monitor"

  $aaaPath += ";$aaaPathJobManager"
}

if ($aaaPath -ne "") {
  Write-Information "(AAA Path): $($aaaPath.substring(1))"
  [Environment]::SetEnvironmentVariable("PATH", "$Env:PATH$aaaPath", "Machine")
}

Write-Information "(AAA End): Job Manager"
