#!/bin/bash -ex

binPaths=""
binDirectory="/usr/local/bin"
cd $binDirectory

aaaProfile="/etc/profile.d/aaa.sh"
touch $aaaProfile

source /tmp/functions.sh

echo "Customize (Start): Image Build Parameters"
buildConfig=$(echo $buildConfigEncoded | base64 -d)
machineType=$(echo $buildConfig | jq -r .machineType)
gpuProvider=$(echo $buildConfig | jq -r .gpuProvider)
renderEngines=$(echo $buildConfig | jq -c .renderEngines)
binStorageHost=$(echo $buildConfig | jq -r .binStorage.host)
binStorageAuth=$(echo $buildConfig | jq -r .binStorage.auth)
databaseUsername=$(echo $buildConfig | jq -r .schedulerDatabase.username)
databasePassword=$(echo $buildConfig | jq -r .schedulerDatabase.password)
databaseAuthRole=$(echo $buildConfig | jq -r .schedulerDatabase.authRole)
echo "Machine Type: $machineType"
echo "GPU Provider: $gpuProvider"
echo "Render Engines: $renderEngines"
echo "Customize (End): Image Build Parameters"

echo "Customize (Start): Image Build Platform"
dnf -y install kernel-devel-$(uname -r)
if [ $machineType == Workstation ]; then
  echo "Customize (Start): Image Build Platform (Workstation)"
  dnf -y group install workstation
  dnf -y module install nodejs
  echo "Customize (End): Image Build Platform (Workstation)"
fi
echo "Customize (End): Image Build Platform"

if [ $machineType == Storage ]; then
  echo "Customize (Start): NVIDIA OFED"
  installType="mellanox-ofed"
  installFile="MLNX_OFED_LINUX-23.10-1.1.9.0-rhel8.9-x86_64.tgz"
  downloadUrl="$binStorageHost/NVIDIA/OFED/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  tar -xzf $installFile
  dnf -y install kernel-modules-extra kernel-rpm-macros rpm-build libtool gcc-gfortran pciutils tcl tk
  StartProcess "./MLNX_OFED*/mlnxofedinstall --without-fw-update --add-kernel-support --skip-repo --force" $binDirectory/$installType
  echo "Customize (End): NVIDIA OFED"
fi

if [ "$gpuProvider" == NVIDIA ]; then
  echo "Customize (Start): NVIDIA GPU (GRID)"
  installType="nvidia-gpu-grid"
  installFile="$installType.run"
  downloadUrl="https://go.microsoft.com/fwlink/?linkid=874272"
  curl -o $installFile -L $downloadUrl
  chmod +x $installFile
  dnf -y install mesa-vulkan-drivers libglvnd-devel
  StartProcess "./$installFile --silent" $binDirectory/$installType
  echo "Customize (End): NVIDIA GPU (GRID)"

  echo "Customize (Start): NVIDIA GPU (CUDA)"
  installType="nvidia-cuda"
  dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
  dnf -y install cuda
  echo "Customize (End): NVIDIA GPU (CUDA)"

  echo "Customize (Start): NVIDIA OptiX"
  versionInfo="8.0.0"
  installType="nvidia-optix"
  installFile="NVIDIA-OptiX-SDK-$versionInfo-linux64-x86_64.sh"
  downloadUrl="$binStorageHost/NVIDIA/OptiX/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  chmod +x $installFile
  installPath="$binDirectory/$installType/$versionInfo"
  mkdir -p $installPath
  StartProcess "./$installFile --skip-license --prefix=$installPath" $binDirectory/$installType
  buildDirectory="$installPath/build"
  mkdir -p $buildDirectory
  dnf -y install mesa-libGL
  dnf -y install mesa-libGL-devel
  dnf -y install libXrandr-devel
  dnf -y install libXinerama-devel
  dnf -y install libXcursor-devel
  StartProcess "cmake -B $buildDirectory -S $installPath/SDK" $binDirectory/$installType
  StartProcess "make -C $buildDirectory" $binDirectory/$installType
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
  versionInfo="v4"
  installType="pbrt"
  installPath="/usr/local/pbrt"
  mkdir -p $installPath
  dnf -y install mesa-libGL-devel
  dnf -y install libXrandr-devel
  dnf -y install libXinerama-devel
  dnf -y install libXcursor-devel
  dnf -y install libXi-devel
  StartProcess "git clone --recursive https://github.com/mmp/$installType-$versionInfo.git" $binDirectory/$installType
  StartProcess "cmake -B $installPath -S $binDirectory/$installType-$versionInfo" $binDirectory/$installType
  StartProcess "make -C $installPath" $binDirectory/$installType
  binPaths="$binPaths:$installPath"
  echo "Customize (End): PBRT"
fi

if [[ $renderEngines == *Blender* ]]; then
  echo "Customize (Start): Blender"
  versionInfo="4.0.2"
  versionType="linux-x64"
  installType="blender"
  installPath="/usr/local/$installType"
  installFile="$installType-$versionInfo-$versionType.tar.xz"
  downloadUrl="$binStorageHost/Blender/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  tar -xJf $installFile
  dnf -y install mesa-libGL
  dnf -y install libXxf86vm
  dnf -y install libXfixes
  dnf -y install libXi
  dnf -y install libSM
  mkdir -p $installPath
  mv $installType-$versionInfo-$versionType/* $installPath
  binPaths="$binPaths:$installPath"
  echo "Customize (End): Blender"
fi

if [[ $renderEngines == *RenderMan* ]]; then
  echo "Customize (Start): RenderMan"
  versionInfo="25.2.0"
  installType="renderman"
  installFile="RenderMan-InstallerNCR-${versionInfo}_2282810-linuxRHEL7_gcc93icc219.x86_64.rpm"
  downloadUrl="$binStorageHost/RenderMan/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  StartProcess "rpm -i $installFile" $binDirectory/$installType
  echo "Customize (End): RenderMan"
fi

if [[ $renderEngines == *Maya* ]]; then
  echo "Customize (Start): Maya"
  versionInfo="2024_0_1"
  installType="autodesk-maya"
  installFile="Autodesk_Maya_${versionInfo}_Update_Linux_64bit.tgz"
  downloadUrl="$binStorageHost/Maya/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  mkdir -p $installType
  tar -xzf $installFile -C $installType
  dnf -y install mesa-libGL
  dnf -y install mesa-libGLU
  dnf -y install alsa-lib
  dnf -y install libXxf86vm
  dnf -y install libXmu
  dnf -y install libXpm
  dnf -y install libnsl
  dnf -y install gtk3
  StartProcess "./$installType/Setup --silent" $binDirectory/$installType
  binPaths="$binPaths:/usr/autodesk/maya/bin"
  echo "Customize (End): Maya"
fi

if [[ $renderEngines == *Houdini* ]]; then
  echo "Customize (Start): Houdini"
  versionInfo="20.0.506"
  versionEULA="2021-10-13"
  installType="houdini"
  installFile="$installType-$versionInfo-linux_x86_64_gcc11.2.tar.gz"
  downloadUrl="$binStorageHost/Houdini/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  tar -xzf $installFile
  [[ $machineType == Workstation ]] && desktopMenus=--install-menus || desktopMenus=--no-install-menus
  [[ $renderEngines == *Maya* ]] && mayaPlugIn=--install-engine-maya || mayaPlugIn=--no-install-engine-maya
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
  StartProcess "./houdini*/houdini.install --auto-install --make-dir --no-install-license --accept-EULA $versionEULA $desktopMenus $mayaPlugIn" $binDirectory/$installType
  binPaths="$binPaths:/opt/hfs$versionInfo/bin"
  echo "Customize (End): Houdini"
fi

if [ $machineType == Scheduler ]; then
  echo "Customize (Start): NFS Server"
  systemctl --now enable nfs-server
  echo "Customize (End): NFS Server"
fi

if [ $machineType != Storage ]; then
  versionInfo="10.3.1.4"
  installRoot="/deadline"
  databaseHost=$(hostname)
  databasePort=27017
  databaseName="deadline10db"
  binPathScheduler="$installRoot/bin"

  echo "Customize (Start): Deadline Download"
  installFile="Deadline-$versionInfo-linux-installers.tar"
  installPath=$(echo ${installFile%.tar})
  downloadUrl="$binStorageHost/Deadline/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  mkdir -p $installPath
  tar -xzf $installFile -C $installPath
  echo "Customize (End): Deadline Download"

  if [ $machineType == Scheduler ]; then
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
    sed -i "s/#security:/security:/" $configFile
    sed -i "/security:/a\  authorization: disabled" $configFile
    systemctl --now enable mongod
    sleep 5s
    echo "Customize (End): Mongo DB Service"

    echo "Customize (Start): Mongo DB User"
    installType="mongo-create-user"
    createUserScript="$installType.js"
    echo "db = db.getSiblingDB(\"$databaseName\");" > $createUserScript
    echo "db.createUser({" >> $createUserScript
    echo "user: \"$databaseUsername\"," >> $createUserScript
    echo "pwd: \"$databasePassword\"," >> $createUserScript
    echo "roles: [" >> $createUserScript
    echo "{ role: \"$databaseAuthRole\", db: \"$databaseName\" }" >> $createUserScript
    echo "]})" >> $createUserScript
    StartProcess "mongosh $createUserScript" $binDirectory/$installType.log
    echo "Customize (End): Mongo DB User"

    echo "Customize (Start): Deadline Server"
    installType="deadline-repository"
    installFile="DeadlineRepository-$versionInfo-linux-x64-installer.run"
    StartProcess "$installPath/$installFile --mode unattended --dbLicenseAcceptance accept --prefix $installRoot --dbhost $databaseHost --dbport $databasePort --dbname $databaseName --dbuser $databaseUsername --dbpassword $databasePassword --dbauth true --installmongodb false" $binDirectory/$installType
    mv /tmp/installbuilder_installer.log $binDirectory/deadline-repository.log
    echo "$installRoot *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    exportfs -r
    echo "Customize (End): Deadline Server"
  fi

  echo "Customize (Start): Deadline Client"
  installType="deadline-client"
  installFile="DeadlineClient-$versionInfo-linux-x64-installer.run"
  installArgs="--mode unattended --prefix $installRoot"
  if [ $machineType == Scheduler ]; then
    installArgs="$installArgs --slavestartup false --launcherdaemon false"
  else
    [ $machineType == Farm ] && workerStartup=true || workerStartup=false
    installArgs="$installArgs --slavestartup $workerStartup --launcherdaemon true"
  fi
  StartProcess "$installPath/$installFile $installArgs" $binDirectory/$installType
  mv /tmp/installbuilder_installer.log $binDirectory/deadline-client.log
  StartProcess "$binPathScheduler/deadlinecommand -StoreDatabaseCredentials $databaseUsername $databasePassword" $binDirectory/$installType-auth
  echo "Customize (End): Deadline Client"

  binPaths="$binPaths:$binPathScheduler"
fi

if [ $machineType == Workstation ]; then
  echo "Customize (Start): HP Anyware"
  versionInfo="23.12"
  [ "$gpuProvider" == "" ] && installType=pcoip-agent-standard || installType=pcoip-agent-graphics
  installFile="pcoip-agent-offline-rocky8.8_$versionInfo.2-1.el8.x86_64.tar.gz"
  downloadUrl="$binStorageHost/Teradici/$versionInfo/$installFile$binStorageAuth"
  curl -o $installFile -L $downloadUrl
  mkdir -p $installType
  tar -xzf $installFile -C $installType
  cd $installType
  StartProcess "./install-pcoip-agent.sh $installType usb-vhci" $binDirectory/$installType
  cd $binDirectory
  echo "Customize (End): HP Anyware"
fi

echo "Customize (PATH): ${binPaths:1}"
echo 'PATH=$PATH'$binPaths >> $aaaProfile
