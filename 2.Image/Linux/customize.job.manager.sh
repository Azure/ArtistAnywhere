#!/bin/bash -ex

source /tmp/functions.sh

echo "(AAA Start): Job Manager"

if [[ $jobManagers == *Deadline* ]]; then
  appVersion=$(echo $imageBuildConfig | jq -r .appVersion.jobManagerDeadline)
  deadlinePath="/deadline"
  databaseName="deadline10db"
  databaseHost=$(hostname)
  databasePort=27017
  aaaPathJobManager="$deadlinePath/bin"

  echo "(AAA Start): Deadline Download"
  fileName="Deadline-$appVersion-linux-installers.tar"
  filePath=$(echo ${fileName%.tar})
  fileLink="$blobStorageEndpointUrl/Deadline/$appVersion/$fileName"
  download_file $fileName $fileLink true
  mkdir -p $filePath
  tar -xzf $fileName -C $filePath
  echo "(AAA End): Deadline Download"

  if [ $machineType == JobManager ]; then
    echo "(AAA Start): Mongo DB Service"
    if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
      echo never > /sys/kernel/mm/transparent_hugepage/enabled
    fi
    repoName="mongodb-org-6.0"
    repoPath="/etc/yum.repos.d/$repoName.repo"
    echo "[$repoName]" > $repoPath
    echo "name=MongoDB" >> $repoPath
    echo "baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/6.0/x86_64/" >> $repoPath
    echo "gpgcheck=1" >> $repoPath
    echo "enabled=1" >> $repoPath
    echo "gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc" >> $repoPath
    dnf -y install mongodb-org
    configFile="/etc/mongod.conf"
    sed -i "s/bindIp: 127.0.0.1/bindIp: 0.0.0.0/" $configFile
    sed -i "/bindIp: 0.0.0.0/a\  tls:" $configFile
    sed -i "/tls:/a\    mode: disabled" $configFile
    systemctl --now enable mongod
    echo "(AAA End): Mongo DB Service"

    echo "(AAA Start): Mongo DB Users"
    fileType="mongo-create-admin-user"
    fileName="$fileType.js"
    echo "use admin" > $fileName
    echo "db.createUser({" >> $fileName
    echo "  user: \"$adminUsername\"," >> $fileName
    echo "  pwd: \"$adminPassword\"," >> $fileName
    echo "  roles: [" >> $fileName
    echo "    { role: \"userAdminAnyDatabase\", db: \"admin\" }," >> $fileName
    echo "    { role: \"readWriteAnyDatabase\", db: \"admin\" }" >> $fileName
    echo "  ]" >> $fileName
    echo "})" >> $fileName
    run_process "mongosh $fileName" $aaaRoot/$fileType

    fileType="mongo-create-database-user"
    fileName="$fileType.js"
    echo "db = db.getSiblingDB(\"$databaseName\");" > $fileName
    echo "db.createUser({" >> $fileName
    echo "  user: \"$serviceUsername\"," >> $fileName
    echo "  pwd: \"$servicePassword\"," >> $fileName
    echo "  roles: [" >> $fileName
    echo "    { role: \"dbOwner\", db: \"$databaseName\" }" >> $fileName
    echo "  ]" >> $fileName
    echo "})" >> $fileName
    run_process "mongosh $fileName" $aaaRoot/$fileType
    echo "(AAA End): Mongo DB Users"

    echo "(AAA Start): Deadline Server"
    fileType="deadline-repository"
    fileName="DeadlineRepository-$appVersion-linux-x64-installer.run"
    export DB_PASSWORD=$servicePassword
    run_process "$filePath/$fileName --mode unattended --dbLicenseAcceptance accept --prefix $deadlinePath --dbhost $databaseHost --dbport $databasePort --dbname $databaseName --dbuser $serviceUsername --dbpassword env:DB_PASSWORD --dbauth true --installmongodb false" $aaaRoot/$fileType
    mv /tmp/installbuilder_installer.log $aaaRoot/deadline-repository.log
    echo "$deadlinePath *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    exportfs -a
    echo "(AAA End): Deadline Server"
  fi

  echo "(AAA Start): Deadline Client"
  fileType="deadline-client"
  fileName="DeadlineClient-$appVersion-linux-x64-installer.run"
  fileArgs="--mode unattended --prefix $deadlinePath"
  [ $machineType == JobManager ] && workerService="false" || workerService="true"
  [ $machineType == JobCluster ] && workerStartup="true" || workerStartup="false"
  fileArgs="$fileArgs --launcherdaemon $workerService --slavestartup $workerStartup"
  run_process "$filePath/$fileName $fileArgs" $aaaRoot/$fileType
  mv /tmp/installbuilder_installer.log $aaaRoot/deadline-client.log
  echo "(AAA End): Deadline Client"

  echo "(AAA Start): Deadline Repository"
  [ $machineType == JobManager ] && repositoryPath=$deadlinePath || repositoryPath="/mnt/deadline"
  echo "$aaaPathJobManager/deadlinecommand -StoreDatabaseCredentials $serviceUsername $servicePassword" >> $aaaProfile
  echo "$aaaPathJobManager/deadlinecommand -ChangeRepository Direct $repositoryPath" >> $aaaProfile
  echo "(AAA End): Deadline Repository"

  aaaPath="$aaaPath:$aaaPathJobManager"
fi

if [[ $jobManagers == *Slurm* ]]; then
  dnf -y install slurm
  appVersion=$(echo $imageBuildConfig | jq -r .appVersion.jobManagerSlurm)

  echo "(AAA Start): Slurm Download"
  fileName="slurm-$appVersion.tar.bz2"
  fileLink="https://download.schedmd.com/slurm/$fileName"
  download_file $fileName $fileLink false
  bzip2 -d $fileName
  fileName=$(echo ${fileName%.bz2})
  tar -xf $fileName
  echo "(AAA End): Slurm Download"
fi

if [ "$aaaPath" != "" ]; then
  echo "(AAA Path): ${aaaPath:1}"
  echo 'PATH=$PATH'$aaaPath >> $aaaProfile
fi

echo "(AAA End): Job Manager"
