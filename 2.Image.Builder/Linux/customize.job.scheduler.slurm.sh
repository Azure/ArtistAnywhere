#!/bin/bash -x

source /tmp/functions.sh

echo "Customize (Start): Job Scheduler"

if [ $machineType != Storage ]; then
  versionPath=$(echo $buildConfig | jq -r .versionPath.jobSchedulerSlurm)
  installRoot="/slurm"
  binPathJobScheduler="$installRoot/bin"

  binPaths="$binPaths:$binPathJobScheduler"
fi

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Job Scheduler"
