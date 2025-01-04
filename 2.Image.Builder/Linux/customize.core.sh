#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Core"

echo "Customize (Start): Image Build Platform"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
dnf -y install epel-release python3-devel gcc-c++ perl lsof cmake bzip2 git openssh
export AZNFS_NONINTERACTIVE_INSTALL=1
version=$(echo $buildConfig | jq -r .version.az_blob_nfs_mount)
curl -L https://github.com/Azure/AZNFS-mount/releases/download/$version/aznfs_install.sh | bash
if [ $machineType == Workstation ]; then
  echo "Customize (Start): Image Build Platform (Workstation)"
  dnf -y group install workstation
  dnf -y module enable nodejs:20
  dnf -y module install nodejs
  echo "Customize (End): Image Build Platform (Workstation)"
fi
echo "Customize (End): Image Build Platform"

if [ "$gpuProvider" != "" ]; then
  echo "Customize (Start): Linux Kernel Dev"
  dnf -y install elfutils-libelf-devel openssl-devel bison flex
  fileName="kernel-devel-5.14.0-362.8.1.el9_3.x86_64.rpm"
  fileLink="https://download.rockylinux.org/vault/rocky/9.3/devel/x86_64/os/Packages/k/$fileName"
  DownloadFile $fileName $fileLink
  rpm -i $fileName
  echo "Customize (End): Linux Kernel Dev"
fi

if [ "$gpuProvider" == NVIDIA ]; then
  echo "Customize (Start): NVIDIA GPU (GRID)"
  fileType="nvidia-gpu-grid"
  fileName="$fileType.run"
  fileLink="https://go.microsoft.com/fwlink/?linkid=874272"
  DownloadFile $fileName $fileLink
  chmod +x $fileName
  dnf -y install libglvnd-devel mesa-vulkan-drivers xorg-x11-drivers pkg-config
  RunProcess "./$fileName --silent" $binDirectory/$fileType
  echo "Customize (End): NVIDIA GPU (GRID)"

  echo "Customize (Start): NVIDIA GPU (CUDA)"
  dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
  dnf -y install cuda
  echo "Customize (End): NVIDIA GPU (CUDA)"

  echo "Customize (Start): NVIDIA OptiX"
  version=$(echo $buildConfig | jq -r .version.nvidia_optix)
  fileType="nvidia-optix"
  fileName="NVIDIA-OptiX-SDK-$version-linux64-x86_64.sh"
  fileLink="$binHostUrl/NVIDIA/OptiX/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  chmod +x $fileName
  filePath="$binDirectory/$fileType/$version"
  mkdir -p $filePath
  RunProcess "./$fileName --skip-license --prefix=$filePath" $binDirectory/$fileType-1
  buildDirectory="$filePath/build"
  mkdir -p $buildDirectory
  dnf -y install libXrandr-devel
  dnf -y install libXcursor-devel
  dnf -y install libXinerama-devel
  dnf -y install mesa-libGL-devel
  dnf -y install mesa-libGL
  RunProcess "cmake -B $buildDirectory -S $filePath/SDK" $binDirectory/$fileType-2
  RunProcess "make -C $buildDirectory" $binDirectory/$fileType-3
  binPaths="$binPaths:$buildDirectory/bin"
  echo "Customize (End): NVIDIA OptiX"
fi

echo "Customize (Start): Azure Managed Lustre (AMLFS) Client"
rpm --import https://packages.microsoft.com/keys/microsoft.asc
repoName="amlfs"
repoPath="/etc/yum.repos.d/$repoName.repo"
echo "[$repoName]" > $repoPath
echo "name=Azure Lustre Packages" >> $repoPath
echo "baseurl=https://packages.microsoft.com/yumrepos/amlfs-el9" >> $repoPath
echo "enabled=1" >> $repoPath
echo "gpgcheck=1" >> $repoPath
echo "gpgkey=https://packages.microsoft.com/keys/microsoft.asc" >> $repoPath
dnf -y install amlfs-lustre-client-2.15.5_41_gc010524-$(uname -r | sed -e "s/\.$(uname -p)$//" | sed -re 's/[-_]/\./g')-1
echo "Customize (End): Azure Managed Lustre (AMLFS) Client"

if [ $machineType == JobScheduler ]; then
  echo "Customize (Start): Azure CLI"
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  dnf -y install https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
  dnf -y install azure-cli
  echo "Customize (End): Azure CLI"
fi

if [ $machineType == Workstation ]; then
  echo "Customize (Start): HP Anyware"
  version=$(echo $buildConfig | jq -r .version.hp_anyware_agent)
  [ "$gpuProvider" == "" ] && fileType="pcoip-agent-standard" || fileType="pcoip-agent-graphics"
  fileName="pcoip-agent-offline-rocky9.4_$version-1.el9.x86_64.tar.gz"
  fileLink="$binHostUrl/Teradici/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  mkdir -p $fileType
  tar -xzf $fileName -C $fileType
  cd $fileType
  RunProcess "./install-pcoip-agent.sh $fileType usb-vhci" $binDirectory/$fileType
  cd $binDirectory
  echo "Customize (End): HP Anyware"
fi

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Core"
