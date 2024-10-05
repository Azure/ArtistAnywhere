#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Core"

echo "Customize (Start): Resize Root Partition"
rootBlockDevice=$(lsblk -J | jq '.blockdevices[] | .["maj:min"] as $version | select($version == "8:0")')
partitionDevice=$(echo $rootBlockDevice | jq -r .name)
partitionNumber=$(echo $rootBlockDevice | jq -r '.children | length')
rootFileSystem=$(df | grep /dev/mapper | cut -d' ' -f1)
growpart /dev/$partitionDevice $partitionNumber
lvextend -l +100%Free $rootFileSystem
xfs_growfs /
echo "Customize (End): Resize Root Partition"

echo "Customize (Start): Image Build Platform"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
dnf -y install epel-release python3-devel gcc gcc-c++ perl lsof cmake git
export AZNFS_NONINTERACTIVE_INSTALL=1
versionPath=$(echo $buildConfig | jq -r .versionPath.azBlobNFSMount)
curl -L https://github.com/Azure/AZNFS-mount/releases/download/$versionPath/aznfs_install.sh | bash
if [ $machineType == Workstation ]; then
  echo "Customize (Start): Image Build Platform (Workstation)"
  dnf -y group install workstation
  dnf -y module enable nodejs:20
  dnf -y module install nodejs
  echo "Customize (End): Image Build Platform (Workstation)"
fi
echo "Customize (End): Image Build Platform"

if [[ $machineType == Storage || "$gpuProvider" != "" ]]; then
  echo "Customize (Start): Linux Kernel Dev"
  dnf -y install elfutils-libelf-devel openssl-devel bison flex
  installFile="kernel-devel-5.14.0-362.8.1.el9_3.x86_64.rpm"
  downloadUrl="https://download.rockylinux.org/vault/rocky/9.3/devel/x86_64/os/Packages/k/$installFile"
  curl -o $installFile -L $downloadUrl
  rpm -i $installFile
  echo "Customize (End): Linux Kernel Dev"
fi

if [ $machineType == Storage ]; then
  echo "Customize (Start): NVIDIA OFED"
  processType="mellanox-ofed"
  installFile="MLNX_OFED_LINUX-24.07-0.6.1.0-rhel9.3-x86_64.tgz"
  downloadUrl="$binHost/NVIDIA/OFED/$installFile"
  curl -o $installFile -L $downloadUrl
  tar -xzf $installFile
  dnf -y install kernel-modules-extra kernel-rpm-macros rpm-build libtool gcc-gfortran pciutils tcl tk
  RunProcess "./MLNX_OFED*/mlnxofedinstall --without-fw-update --add-kernel-support --skip-repo" $binDirectory/$processType
  echo "Customize (End): NVIDIA OFED"
fi

if [ "$gpuProvider" == NVIDIA ]; then
  echo "Customize (Start): NVIDIA GPU (GRID)"
  processType="nvidia-gpu-grid"
  installFile="$processType.run"
  downloadUrl="https://go.microsoft.com/fwlink/?linkid=874272"
  curl -o $installFile -L $downloadUrl
  chmod +x $installFile
  dnf -y install libglvnd-devel mesa-vulkan-drivers xorg-x11-drivers pkg-config
  RunProcess "./$installFile --silent" $binDirectory/$processType
  echo "Customize (End): NVIDIA GPU (GRID)"

  echo "Customize (Start): NVIDIA GPU (CUDA)"
  dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
  dnf -y install cuda
  echo "Customize (End): NVIDIA GPU (CUDA)"

  echo "Customize (Start): NVIDIA OptiX"
  versionPath=$(echo $buildConfig | jq -r .versionPath.nvidiaOptiX)
  processType="nvidia-optix"
  installFile="NVIDIA-OptiX-SDK-$versionPath-linux64-x86_64.sh"
  downloadUrl="$binHost/NVIDIA/OptiX/$versionPath/$installFile"
  curl -o $installFile -L $downloadUrl
  chmod +x $installFile
  installPath="$binDirectory/$processType/$versionPath"
  mkdir -p $installPath
  RunProcess "./$installFile --skip-license --prefix=$installPath" $binDirectory/$processType-1
  buildDirectory="$installPath/build"
  mkdir -p $buildDirectory
  dnf -y install libXrandr-devel
  dnf -y install libXcursor-devel
  dnf -y install libXinerama-devel
  dnf -y install mesa-libGL-devel
  dnf -y install mesa-libGL
  RunProcess "cmake -B $buildDirectory -S $installPath/SDK" $binDirectory/$processType-2
  RunProcess "make -C $buildDirectory" $binDirectory/$processType-3
  binPaths="$binPaths:$buildDirectory/bin"
  echo "Customize (End): NVIDIA OptiX"
fi

if [[ $machineType == Storage || $machineType == JobScheduler ]]; then
  echo "Customize (Start): Azure CLI"
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  dnf -y install https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm
  dnf -y install azure-cli
  echo "Customize (End): Azure CLI"
fi

if [ $machineType == Workstation ]; then
  echo "Customize (Start): HP Anyware"
  versionPath=$(echo $buildConfig | jq -r .versionPath.hpAnywareAgent)
  [ "$gpuProvider" == "" ] && processType="pcoip-agent-standard" || processType="pcoip-agent-graphics"
  installFile="pcoip-agent-offline-rocky9.4_$versionPath-1.el9.x86_64.tar.gz"
  downloadUrl="$binHost/Teradici/$versionPath/$installFile"
  curl -o $installFile -L $downloadUrl
  mkdir -p $processType
  tar -xzf $installFile -C $processType
  cd $processType
  RunProcess "./install-pcoip-agent.sh $processType usb-vhci" $binDirectory/$processType
  cd $binDirectory
  echo "Customize (End): HP Anyware"
fi

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Core"
