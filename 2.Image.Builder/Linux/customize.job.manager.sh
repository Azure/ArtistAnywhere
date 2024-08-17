#!/bin/bash -x

echo "Customize (Start): Job Manager"

source /tmp/functions.sh

if [ $machineType == JobManager ]; then
  echo "Customize (Start): NFS Server"
  systemctl --now enable nfs-server
  echo "Customize (End): NFS Server"
fi

if [ $machineType != Storage ]; then
  versionPath=$(echo $buildConfig | jq -r .versionPath.jobManager)
  installRoot="/deadline"
  databaseName="deadline10db"
  binPathJobManager="$installRoot/bin"

  echo "Customize (Start): Deadline Download"
  installFile="Deadline-$versionPath-linux-installers.tar"
  installPath=$(echo ${installFile%.tar})
  downloadUrl="$binStorageHost/Deadline/$versionPath/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  mkdir -p $installPath
  tar -xzf $installFile -C $installPath
  echo "Customize (End): Deadline Download"

  if [ $machineType == JobManager ]; then
    if [ $enableCosmosDB != true ]; then
      echo "Customize (Start): Mongo DB Service"
      if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
        echo never > /sys/kernel/mm/transparent_hugepage/enabled
      fi
      repoPath="/etc/yum.repos.d/mongodb.repo"
      echo "[mongodb-org-5.0]" > $repoPath
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

      # sed -i "s/#security:/security:/" $configFile
      # sed -i "/security:/a\  authorization: enabled" $configFile
      # systemctl restart mongod

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
      # RunProcess "mongosh --authenticationDatabase admin -u $adminUsername -p $adminPassword $mongoScript" $binDirectory/$processType
      RunProcess "mongosh $mongoScript" $binDirectory/$processType
      echo "Customize (End): Mongo DB Users"
    fi

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
  if [ $machineType == JobManager ]; then
    installArgs="$installArgs --slavestartup false --launcherdaemon false"
  else
    [ $machineType == Farm ] && workerStartup="true" || workerStartup="false"
    installArgs="$installArgs --slavestartup $workerStartup --launcherdaemon true"
  fi
  RunProcess "$installPath/$installFile $installArgs" $binDirectory/$processType
  mv /tmp/installbuilder_installer.log $binDirectory/deadline-client.log
  [ $machineType == JobManager ] && repositoryPath=$installRoot || repositoryPath="/mnt/deadline"
  echo "$binPathJobManager/deadlinecommand -StoreDatabaseCredentials $serviceUsername $servicePassword" >> $aaaProfile
  echo "$binPathJobManager/deadlinecommand -ChangeRepository Direct $repositoryPath" >> $aaaProfile
  echo "Customize (End): Deadline Client"

  binPaths="$binPaths:$binPathJobManager"
fi

echo "Customize (PATH): ${binPaths:1}"
echo 'PATH=$PATH'$binPaths >> $aaaProfile

echo "Customize (End): Job Manager"
