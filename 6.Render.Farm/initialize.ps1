$binDirectory = "C:\Users\Public\Downloads"
Set-Location -Path $binDirectory

. C:\AzureData\functions.ps1

if ("${terminateNotification.enable}" -eq $true) {
  $taskName = "AAA Terminate Event Handler"
  $taskInterval = New-TimeSpan -Minutes 1
  $taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Unrestricted -File C:\AzureData\terminate.ps1"
  $taskTrigger = New-ScheduledTaskTrigger -RepetitionInterval $taskInterval -At $(Get-Date) -Once
  Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -User System -Force
}

SetFileSystems (ConvertFrom-Json -InputObject '${jsonencode(fileSystems)}')

InitializeClient (ConvertFrom-Json -InputObject '${jsonencode(activeDirectory)}') $null $null
