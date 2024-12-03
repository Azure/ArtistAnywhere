#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Job Scheduler (Deadline)"

if [ $machineType != Storage ]; then
  version=$(echo $buildConfig | jq -r .version.job_scheduler_deadline)
  installRoot="/deadline"
  databaseHost=$(hostname)
  databasePort=27017
  databaseName="deadline10db"
  binPathJobScheduler="$installRoot/bin"

  echo "Customize (Start): Deadline Download"
  fileName="Deadline-$version-linux-installers.tar"
  filePath=$(echo ${fileName%.tar})
  fileLink="$binHostUrl/Deadline/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  mkdir -p $filePath
  tar -xzf $fileName -C $filePath
  echo "Customize (End): Deadline Download"

  if [ $machineType == JobScheduler ]; then
    echo "Customize (Start): Mongo DB Service"
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
    echo "Customize (End): Mongo DB Service"

    echo "Customize (Start): Mongo DB Users"
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
    RunProcess "mongosh $fileName" $binDirectory/$fileType

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
    RunProcess "mongosh $fileName" $binDirectory/$fileType
    echo "Customize (End): Mongo DB Users"

    echo "Customize (Start): Deadline Server"
    fileType="deadline-repository"
    fileName="DeadlineRepository-$version-linux-x64-installer.run"
    export DB_PASSWORD=$servicePassword
    RunProcess "$filePath/$fileName --mode unattended --dbLicenseAcceptance accept --prefix $installRoot --dbhost $databaseHost --dbport $databasePort --dbname $databaseName --dbuser $serviceUsername --dbpassword env:DB_PASSWORD --dbauth true --installmongodb false" $binDirectory/$fileType
    mv /tmp/installbuilder_installer.log $binDirectory/deadline-repository.log
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

  echo "Customize (Start): Deadline Repository"
  [ $machineType == JobScheduler ] && repositoryPath=$installRoot || repositoryPath="/mnt/deadline"
  echo "$binPathJobScheduler/deadlinecommand -StoreDatabaseCredentials $serviceUsername $servicePassword" >> $aaaProfile
  echo "$binPathJobScheduler/deadlinecommand -ChangeRepository Direct $repositoryPath" >> $aaaProfile
  echo "Customize (End): Deadline Repository"

  binPaths="$binPaths:$binPathJobScheduler"
fi

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Job Scheduler (Deadline)"
