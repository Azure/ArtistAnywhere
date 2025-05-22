param (
  [string] $resourceGroupName,
  [string] $computeJobManager,
  [string] $computeClusterName,
  [int] $computeClusterNodeLimit
  [int] $jobWaitThresholdSeconds
  [int] $workerIdleDeleteSeconds
)

az login --identity

if ($computeJobManager -eq "Deadline") {
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
    $computeClusterNodeCount = az vmss show --resource-group $resourceGroupName --name $computeClusterName --query "sku.capacity"
    if ($computeClusterNodeLimit -gt 0 -and $computeClusterNodeCount + $queuedTasks -gt $computeClusterNodeLimit) {
      $computeClusterNodeCount = $computeClusterNodeLimit
    } else {
      $computeClusterNodeCount += $queuedTasks
    }
    az vmss scale --resource-group $resourceGroupName --name $computeClusterName --new-capacity $computeClusterNodeCount
  } else { # Scale Down
    $workerNames = deadlinecommand -GetSlaveNames
    foreach ($workerName in $workerNames) {
      $worker = deadlinecommand -GetSlave $workerName | ConvertFrom-StringData
      if ($worker.SlaveState -eq "Idle") {
        $workerIdleStartTime = $worker.WorkerLastRenderFinishedTime == "" ? $worker.StateDateTime : $worker.WorkerLastRenderFinishedTime
        $workerIdleEndTime = Get-Date -AsUtc
        $workerIdleSeconds = (New-TimeSpan -Start $workerIdleStartTime -End $workerIdleEndTime).TotalSeconds
        if ($workerIdleSeconds -gt $workerIdleDeleteSeconds) {
          $instanceId = az vmss list-instances --resource-group $resourceGroupName --name $computeClusterName --query "[?osProfile.computerName=='$workerName'].instanceId" --output tsv
          az vmss delete-instances --resource-group $resourceGroupName --name $computeClusterName --instance-ids $instanceId
        }
      }
    }
  }
} else if ($computeJobManager -eq "Slurm") {

}
