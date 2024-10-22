#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Job Scheduler (LSF)"

if [ $machineType != Storage ]; then
  version=$(echo $buildConfig | jq -r .version.jobSchedulerLSF)
  installRoot="/lsf"
  #binPathJobScheduler="$installRoot/10.1/linux2.6-glibc2.3-x86_64/bin"

  echo "Customize (Start): LSF Download"
  fileName="lsfsce$version-x86_64.tar.gz"
  fileLink="$binHostUrl/LSF/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  tar -xzf $fileName
  tar -xf lsf*/lsf/lsf10.1_lsf*
  echo "Customize (End): LSF Download"

  dnf -y install libnsl ed
  cd lsf10*
  sed -i "/# LSF_ADMINS=/c\LSF_ADMINS=root" install.config
  sed -i "/# LSF_TOP=/c\LSF_TOP=$installRoot" install.config
  sed -i "/# LSF_CLUSTER_NAME=/c\LSF_CLUSTER_NAME=Default" install.config
  sed -i "/# LSF_MASTER_LIST=/c\LSF_MASTER_LIST=$(hostname)" install.config
  sed -i "/# LSF_TARDIR=/c\LSF_TARDIR=$binDirectory/lsfs*/lsf" install.config
  sed -i "/# LSF_SILENT_INSTALL_TARLIST=/c\LSF_SILENT_INSTALL_TARLIST=ALL" install.config
  sed -i "/# SILENT_INSTALL=/c\SILENT_INSTALL=Y" install.config
  sed -i "/# ACCEPT_LICENSE=/c\ACCEPT_LICENSE=Y" install.config
  ./lsfinstall -f install.config

  #binPaths="$binPaths:$binPathJobScheduler"
fi

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Job Scheduler (LSF)"
