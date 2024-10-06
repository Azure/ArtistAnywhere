$ErrorActionPreference = "Stop"

$binPaths = ""
$binDirectory = "C:\Users\Public\Downloads"
Set-Location -Path $binDirectory

$fileSystemsMountPath = "$binDirectory\fileSystems.bat"

if ($buildConfigEncoded -ne "") {
  Write-Host "Customize (Start): Image Build Parameters"
  $buildConfigBytes = [System.Convert]::FromBase64String($buildConfigEncoded)
  $buildConfig = [System.Text.Encoding]::UTF8.GetString($buildConfigBytes) | ConvertFrom-Json
  $machineType = $buildConfig.machineType
  $gpuProvider = $buildConfig.gpuProvider
  $binHostUrl = $buildConfig.binHostUrl
  $jobProcessors = $buildConfig.jobProcessors
  $tenantId = $buildConfig.authClient.tenantId
  $clientId = $buildConfig.authClient.clientId
  $clientSecret = $buildConfig.authClient.clientSecret
  $storageVersion = $buildConfig.authClient.storageVersion
  $adminUsername = $buildConfig.authCredential.adminUsername
  $adminPassword = $buildConfig.authCredential.adminPassword
  $serviceUsername = $buildConfig.authCredential.serviceUsername
  $servicePassword = $buildConfig.authCredential.servicePassword
  Write-Host "Build Config: $buildConfig"
  Write-Host "Customize (End): Image Build Parameters"
}

function DownloadFile ($fileName, $fileLink, $tenantId, $clientId, $clientSecret, $storageVersion) {
  Add-Type -AssemblyName System.Net.Http
  $httpClient = New-Object System.Net.Http.HttpClient
  if ($tenantId -ne $null) {
    $body = @{
      resource      = "https://storage.azure.com"
      grant_type    = "client_credentials"
      client_id     = $clientId
      client_secret = $clientSecret
    }
    $authToken = (Invoke-WebRequest -UseBasicParsing -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -Body $body -Method Post).Content
  	$accessToken = (ConvertFrom-Json -InputObject $authToken).access_token
    $httpClient.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $accessToken)
    $httpClient.DefaultRequestHeaders.Add("x-ms-version", $storageVersion)
  }
  $httpResponse = $httpClient.GetAsync($fileLink).Result
  if ($httpResponse.IsSuccessStatusCode) {
    $stream = $httpResponse.Content.ReadAsStreamAsync().Result
    $filePath = Join-Path -Path $pwd.Path -ChildPath $fileName
    $fileStream = [System.IO.File]::Create($filePath)
    $stream.CopyTo($fileStream)
    $fileStream.Close()
  } else {
    Write-Error "Failed to download $fileLink ($($httpResponse.StatusCode))"
  }
}

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

function SetFileSystem ($fileSystemConfig) {
  foreach ($fileSystem in $fileSystemConfig) {
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
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    $taskAction = New-ScheduledTaskAction -Execute $fileSystemsMountPath
    Register-ScheduledTask -TaskName $taskName -Trigger $taskTrigger -Action $taskAction -User System -Force
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
      Write-Host $_.Exception.Message
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

function JoinActiveDirectory ($domainName, $domainServerName, $orgUnitPath, $userName, $userPassword) {
  if ($userName -notlike "*@*") {
    $userName = "$userName@$domainName"
  }
  $securePassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
  $userCredential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

  $adComputer = Get-ADComputer -Identity $(hostname) -Server $domainServerName -Credential $userCredential
  if ($adComputer) {
    Remove-ADObject -Identity $adComputer -Server $domainServerName -Recursive -Confirm:$false
  }

  if ($orgUnitPath -ne "") {
    Add-Computer -DomainName $domainName -Server $domainServerName -Credential $userCredential -OUPath $orgUnitPath -Force -PassThru -Verbose -Restart
  } else {
    Add-Computer -DomainName $domainName -Server $domainServerName -Credential $userCredential -Force -PassThru -Verbose -Restart
  }
}

function SetActiveDirectory ($activeDirectory) {
  if ($activeDirectory.enable) {
    Retry 3 10 {
      JoinActiveDirectory $activeDirectory.domainName $activeDirectory.domainServerName $activeDirectory.orgUnitPath $activeDirectory.adminUsername $activeDirectory.adminPassword
    }
  }
}
