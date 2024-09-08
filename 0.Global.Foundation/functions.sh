#!/bin/bash -x

binPaths=""
binDirectory="/usr/local/bin"
cd $binDirectory

aaaProfile="/etc/profile.d/aaa.sh"
touch $aaaProfile

echo "Customize (Start): Image Build Parameters"
dnf -y install jq
buildConfig=$(echo $buildConfigEncoded | base64 -d)
machineType=$(echo $buildConfig | jq -r .machineType)
gpuProvider=$(echo $buildConfig | jq -r .gpuProvider)
binStorageHost=$(echo $buildConfig | jq -r .binStorage.host)
binStorageAuth=$(echo $buildConfig | jq -r .binStorage.auth)
jobProcessors=$(echo $buildConfig | jq -c .jobProcessors)
adminUsername=$(echo $buildConfig | jq -r .authCredential.adminUsername)
adminPassword=$(echo $buildConfig | jq -r .authCredential.adminPassword)
serviceUsername=$(echo $buildConfig | jq -r .authCredential.serviceUsername)
servicePassword=$(echo $buildConfig | jq -r .authCredential.servicePassword)
echo "Machine Type: $machineType"
echo "GPU Provider: $gpuProvider"
echo "Job Processors: $jobProcessors"
echo "Customize (End): Image Build Parameters"

function RunProcess {
  exitStatus=-1
  retryCount=0
  command="$1"
  logFile=$2
  while [[ $exitStatus && $retryCount -lt 3 ]]; do
    $command 1> $logFile.out 2> $logFile.err
    exitStatus=$?
    ((retryCount++))
    if [ $exitStatus ]; then
      cat $logFile.out
      cat $logFile.err
      sleep 5s
    fi
  done
}

function GetEncodedValue {
  echo $1 | base64 -d | jq -r $2
}

function SetFileSystem {
  fileSystemConfig="$1"
  for fileSystem in $(echo $fileSystemConfig | jq -r '.[] | @base64'); do
    if [ $(GetEncodedValue $fileSystem .enable) == true ]; then
      SetFileSystemMount "$(GetEncodedValue $fileSystem .mount)"
    fi
  done
  systemctl daemon-reload
  mount -a
}

function SetFileSystemMount {
  fileSystemMount="$1"
  mountType=$(echo $fileSystemMount | jq -r .type)
  mountPath=$(echo $fileSystemMount | jq -r .path)
  mountSource=$(echo $fileSystemMount | jq -r .source)
  mountOptions=$(echo $fileSystemMount | jq -r .options)
  if [ $(grep -c $mountPath /etc/fstab) ]; then
    mkdir -p $mountPath
    echo "$mountSource $mountPath $mountType $mountOptions 0 0" >> /etc/fstab
  fi
}
