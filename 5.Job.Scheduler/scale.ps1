param (
  [string] $resourceGroupName,
  [string] $jobSchedulerName,
  [string] $computeFarmName,
  [int] $computeFarmNodeCountMax
  [int] $jobWaitThresholdSeconds
  [int] $workerIdleDeleteSeconds
)

az login --identity

if ($jobSchedulerName -eq "Deadline") {
  $queuedTasks = 0
  $activeJobIds = deadlinecommand -GetJobIdsFilter Status=Active
  foreach ($jobId in $activeJobIds) {
    $jobDetails = deadlinecommand -GetJobDetails $jobId
    $jobWaitEndTime = Get-Date -AsUtc
    $jobWaitSeconds = (New-TimeSpan -Start $jobDetails.SubmitDate -End $jobWaitEndTime).TotalSeconds
    if ($jobWaitSeconds -gt $jobWaitThresholdSeconds) {
      $taskIds = deadlinecommand -GetJobTaskIds $jobId
      foreach ($taskId in $taskIds) {
        $task = deadlinecommand -GetJobTask $jobId $taskId | ConvertFrom-StringData
        if ($task.TaskStatus -eq "Queued") {
          $queuedTasks++
        }
      }
    }
  }
  if ($queuedTasks -gt 0) { # Scale Up
    $computeFarmNodeCount = az vmss show --resource-group $resourceGroupName --name $computeFarmName --query "sku.capacity"
    if ($computeFarmNodeCountMax -gt 0 -and $computeFarmNodeCount + $queuedTasks -gt $computeFarmNodeCountMax) {
      $computeFarmNodeCount = $computeFarmNodeCountMax
    } else {
      $computeFarmNodeCount += $queuedTasks
    }
    az vmss scale --resource-group $resourceGroupName --name $computeFarmName --new-capacity $computeFarmNodeCount
  } else { # Scale Down
    $workerNames = deadlinecommand -GetSlaveNames
    foreach ($workerName in $workerNames) {
      $worker = deadlinecommand -GetSlave $workerName | ConvertFrom-StringData
      if ($worker.SlaveState -eq "Idle") {
        $workerIdleStartTime = $worker.WorkerLastRenderFinishedTime == "" ? $worker.StateDateTime : $worker.WorkerLastRenderFinishedTime
        $workerIdleEndTime = Get-Date -AsUtc
        $workerIdleSeconds = (New-TimeSpan -Start $workerIdleStartTime -End $workerIdleEndTime).TotalSeconds
        if ($workerIdleSeconds -gt $workerIdleDeleteSeconds) {
          $instanceId = az vmss list-instances --resource-group $resourceGroupName --name $computeFarmName --query "[?osProfile.computerName=='$workerName'].instanceId" --output tsv
          az vmss delete-instances --resource-group $resourceGroupName --name $computeFarmName --instance-ids $instanceId
        }
      }
    }
  }
} else if ($jobSchedulerName -eq "LSF") {

}
