#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Job Scheduler (Deadline)"

if [ $machineType != Storage ]; then
  version=$(echo $buildConfig | jq -r .version.jobSchedulerDeadline)
  installRoot="/deadline"
  databaseHost=$(hostname)
  databasePath="/deadlineData"
  certificateFile="Deadline10Client.pfx"
  binPathJobScheduler="$installRoot\bin"

  echo "Customize (Start): Deadline Download"
  fileName="Deadline-$version-linux-installers.tar"
  filePath=$(echo ${fileName%.tar})
  fileLink="$binHostUrl/Deadline/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  mkdir -p $filePath
  tar -xzf $fileName -C $filePath
  echo "Customize (End): Deadline Download"

  if [ $machineType == JobScheduler ]; then
    echo "Customize (Start): Deadline Server"
    fileType="deadline-repository"
    fileName="DeadlineRepository-$version-linux-x64-installer.run"
    RunProcess "$filePath/$fileName --mode unattended --dbLicenseAcceptance accept --prefix $installRoot --dbhost $databaseHost --mongodir $databasePath --installmongodb true" "$binDirectory/$fileType"
    mv /tmp/installbuilder_installer.log $binDirectory/deadline-repository.log
    cp $databasePath/certs/$certificateFile  $installRoot/$certificateFile
    echo "$installRoot *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    exportfs -r
    echo "Customize (End): Deadline Server"
  fi

  echo "Customize (Start): Deadline Client"
  fileType="deadline-client"
  fileName="DeadlineClient-$version-linux-x64-installer.run"
  fileArgs="--mode unattended --prefix $installRoot"
  if [ $machineType == JobScheduler ]; then
    fileArgs="$fileArgs --slavestartup false --launcherdaemon false"
  else
    [ $machineType == Farm ] && workerStartup="true" || workerStartup="false"
    fileArgs="$fileArgs --slavestartup $workerStartup --launcherdaemon true"
  fi
  RunProcess "$filePath/$fileName $fileArgs" $binDirectory/$fileType
  mv /tmp/installbuilder_installer.log $binDirectory/deadline-client.log
  echo "Customize (End): Deadline Client"

  echo "Customize (Start): Deadline Client Auth"
  [ $machineType == JobScheduler ] && repositoryPath=$installRoot || repositoryPath="/mnt/deadline"
  echo "$binPathJobScheduler/deadlinecommand -StoreDatabaseCredentials $serviceUsername $servicePassword" >> $aaaProfile
  echo "$binPathJobScheduler/deadlinecommand -ChangeRepository Direct $repositoryPath" >> $aaaProfile
  echo "Customize (End): Deadline Client Auth"

  binPaths="$binPaths:$binPathJobScheduler"
fi

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Job Scheduler (Deadline)"
