$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

$aaaPath = ""
$aaaRoot = "C:\Program Files\AAA"
New-Item -ItemType Directory -Path $aaaRoot -Force
Set-Location -Path $aaaRoot

$fileSystemsMount = "$aaaRoot\fileSystems.bat"

if ($imageBuildConfigEncoded -ne "") {
  Write-Information "(AAA Start): Image Build Config"
  $imageBuildConfigBytes = [System.Convert]::FromBase64String($imageBuildConfigEncoded)
  $imageBuildConfig = [System.Text.Encoding]::UTF8.GetString($imageBuildConfigBytes) | ConvertFrom-Json
  $blobStorage = $imageBuildConfig.blobStorage
  $machineType = $imageBuildConfig.machineType
  $gpuProvider = $imageBuildConfig.gpuProvider
  $jobManagers = $imageBuildConfig.jobManagers
  $jobProcessors = $imageBuildConfig.jobProcessors
  $adminUsername = $imageBuildConfig.authCredential.adminUsername
  $adminPassword = $imageBuildConfig.authCredential.adminPassword
  $serviceUsername = $imageBuildConfig.authCredential.serviceUsername
  $servicePassword = $imageBuildConfig.authCredential.servicePassword
  Write-Information "(AAA End): Image Build Config"
}

function DownloadFile ($fileName, $fileLink, $authRequired) {
  Add-Type -AssemblyName System.Net.Http
  $httpClient = New-Object System.Net.Http.HttpClient
  if ($authRequired) {
    $authToken = Invoke-WebRequest -UseBasicParsing -Headers @{Metadata=$true} -Uri $blobStorage.authTokenUrl
    $accessToken = (ConvertFrom-Json -InputObject $authToken).access_token
    $httpClient.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $accessToken)
    $httpClient.DefaultRequestHeaders.Add("x-ms-version", $blobStorage.apiVersion)
  }
  $httpResponse = $httpClient.GetAsync($fileLink).Result
  if ($httpResponse.IsSuccessStatusCode) {
    $stream = $httpResponse.Content.ReadAsStreamAsync().Result
    $filePath = Join-Path -Path $pwd.Path -ChildPath $fileName
    $fileStream = [System.IO.File]::Create($filePath)
    $stream.CopyTo($fileStream)
    $fileStream.Close()
  } else {
    throw [System.Web.HttpException]::new($httpResponse.StatusCode, $httpResponse.ReasonPhrase)
  }
}

function RunProcess ($filePath, $argumentList, $logFile) {
  try {
    if ($logFile) {
      $logFile = "$aaaRoot\$logFile"
      if ($argumentList) {
        Start-Process -FilePath $filePath -ArgumentList $argumentList -Wait -RedirectStandardOutput $logFile-out -RedirectStandardError $logFile-err
      } else {
        Start-Process -FilePath $filePath -Wait -RedirectStandardOutput $logFile-out -RedirectStandardError $logFile-err
      }
      Get-Content -Path $logFile-err | Write-Information
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

function SetFileSystem ($fileSystemConfig) {
  foreach ($fileSystem in $fileSystemConfig) {
    if ($fileSystem.enable) {
      SetFileSystemMount $fileSystem.mount
    }
  }
  RegisterFileSystemMounts
}

function SetFileSystemMount ($fileSystemMount) {
  if (!(Test-Path -PathType Leaf -Path $fileSystemMount)) {
    New-Item -ItemType File -Path $fileSystemsMount
  }
  $mountScript = Get-Content -Path $fileSystemsMount
  if ($mountScript -eq $null -or $mountScript -notlike "*$($fileSystemMount.path)*") {
    $mount = "mount $($fileSystemMount.options) $($fileSystemMount.target) $($fileSystemMount.path)"
    Add-Content -Path $fileSystemsMount -Value $mount
  }
}

function RegisterFileSystemMounts {
  RunProcess $fileSystemsMount $null file-system-mount
  $taskName = "AAA File System Mount"
  $taskTrigger = New-ScheduledTaskTrigger -AtStartup
  $taskAction = New-ScheduledTaskAction -Execute $fileSystemsMount
  Register-ScheduledTask -TaskName $taskName -Trigger $taskTrigger -Action $taskAction -User System -Force
}

function Retry {
  param (
    [int] $retryCountMax,
    [int] $delaySeconds,
    [ScriptBlock] $scriptBlock
  )
  $ex = $null
  $retryCount = 0
  do {
    $retryCount++
    try {
      return $scriptBlock.Invoke()
    } catch {
      Write-Information "(AAA) Error $retryCount of $retryCountMax Retry: $($_.Exception.Message)"
      if ($ex -eq $null) {
        $ex = $_.Exception
      }
      Start-Sleep -Seconds $delaySeconds
    }
  } while ($retryCount -lt $retryCountMax)
  if ($ex -ne $null) {
    throw $ex
  }
}

function JoinActiveDirectory {
  param (
    [Parameter(ParameterSetName="Retry")]
    [object] $activeDirectory,
    [Parameter(ParameterSetName="Join")]
    [string] $serverName,
    [string] $domainName,
    [string] $userName,
    [string] $userPassword
  )
  if ($PSCmdlet.ParameterSetName -eq "Retry") {
    if ($activeDirectory.enable) {
      Retry 3 10 {
        JoinActiveDirectory -serverName $activeDirectory.serverName -domainName $activeDirectory.domainName -userName $activeDirectory.machine.adminLogin.userName -userPassword $activeDirectory.machine.adminLogin.userPassword
      }
    }
  } else {
    if ($userName -notlike "*@*") {
      $userName = "$userName@$domainName"
    }
    $securePassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
    $userCredential = New-Object System.Management.Automation.PSCredential($userName, $securePassword)

    $oldComputer = $null
    try {
      $machineName = [System.Environment]::MachineName
      $oldComputer = Get-ADComputer -Server $serverName -Identity $machineName -Credential $userCredential
      Write-Information "(AAA) Get-ADComputer: $oldComputer"
    }
    catch {
      Write-Information "(AAA) Error: $($_.Exception.Message)"
    }
    finally {
      if ($oldComputer) {
        Write-Information "(AAA) Remove-ADObject: $serverName, $oldComputer"
        Remove-ADObject -Server $serverName -Identity $oldComputer -Recursive -Confirm:$false
      }
    }

    Write-Information "(AAA) Add-Computer: $serverName, $domainName"
    try {
      Add-Computer -Server $serverName -DomainName $domainName -Credential $userCredential -Force -PassThru -Verbose
      Write-Information "(AAA) Restart-Computer"
      Restart-Computer
    } catch {
      $ex = $_.Exception
      while ($ex.InnerException) {
        $ex = $ex.InnerException
      }
      Write-Information "(AAA) Error: $($ex.Message)"
    }
  }
}
