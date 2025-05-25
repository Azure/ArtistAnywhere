param (
  [string] $resourceGroupName,
  [string] $jobManagerName,
  [string] $jobClusterName,
  [int] $jobClusterNodeLimit
  [int] $jobWaitThresholdSeconds
  [int] $workerIdleDeleteSeconds
)

az login --identity

if ($jobManagerName -eq "Deadline") {
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
    $jobClusterNodeCount = az vmss show --resource-group $resourceGroupName --name $jobClusterName --query "sku.capacity"
    if ($jobClusterNodeLimit -gt 0 -and $jobClusterNodeCount + $queuedTasks -gt $jobClusterNodeLimit) {
      $jobClusterNodeCount = $jobClusterNodeLimit
    } else {
      $jobClusterNodeCount += $queuedTasks
    }
    az vmss scale --resource-group $resourceGroupName --name $jobClusterName --new-capacity $jobClusterNodeCount
  } else { # Scale Down
    $workerNames = deadlinecommand -GetSlaveNames
    foreach ($workerName in $workerNames) {
      $worker = deadlinecommand -GetSlave $workerName | ConvertFrom-StringData
      if ($worker.SlaveState -eq "Idle") {
        $workerIdleStartTime = $worker.WorkerLastRenderFinishedTime == "" ? $worker.StateDateTime : $worker.WorkerLastRenderFinishedTime
        $workerIdleEndTime = Get-Date -AsUtc
        $workerIdleSeconds = (New-TimeSpan -Start $workerIdleStartTime -End $workerIdleEndTime).TotalSeconds
        if ($workerIdleSeconds -gt $workerIdleDeleteSeconds) {
          $instanceId = az vmss list-instances --resource-group $resourceGroupName --name $jobClusterName --query "[?osProfile.computerName=='$workerName'].instanceId" --output tsv
          az vmss delete-instances --resource-group $resourceGroupName --name $jobClusterName --instance-ids $instanceId
        }
      }
    }
  }
} else if ($jobManagerName -eq "Slurm") {

}
