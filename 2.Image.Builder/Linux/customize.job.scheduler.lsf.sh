#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Job Scheduler (LSF)"

if [ $machineType != Storage ]; then
  version=$(echo $buildConfig | jq -r .version.jobSchedulerLSF)
  # installRoot="/lsf"

  echo "Customize (Start): LSF Download"
  fileName="lsfsce$version-x86_64.tar.gz"
  fileLink="$binHostUrl/LSF/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  mkdir -p $filePath
  tar -xzf $fileName
  echo "Customize (End): LSF Download"
fi

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Job Scheduler (LSF)"
