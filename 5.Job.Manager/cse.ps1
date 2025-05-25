. C:\AzureData\functions.ps1

sc start Deadline10DatabaseService

$scriptFile = "$aaaRoot\aaaAutoScaler.ps1"
Copy-Item -Path "C:\AzureData\CustomData.bin" -Destination $scriptFile

$taskName     = "AAA Auto Scaler"
$taskStart    = Get-Date
$taskInterval = New-TimeSpan -Seconds ${autoScale.detectionIntervalSeconds}
$taskAction   = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Unrestricted -File $scriptFile -resourceGroupName ${autoScale.resourceGroupName} -jobManagerName ${autoScale.jobManagerName} -jobClusterName ${autoScale.jobClusterName} -jobClusterNodeLimit ${autoScale.jobClusterNodeLimit} -jobWaitThresholdSeconds ${autoScale.jobWaitThresholdSeconds} -workerIdleDeleteSeconds ${autoScale.workerIdleDeleteSeconds}"
$taskTrigger  = New-ScheduledTaskTrigger -RepetitionInterval $taskInterval -At $taskStart -Once
if ("${autoScale.enable}" -ne $false) {
  $taskSettings = New-ScheduledTaskSettingsSet
} else {
  $taskSettings = New-ScheduledTaskSettingsSet -Disable
}
Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -User System -Force

JoinActiveDirectory -activeDirectory (ConvertFrom-Json -InputObject '${jsonencode(activeDirectory)}')
