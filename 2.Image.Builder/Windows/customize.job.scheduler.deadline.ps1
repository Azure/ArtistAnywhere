param (
  [string] $buildConfigEncoded
)

. C:\AzureData\functions.ps1

Write-Host "Customize (Start): Job Scheduler (Deadline)"

if ($machineType -ne "Storage") {
  $version = $buildConfig.version.job_scheduler_deadline
  $databaseHost = $(hostname)
  $databasePath = "C:\DeadlineData"
  $deadlinePath = "C:\DeadlineServer"
  $deadlineCertificate = "Deadline10Client.pfx"
  $binPathJobScheduler = "C:\Deadline\bin"

  Write-Host "Customize (Start): Deadline Download"
  $fileName = "Deadline-$version-windows-installers.zip"
  $fileLink = "$binHostUrl/Deadline/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  Expand-Archive -Path $fileName
  Write-Host "Customize (End): Deadline Download"

  Set-Location -Path Deadline*
  if ($machineType -eq "JobScheduler") {
    Write-Host "Customize (Start): Deadline Server"
    $fileType = "deadline-repository"
    $fileName = "DeadlineRepository-$version-windows-installer.exe"
    RunProcess .\$fileName "--mode unattended --dbLicenseAcceptance accept --prefix $deadlinePath --dbhost $databaseHost --mongodir $databasePath --installmongodb true" "$binDirectory\$fileType"
    Move-Item -Path $env:TMP\installbuilder_installer.log -Destination $binDirectory\$fileType.log
    Copy-Item -Path $databasePath\certs\$deadlineCertificate -Destination $deadlinePath\$deadlineCertificate
    New-NfsShare -Name "Deadline" -Path $deadlinePath -Permission ReadWrite
    Write-Host "Customize (End): Deadline Server"
  }

  Write-Host "Customize (Start): Deadline Client"
  $fileType = "deadline-client"
  $fileName = "DeadlineClient-$version-windows-installer.exe"
  $fileArgs = "--mode unattended --prefix $deadlinePath"
  if ($machineType -eq "JobScheduler") {
    $fileArgs = "$fileArgs --slavestartup false --launcherservice false"
  } else {
    if ($machineType -eq "Farm") {
      $workerStartup = "true"
    } else {
      $workerStartup = "false"
    }
    $fileArgs = "$fileArgs --slavestartup $workerStartup --launcherservice true"
  }
  RunProcess .\$fileName $fileArgs "$binDirectory\$fileType"
  Move-Item -Path $env:TMP\installbuilder_installer.log -Destination $binDirectory\$fileType.log
  Set-Location -Path $binDirectory
  Write-Host "Customize (End): Deadline Client"

  Write-Host "Customize (Start): Deadline Repository"
  $filePath = "$binDirectory\deadline-repository.bat"
  New-Item -Path $filePath -ItemType File
  if ($machineType -eq "JobScheduler") {
    Add-Content -Path $filePath -Value "$binPathJobScheduler\deadlinecommand.exe -ChangeRepository Direct $deadlinePath $deadlinePath\$deadlineCertificate"
  } else {
    Add-Content -Path $filePath -Value "$binPathJobScheduler\deadlinecommand.exe -ChangeRepository Direct S:\ S:\$deadlineCertificate"
  }
  $registryKeyName = "Run"
  $registryKeyRoot = "HKLM:\Software\Microsoft\Windows\CurrentVersion"
  $registryKeyPath = "$registryKeyRoot\$registryKeyName"
  if (-not (Test-Path -Path $registryKeyPath)) {
    New-Item -Path $registryKeyRoot -Name $registryKeyName
  }
  Set-ItemProperty -Path $registryKeyPath -Name "DeadlineRepository" -Value $filePath
  Write-Host "Customize (End): Deadline Repository"

  Write-Host "Customize (Start): Deadline Monitor"
  $shortcutPath = "$env:AllUsersProfile\Desktop\Deadline Monitor.lnk"
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
  setx PATH "$env:PATH$binPaths" /m
}

Write-Host "Customize (End): Job Scheduler (Deadline)"
