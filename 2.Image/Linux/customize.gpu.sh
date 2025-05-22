#!/bin/bash -ex

source /tmp/functions.sh

echo "(AAA Start): Core (GPU)"

if [ "$gpuProvider" != "" ]; then
  echo "(AAA Start): Linux Kernel Devel"
  dnf -y install elfutils-libelf-devel openssl-devel bison flex
  fileName="kernel-devel-5.14.0-503.14.1.el9_5.x86_64.rpm"
  fileLink="$blobStorageEndpointUrl/Linux/$fileName"
  download_file $fileName $fileLink true
  rpm -i $fileName
  echo "(AAA End): Linux Kernel Devel"
fi

if [ "$gpuProvider" == NVIDIA ]; then
  if [ $machineType == VDI ]; then
    echo "(AAA Start): NVIDIA GPU (GRID)"
    fileType="nvidia-gpu-grid"
    fileName="$fileType.run"
    fileLink="https://go.microsoft.com/fwlink/?linkid=874272"
    download_file $fileName $fileLink false
    chmod +x $fileName
    dnf -y install libglvnd-devel mesa-vulkan-drivers xorg-x11-drivers
    run_process "./$fileName --silent" $binDirectory/$fileType
    echo "(AAA End): NVIDIA GPU (GRID)"
  elif [ $machineType == Cluster ]; then
    echo "(AAA Start): NVIDIA GPU (CUDA)"
    dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
    dnf -y install cuda
    echo "(AAA End): NVIDIA GPU (CUDA)"
  fi
fi

if [ "$gpuProvider" == AMD ]; then
  if [ $machineType == VDI ]; then
    echo "(AAA Start): AMD GPU (Radeon)"
    echo "(AAA End): AMD GPU (Radeon)"
  elif [ $machineType == Cluster ]; then
    echo "(AAA Start): AMD GPU (Instinct)"
    echo "(AAA End): AMD GPU (Instinct)"
  fi
fi

if [ $machineType == VDI ]; then
  echo "(AAA Start): HP Anyware"
  appVersion=$(echo $buildConfig | jq -r .appVersion.hpAnywareAgent)
  [ "$gpuProvider" == "" ] && fileType="pcoip-agent-standard" || fileType="pcoip-agent-graphics"
  fileName="pcoip-agent-offline-rhel9.5_$appVersion-1.el9.x86_64.tar.gz"
  fileLink="$blobStorageEndpointUrl/Teradici/$appVersion/$fileName"
  download_file $fileName $fileLink true
  mkdir -p $fileType
  tar -xzf $fileName -C $fileType
  cd $fileType
  run_process "./install-pcoip-agent.sh $fileType usb-vhci" $binDirectory/$fileType
  cd $binDirectory
  echo "(AAA End): HP Anyware"
fi

if [ "$binPaths" != "" ]; then
  echo "(AAA Path): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "(AAA End): Core (GPU)"
