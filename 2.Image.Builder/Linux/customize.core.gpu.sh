#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Core (GPU)"

if [ "$gpuProvider" != "" ]; then
  echo "Customize (Start): Linux Kernel Devel"
  dnf -y install elfutils-libelf-devel openssl-devel bison flex
  fileName="kernel-devel-5.14.0-503.14.1.el9_5.x86_64.rpm"
  fileLink="$binHostUrl/Linux/$fileName"
  download_file $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  rpm -i $fileName
  echo "Customize (End): Linux Kernel Devel"
fi

if [ "$gpuProvider" == NVIDIA.GRID ]; then
  echo "Customize (Start): NVIDIA GPU (GRID)"
  fileType="nvidia-gpu-grid"
  fileName="$fileType.run"
  fileLink="https://go.microsoft.com/fwlink/?linkid=874272"
  download_file $fileName $fileLink
  chmod +x $fileName
  dnf -y install libglvnd-devel mesa-vulkan-drivers xorg-x11-drivers
  run_process "./$fileName --silent" $binDirectory/$fileType
  echo "Customize (End): NVIDIA GPU (GRID)"
fi

if [[ "$gpuProvider" == NVIDIA* ]]; then
  echo "Customize (Start): NVIDIA GPU (CUDA)"
  dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
  dnf -y install cuda
  echo "Customize (End): NVIDIA GPU (CUDA)"
fi

if [ $machineType == Workstation ]; then
  echo "Customize (Start): HP Anyware"
  version=$(echo $buildConfig | jq -r .version.hp_anyware_agent)
  [ "$gpuProvider" == "" ] && fileType="pcoip-agent-standard" || fileType="pcoip-agent-graphics"
  fileName="pcoip-agent-offline-rhel9.5_$version-1.el9.x86_64.tar.gz"
  fileLink="$binHostUrl/Teradici/$version/$fileName"
  download_file $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  mkdir -p $fileType
  tar -xzf $fileName -C $fileType
  cd $fileType
  run_process "./install-pcoip-agent.sh $fileType usb-vhci" $binDirectory/$fileType
  cd $binDirectory
  echo "Customize (End): HP Anyware"
fi

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Core (GPU)"
