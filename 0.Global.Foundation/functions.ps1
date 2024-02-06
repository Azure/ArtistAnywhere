$fileSystemsPath = "C:\Users\Public\Downloads\fileSystems.bat"

function RunProcess ($filePath, $argumentList, $logFile) {
  if ($logFile) {
    if ($argumentList) {
      Start-Process -FilePath $filePath -ArgumentList $argumentList -Wait -RedirectStandardOutput $logFile-out -RedirectStandardError $logFile-err
    } else {
      Start-Process -FilePath $filePath -Wait -RedirectStandardOutput $logFile-out -RedirectStandardError $logFile-err
    }
    Get-Content -Path $logFile-err | Write-Host
  } else {
    if ($argumentList) {
      Start-Process -FilePath $filePath -ArgumentList $argumentList -Wait
    } else {
      Start-Process -FilePath $filePath -Wait
    }
  }
}

function FileExists ($filePath) {
  return Test-Path -PathType Leaf -Path $filePath
}

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
    RunProcess $fileSystemsPath $null "$binDirectory\file-system-mount"
    $taskName = "AAA File System Mount"
    $taskAction = New-ScheduledTaskAction -Execute $fileSystemsPath
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -User System -Force
  }
}

function Retry ($delaySeconds, $maxCount, $scriptBlock) {
  $count = 0
  $exception = $null
  do {
    $count++
    try {
      $scriptBlock.Invoke()
      $exception = $null
      exit
    } catch {
      $exception = $_.Exception
      Start-Sleep -Seconds $delaySeconds
    }
  } while ($count -lt $maxCount)
  if ($exception) {
    throw $exception
  }
}

function JoinActiveDirectory ($domainName, $domainServerName, $orgUnitPath, $adminUsername, $adminPassword) {
  if ($adminUsername -notlike "*@*") {
    $adminUsername = "$adminUsername@$domainName"
  }
  $securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
  $adminCredential = New-Object System.Management.Automation.PSCredential($adminUsername, $securePassword)

  try {
    $localComputerName = $(hostname)
    $adComputer = Get-ADComputer -Identity $localComputerName -Server $domainServerName -Credential $adminCredential
    Remove-ADObject -Identity $adComputer -Server $domainServerName -Recursive -Confirm:$false
    #Start-Sleep -Seconds 30
    $adComputer = null
  } catch {
    if ($adComputer) {
      Write-Error "Error occurred while trying to remove the $localComputerName computer AD object."
    }
  }

  if ($orgUnitPath -ne "") {
    Add-Computer -DomainName $domainName -Server $domainServerName -Credential $adminCredential -OUPath $orgUnitPath -Force -PassThru -Verbose
  } else {
    Add-Computer -DomainName $domainName -Server $domainServerName -Credential $adminCredential -Force -PassThru -Verbose
  }
}

function InitializeClient ($binDirectory, $activeDirectoryJson) {
  RunProcess deadlinecommand.exe "-ChangeRepository Direct S:\ S:\Deadline10Client.pfx" "$binDirectory\deadline-repository"
  $activeDirectory = ConvertFrom-Json -InputObject $activeDirectoryJson
  if ($activeDirectory.enable) {
    Retry 5 10 {
      JoinActiveDirectory $activeDirectory.domainName $activeDirectory.domainServerName $activeDirectory.orgUnitPath $activeDirectory.adminUsername $activeDirectory.adminPassword
    }
  }
}
