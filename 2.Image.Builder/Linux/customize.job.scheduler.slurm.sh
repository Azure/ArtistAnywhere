#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Job Scheduler (Slurm)"

version=$(echo $buildConfig | jq -r .version.job_scheduler_slurm)

echo "Customize (Start): Slurm Download"
fileName="slurm-$version.tar.bz2"
fileLink="$binHostUrl/Slurm/$version/$fileName"
download_file $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
bzip2 -d $fileName
echo "Customize (End): Slurm Download"

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Job Scheduler (Slurm)"
