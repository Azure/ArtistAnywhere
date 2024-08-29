. C:\AzureData\functions.ps1

if ("${terminateNotification.enable}" -eq $true) {
  $taskName = "AAA Terminate Event Handler"
  $taskInterval = New-TimeSpan -Minutes 1
  $taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Unrestricted -File C:\AzureData\terminate.ps1"
  $taskTrigger = New-ScheduledTaskTrigger -RepetitionInterval $taskInterval -At $(Get-Date) -Once
  Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -User System -Force
}

SetFileSystem (ConvertFrom-Json -InputObject '${jsonencode(fileSystem)}')

Start-ScheduledTask -TaskName $jobManagerTaskName

SetActiveDirectory (ConvertFrom-Json -InputObject '${jsonencode(activeDirectory)}')
