$fileSystemsMountPath = "C:\Users\Public\Downloads\fileSystems.bat"
$jobSchedulerTaskName = "AAA Job Scheduler Initialize"

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

function SetFileSystems ($fileSystems) {
  foreach ($fileSystem in $fileSystems) {
    if ($fileSystem.enable) {
      SetFileSystemMount $fileSystem.mount
    }
  }
  RegisterFileSystemMounts
}

function SetFileSystemMount ($fileSystemMount) {
  if (!(FileExists $fileSystemsMountPath)) {
    New-Item -ItemType File -Path $fileSystemsMountPath
  }
  $mountScript = Get-Content -Path $fileSystemsMountPath
  if ($mountScript -eq $null -or $mountScript -notlike "*$($fileSystemMount.path)*") {
    $mount = "mount $($fileSystemMount.options) $($fileSystemMount.source) $($fileSystemMount.path)"
    Add-Content -Path $fileSystemsMountPath -Value $mount
  }
}

function RegisterFileSystemMounts {
  if (FileExists $fileSystemsMountPath) {
    RunProcess $fileSystemsMountPath $null file-system-mount
    $taskName = "AAA File System Mount"
    $taskAction = New-ScheduledTaskAction -Execute $fileSystemsMountPath
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -User System -Force
  }
}

function Retry ($delaySeconds, $maxCount, $scriptBlock) {
  $exOriginal = $null
  $retryCount = 0
  do {
    $retryCount++
    try {
      $scriptBlock.Invoke()
      $exOriginal = $null
      exit
    } catch {
      if ($exOriginal -eq $null) {
        $exOriginal = $_.Exception.MembershipwiseClone
      }
      Start-Sleep -Seconds $delaySeconds
    }
  } while ($retryCount -lt $maxCount)
  if ($exOriginal -ne $null) {
    throw $exOriginal
  }
}

function JoinActiveDirectory ($domainName, $domainServerName, $orgUnitPath, $adminUsername, $adminPassword) {
  if ($adminUsername -notlike "*@*") {
    $adminUsername = "$adminUsername@$domainName"
  }
  $securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
  $adminCredential = New-Object System.Management.Automation.PSCredential($adminUsername, $securePassword)

  $adComputer = Get-ADComputer -Identity $(hostname) -Server $domainServerName -Credential $adminCredential
  if ($adComputer) {
    Remove-ADObject -Identity $adComputer -Server $domainServerName -Recursive -Confirm:$false
  }

  if ($orgUnitPath -ne "") {
    Add-Computer -DomainName $domainName -Server $domainServerName -Credential $adminCredential -OUPath $orgUnitPath -Force -PassThru -Verbose -Restart
  } else {
    Add-Computer -DomainName $domainName -Server $domainServerName -Credential $adminCredential -Force -PassThru -Verbose -Restart
  }
}

function SetActiveDirectory ($activeDirectory) {
  if ($activeDirectory.enable) {
    Retry 3 10 {
      JoinActiveDirectory $activeDirectory.domainName $activeDirectory.domainServerName $activeDirectory.orgUnitPath $activeDirectory.adminUsername $activeDirectory.adminPassword
    }
  }
}
