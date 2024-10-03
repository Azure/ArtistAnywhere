#!/bin/bash -x

source /tmp/functions.sh

echo "Customize (Start): Job Scheduler"

if [ $machineType != Storage ]; then
  versionPath=$(echo $buildConfig | jq -r .versionPath.jobSchedulerDeadline)
  installRoot="/deadline"
  databaseHost=$(hostname)
  databasePort=27017
  databaseName="deadline10db"
  binPathJobScheduler="$installRoot/bin"

  echo "Customize (Start): Deadline Download"
  installFile="Deadline-$versionPath-linux-installers.tar"
  installPath=$(echo ${installFile%.tar})
  downloadUrl="$binStorageHost/Deadline/$versionPath/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  mkdir -p $installPath
  tar -xzf $installFile -C $installPath
  echo "Customize (End): Deadline Download"

  if [ $machineType == JobScheduler ]; then
    echo "Customize (Start): Mongo DB Service"
    if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
      echo never > /sys/kernel/mm/transparent_hugepage/enabled
    fi
    repoName="mongodb-org-5.0"
    repoPath="/etc/yum.repos.d/$repoName.repo"
    echo "[$repoName]" > $repoPath
    echo "name=MongoDB" >> $repoPath
    echo "baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/5.0/x86_64/" >> $repoPath
    echo "gpgcheck=1" >> $repoPath
    echo "enabled=1" >> $repoPath
    echo "gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc" >> $repoPath
    dnf -y install mongodb-org
    configFile="/etc/mongod.conf"
    sed -i "s/bindIp: 127.0.0.1/bindIp: 0.0.0.0/" $configFile
    sed -i "/bindIp: 0.0.0.0/a\  tls:" $configFile
    sed -i "/tls:/a\    mode: disabled" $configFile
    systemctl --now enable mongod
    echo "Customize (End): Mongo DB Service"

    echo "Customize (Start): Mongo DB Users"
    processType="mongo-create-admin-user"
    mongoScript="$processType.js"
    echo "use admin" > $mongoScript
    echo "db.createUser({" >> $mongoScript
    echo "  user: \"$adminUsername\"," >> $mongoScript
    echo "  pwd: \"$adminPassword\"," >> $mongoScript
    echo "  roles: [" >> $mongoScript
    echo "    { role: \"userAdminAnyDatabase\", db: \"admin\" }," >> $mongoScript
    echo "    { role: \"readWriteAnyDatabase\", db: \"admin\" }" >> $mongoScript
    echo "  ]" >> $mongoScript
    echo "})" >> $mongoScript
    RunProcess "mongosh $mongoScript" $binDirectory/$processType

    processType="mongo-create-database-user"
    mongoScript="$processType.js"
    echo "db = db.getSiblingDB(\"$databaseName\");" > $mongoScript
    echo "db.createUser({" >> $mongoScript
    echo "  user: \"$serviceUsername\"," >> $mongoScript
    echo "  pwd: \"$servicePassword\"," >> $mongoScript
    echo "  roles: [" >> $mongoScript
    echo "    { role: \"dbOwner\", db: \"$databaseName\" }" >> $mongoScript
    echo "  ]" >> $mongoScript
    echo "})" >> $mongoScript
    RunProcess "mongosh $mongoScript" $binDirectory/$processType
    echo "Customize (End): Mongo DB Users"

    echo "Customize (Start): Deadline Server"
    processType="deadline-repository"
    installFile="DeadlineRepository-$versionPath-linux-x64-installer.run"
    export DB_PASSWORD=$servicePassword
    RunProcess "$installPath/$installFile --mode unattended --dbLicenseAcceptance accept --prefix $installRoot --dbhost $databaseHost --dbport $databasePort --dbname $databaseName --dbuser $serviceUsername --dbpassword env:DB_PASSWORD --dbauth true --installmongodb false" $binDirectory/$processType
    mv /tmp/installbuilder_installer.log $binDirectory/deadline-repository.log
    echo "$installRoot *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    exportfs -r
    echo "Customize (End): Deadline Server"
  fi

  echo "Customize (Start): Deadline Client"
  processType="deadline-client"
  installFile="DeadlineClient-$versionPath-linux-x64-installer.run"
  installArgs="--mode unattended --prefix $installRoot"
  if [ $machineType == JobScheduler ]; then
    installArgs="$installArgs --slavestartup false --launcherdaemon false"
  else
    [ $machineType == Farm ] && workerStartup="true" || workerStartup="false"
    installArgs="$installArgs --slavestartup $workerStartup --launcherdaemon true"
  fi
  RunProcess "$installPath/$installFile $installArgs" $binDirectory/$processType
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

echo "Customize (End): Job Scheduler"
