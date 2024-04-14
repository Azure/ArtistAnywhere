#!/bin/bash -x

binPaths=""
binDirectory="/usr/local/bin"
cd $binDirectory

aaaProfile="/etc/profile.d/aaa.sh"
touch $aaaProfile

source /tmp/functions.sh

echo "Customize (Start): Image Build Parameters"
dnf -y install jq
buildConfig=$(echo $buildConfigEncoded | base64 -d)
machineType=$(echo $buildConfig | jq -r .machineType)
gpuProvider=$(echo $buildConfig | jq -r .gpuProvider)
binStorageHost=$(echo $buildConfig | jq -r .binStorage.host)
binStorageAuth=$(echo $buildConfig | jq -r .binStorage.auth)
adminUsername=$(echo $buildConfig | jq -r .dataPlatform.adminLogin.userName)
adminPassword=$(echo $buildConfig | jq -r .dataPlatform.adminLogin.userPassword)
databaseUsername=$(echo $buildConfig | jq -r .dataPlatform.jobDatabase.serviceLogin.userName)
databasePassword=$(echo $buildConfig | jq -r .dataPlatform.jobDatabase.serviceLogin.userPassword)
databaseHost=$(echo $buildConfig | jq -r .dataPlatform.jobDatabase.host)
databasePort=$(echo $buildConfig | jq -r .dataPlatform.jobDatabase.port)
renderEngines=$(echo $buildConfig | jq -c .renderEngines)
enableCosmosDB=false
if [ "$databaseHost" == "" ]; then
  databaseHost=$(hostname)
else
  enableCosmosDB=true
fi
echo "Machine Type: $machineType"
echo "GPU Provider: $gpuProvider"
echo "Admin Username: $adminUsername"
echo "Admin Password: $adminPassword"
echo "Enable Cosmos DB: $enableCosmosDB"
echo "Database Username: $databaseUsername"
echo "Database Password: $databasePassword"
echo "Database Host: $databaseHost"
echo "Database Port: $databasePort"
echo "Render Engines: $renderEngines"
echo "Customize (End): Image Build Parameters"

echo "Customize (Start): Image Build Platform"
# systemctl --now disable firewalld
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
dnf -y install gcc gcc-c++ perl cmake git docker
dnf -y install kernel-devel-$(uname -r) python3-devel
export AZNFS_NONINTERACTIVE_INSTALL=1
curl -L https://github.com/Azure/AZNFS-mount/releases/download/2.0.4/aznfs_install.sh | bash
if [ $machineType == Workstation ]; then
  echo "Customize (Start): Image Build Platform (Workstation)"
  dnf -y group install workstation
  dnf -y module install nodejs
  echo "Customize (End): Image Build Platform (Workstation)"
fi
echo "Customize (End): Image Build Platform"

if [ $machineType == Storage ]; then
  echo "Customize (Start): NVIDIA OFED"
  processType="mellanox-ofed"
  installFile="MLNX_OFED_LINUX-23.10-1.1.9.0-rhel8.9-x86_64.tgz"
  downloadUrl="$binStorageHost/NVIDIA/OFED/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  tar -xzf $installFile
  dnf -y install kernel-modules-extra kernel-rpm-macros rpm-build libtool gcc-gfortran pciutils tcl tk
  RunProcess "./MLNX_OFED*/mlnxofedinstall --without-fw-update --add-kernel-support --skip-repo --force" $binDirectory/$processType
  echo "Customize (End): NVIDIA OFED"
fi

if [ "$gpuProvider" == NVIDIA ]; then
  echo "Customize (Start): NVIDIA GPU (GRID)"
  processType="nvidia-gpu-grid"
  installFile="$processType.run"
  downloadUrl="https://go.microsoft.com/fwlink/?linkid=874272"
  curl -o $installFile -L $downloadUrl
  chmod +x $installFile
  dnf -y install mesa-vulkan-drivers libglvnd-devel
  RunProcess "./$installFile --silent" $binDirectory/$processType
  echo "Customize (End): NVIDIA GPU (GRID)"

  echo "Customize (Start): NVIDIA GPU (CUDA)"
  dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
  dnf -y install cuda
  echo "Customize (End): NVIDIA GPU (CUDA)"

  echo "Customize (Start): NVIDIA OptiX"
  versionPath=$(echo $buildConfig | jq -r .versionPath.nvidiaOptiX)
  processType="nvidia-optix"
  installFile="NVIDIA-OptiX-SDK-$versionPath-linux64-x86_64.sh"
  downloadUrl="$binStorageHost/NVIDIA/OptiX/$versionPath/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  chmod +x $installFile
  installPath="$binDirectory/$processType/$versionPath"
  mkdir -p $installPath
  RunProcess "./$installFile --skip-license --prefix=$installPath" $binDirectory/$processType-1
  buildDirectory="$installPath/build"
  mkdir -p $buildDirectory
  dnf -y install mesa-libGL
  dnf -y install mesa-libGL-devel
  dnf -y install libXrandr-devel
  dnf -y install libXinerama-devel
  dnf -y install libXcursor-devel
  RunProcess "cmake -B $buildDirectory -S $installPath/SDK" $binDirectory/$processType-2
  RunProcess "make -C $buildDirectory" $binDirectory/$processType-3
  binPaths="$binPaths:$buildDirectory/bin"
  echo "Customize (End): NVIDIA OptiX"
fi

if [[ $machineType == Storage || $machineType == Scheduler ]]; then
  echo "Customize (Start): Azure CLI"
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  dnf -y install https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
  dnf -y install azure-cli
  echo "Customize (End): Azure CLI"
fi

if [[ $renderEngines == *PBRT* ]]; then
  echo "Customize (Start): PBRT"
  versionPath=$(echo $buildConfig | jq -r .versionPath.renderPBRT)
  processType="pbrt"
  installPath="/usr/local/pbrt"
  mkdir -p $installPath
  dnf -y install mesa-libGL-devel
  dnf -y install libXrandr-devel
  dnf -y install libXinerama-devel
  dnf -y install libXcursor-devel
  dnf -y install libXi-devel
  RunProcess "git clone --recursive https://github.com/mmp/$processType-$versionPath.git" $binDirectory/$processType-1
  RunProcess "cmake -B $installPath -S $binDirectory/$processType-$versionPath" $binDirectory/$processType-2
  RunProcess "make -C $installPath" $binDirectory/$processType-3
  binPaths="$binPaths:$installPath"
  echo "Customize (End): PBRT"
fi

if [[ $renderEngines == *Blender* ]]; then
  echo "Customize (Start): Blender"
  versionPath=$(echo $buildConfig | jq -r .versionPath.renderBlender)
  versionType="linux-x64"
  processType="blender"
  installPath="/usr/local/$processType"
  installFile="$processType-$versionPath-$versionType.tar.xz"
  downloadUrl="$binStorageHost/Blender/$versionPath/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  tar -xJf $installFile
  dnf -y install mesa-libGL
  dnf -y install libXxf86vm
  dnf -y install libXfixes
  dnf -y install libXi
  dnf -y install libSM
  mkdir -p $installPath
  mv $processType-$versionPath-$versionType/* $installPath
  binPaths="$binPaths:$installPath"
  echo "Customize (End): Blender"
fi

if [[ $renderEngines == *Maya* ]]; then
  echo "Customize (Start): Maya"
  versionPath=$(echo $buildConfig | jq -r .versionPath.renderMaya)
  processType="autodesk-maya"
  installFile="Autodesk_Maya_${versionPath}_Update_Linux_64bit.tgz"
  downloadUrl="$binStorageHost/Maya/$versionPath/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  mkdir -p $processType
  tar -xzf $installFile -C $processType
  dnf -y install mesa-libGL
  dnf -y install mesa-libGLU
  dnf -y install alsa-lib
  dnf -y install libXxf86vm
  dnf -y install libXmu
  dnf -y install libXpm
  dnf -y install libnsl
  dnf -y install gtk3
  RunProcess "./$processType/Setup --silent" $binDirectory/$processType
  binPaths="$binPaths:/usr/autodesk/maya/bin"
  echo "Customize (End): Maya"
fi

if [[ $renderEngines == *Houdini* ]]; then
  echo "Customize (Start): Houdini"
  versionPath=$(echo $buildConfig | jq -r .versionPath.renderHoudini)
  versionEULA="2021-10-13"
  processType="houdini"
  installFile="$processType-$versionPath-linux_x86_64_gcc11.2.tar.gz"
  downloadUrl="$binStorageHost/Houdini/$versionPath/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  tar -xzf $installFile
  [ $machineType == Workstation ] && desktopMenus="--install-menus" || desktopMenus="--no-install-menus"
  [[ $renderEngines == *Maya* ]] && mayaPlugIn="--install-engine-maya" || mayaPlugIn="--no-install-engine-maya"
  dnf -y install mesa-libGL
  dnf -y install libXcomposite
  dnf -y install libXdamage
  dnf -y install libXrandr
  dnf -y install libXcursor
  dnf -y install libXi
  dnf -y install libXtst
  dnf -y install libXScrnSaver
  dnf -y install alsa-lib
  dnf -y install libnsl
  dnf -y install avahi
  RunProcess "./houdini*/houdini.install --auto-install --make-dir --no-install-license --accept-EULA $versionEULA $desktopMenus $mayaPlugIn" $binDirectory/$processType
  binPaths="$binPaths:/opt/hfs$versionPath/bin"
  echo "Customize (End): Houdini"
fi

if [ $machineType == Scheduler ]; then
  echo "Customize (Start): NFS Server"
  systemctl --now enable nfs-server
  echo "Customize (End): NFS Server"
fi

if [ $machineType != Storage ]; then
  versionPath=$(echo $buildConfig | jq -r .versionPath.jobScheduler)
  installRoot="/deadline"
  databaseName="deadline10db"
  binPathScheduler="$installRoot/bin"

  echo "Customize (Start): Deadline Download"
  installFile="Deadline-$versionPath-linux-installers.tar"
  installPath=$(echo ${installFile%.tar})
  downloadUrl="$binStorageHost/Deadline/$versionPath/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  mkdir -p $installPath
  tar -xzf $installFile -C $installPath
  echo "Customize (End): Deadline Download"

  if [ $machineType == Scheduler ]; then
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
      echo "  user: \"$databaseUsername\"," >> $mongoScript
      echo "  pwd: \"$databasePassword\"," >> $mongoScript
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
    export DB_PASSWORD=$databasePassword
    RunProcess "$installPath/$installFile --mode unattended --dbLicenseAcceptance accept --prefix $installRoot --dbhost $databaseHost --dbport $databasePort --dbname $databaseName --dbuser $databaseUsername --dbpassword env:DB_PASSWORD --dbauth true --installmongodb false" $binDirectory/$processType
    mv /tmp/installbuilder_installer.log $binDirectory/deadline-repository.log
    echo "$installRoot *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    exportfs -r
    echo "Customize (End): Deadline Server"
  fi

  echo "Customize (Start): Deadline Client"
  processType="deadline-client"
  installFile="DeadlineClient-$versionPath-linux-x64-installer.run"
  installArgs="--mode unattended --prefix $installRoot"
  if [ $machineType == Scheduler ]; then
    installArgs="$installArgs --slavestartup false --launcherdaemon false"
  else
    [ $machineType == Farm ] && workerStartup="true" || workerStartup="false"
    installArgs="$installArgs --slavestartup $workerStartup --launcherdaemon true"
  fi
  RunProcess "$installPath/$installFile $installArgs" $binDirectory/$processType
  mv /tmp/installbuilder_installer.log $binDirectory/deadline-client.log
  [ $machineType == Scheduler ] && repositoryPath=$installRoot || repositoryPath="/mnt/deadline"
  echo "$binPathScheduler/deadlinecommand -StoreDatabaseCredentials $databaseUsername $databasePassword" >> $aaaProfile
  echo "$binPathScheduler/deadlinecommand -ChangeRepository Direct $repositoryPath" >> $aaaProfile
  echo "Customize (End): Deadline Client"

  binPaths="$binPaths:$binPathScheduler"
fi

if [ $machineType == Workstation ]; then
  echo "Customize (Start): HP Anyware"
  versionPath=$(echo $buildConfig | jq -r .versionPath.pcoipAgent)
  [ "$gpuProvider" == "" ] && processType="pcoip-agent-standard" || processType="pcoip-agent-graphics"
  installFile="pcoip-agent-offline-rocky8.8_$versionPath-1.el8.x86_64.tar.gz"
  downloadUrl="$binStorageHost/Teradici/$versionPath/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  mkdir -p $processType
  tar -xzf $installFile -C $processType
  cd $processType
  RunProcess "./install-pcoip-agent.sh $processType usb-vhci" $binDirectory/$processType
  cd $binDirectory
  echo "Customize (End): HP Anyware"
fi

echo "Customize (PATH): ${binPaths:1}"
echo 'PATH=$PATH'$binPaths >> $aaaProfile
