$ErrorActionPreference = "Stop"

$binPaths = ""
$binDirectory = "C:\Users\Public\Downloads"
Set-Location -Path $binDirectory

$fileSystemsMountPath = "$binDirectory\fileSystems.bat"

if ($buildConfigEncoded -ne "") {
  Write-Host "Customize (Start): Image Build Parameters"
  $buildConfigBytes = [System.Convert]::FromBase64String($buildConfigEncoded)
  $buildConfig = [System.Text.Encoding]::UTF8.GetString($buildConfigBytes) | ConvertFrom-Json
  $blobStorage = $buildConfig.blobStorage
  $machineType = $buildConfig.machineType
  $gpuProvider = $buildConfig.gpuProvider
  $jobSchedulers = $buildConfig.jobSchedulers
  $jobProcessors = $buildConfig.jobProcessors
  $adminUsername = $buildConfig.authCredential.adminUsername
  $adminPassword = $buildConfig.authCredential.adminPassword
  $serviceUsername = $buildConfig.authCredential.serviceUsername
  $servicePassword = $buildConfig.authCredential.servicePassword
  Write-Host "Customize (End): Image Build Parameters"
}

function DownloadFile ($fileName, $fileLink) {
  try {
    Add-Type -AssemblyName System.Net.Http
    $authToken = Invoke-WebRequest -UseBasicParsing -Headers @{Metadata=$true} -Uri $blobStorage.authTokenUrl
    $accessToken = (ConvertFrom-Json -InputObject $authToken.Content).access_token
    $httpClient = New-Object System.Net.Http.HttpClient
    $httpClient.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $accessToken)
    $httpClient.DefaultRequestHeaders.Add("x-ms-version", $blobStorage.apiVersion)
    $httpResponse = $httpClient.GetAsync($fileLink).Result
    if ($httpResponse.IsSuccessStatusCode) {
      $stream = $httpResponse.Content.ReadAsStreamAsync().Result
      $filePath = Join-Path -Path $pwd.Path -ChildPath $fileName
      $fileStream = [System.IO.File]::Create($filePath)
      $stream.CopyTo($fileStream)
      $fileStream.Close()
    } else {
      throw [Microsoft.PowerShell.Commands.HttpResponseException]::new($httpResponse.ReasonPhrase, $httpResponse)
    }
  } catch {
    Write-Error "DownloadFile Error: $_.Exception.Message"
    Write-Error "FileName: $fileName"
    Write-Error "FileLink: $fileLink"
    throw
  }
}

function RunProcess ($filePath, $argumentList, $logFile) {
  try {
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
  } catch {
    Write-Error "RunProcess Error: $_.Exception.Message"
    Write-Error "FilePath: $filePath"
    Write-Error "ArgumentList: $argumentList"
    throw
  }
}

function FileExists ($filePath) {
  return Test-Path -PathType Leaf -Path $filePath
}

function SetFileSystem ($fileSystemConfig) {
  if ($fileSystemConfig -ne $null) {
    foreach ($fileSystem in $fileSystemConfig) {
      if ($fileSystem.enable) {
        SetFileSystemMount $fileSystem.mount
      }
    }
    RegisterFileSystemMounts
  }
}

function SetFileSystemMount ($fileSystemMount) {
  if (!(FileExists $fileSystemsMountPath)) {
    New-Item -ItemType File -Path $fileSystemsMountPath
  }
  $mountScript = Get-Content -Path $fileSystemsMountPath
  if ($mountScript -eq $null -or $mountScript -notlike "*$($fileSystemMount.path)*") {
    $mount = "mount $($fileSystemMount.options) $($fileSystemMount.target) $($fileSystemMount.path)"
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

function JoinActiveDirectory {
  param (
    [Parameter(ParameterSetName="Retry")]
    [object] $activeDirectory,
    [Parameter(ParameterSetName="Join")]
    [string] $domainName,
    [string] $serverName,
    [string] $userName,
    [string] $userPassword
  )
  process {
    if ($PSCmdlet.ParameterSetName -eq "Retry") {
      if ($activeDirectory.enable) {
        Retry 3 10 {
          JoinActiveDirectory -domainName $activeDirectory.domainName -serverName $activeDirectory.serverName -userName $activeDirectory.machine.adminLogin.userName -userPassword $activeDirectory.machine.adminLogin.userPassword
        }
      }
    } else {
      if ($userName -notlike "*@*") {
        $userName = "$userName@$domainName"
      }
      $securePassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
      $userCredential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

      try {
        $adComputer = Get-ADComputer -Identity $(hostname) -Server $serverName -Credential $userCredential
      }
      catch {}
      finally {
        if ($adComputer) {
          Remove-ADObject -Identity $adComputer -Server $serverName -Recursive -Confirm:$false
        }
      }

      Add-Computer -DomainName $domainName -Server $serverName -Credential $userCredential -Force -PassThru -Verbose
      if ($?) {
        Restart-Computer
      }
    }
  }
}
