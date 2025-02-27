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

  echo "Customize (Start): NVIDIA OptiX"
  version=$(echo $buildConfig | jq -r .version.nvidia_optix)
  fileType="nvidia-optix"
  fileName="NVIDIA-OptiX-SDK-$version-linux64-x86_64.sh"
  fileLink="$binHostUrl/NVIDIA/OptiX/$version/$fileName"
  download_file $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  chmod +x $fileName
  filePath="$binDirectory/$fileType/$version"
  mkdir -p $filePath
  run_process "./$fileName --skip-license --prefix=$filePath" $binDirectory/$fileType-1
  buildDirectory="$filePath/build"
  mkdir -p $buildDirectory
  dnf -y install libXrandr-devel
  dnf -y install libXcursor-devel
  dnf -y install libXinerama-devel
  dnf -y install mesa-libGL-devel
  dnf -y install mesa-libGL
  run_process "cmake -B $buildDirectory -S $filePath/SDK" $binDirectory/$fileType-2
  run_process "make -C $buildDirectory" $binDirectory/$fileType-3
  binPaths="$binPaths:$buildDirectory/bin"
  echo "Customize (End): NVIDIA OptiX"
fi

if [[ "$gpuProvider" == NVIDIA* ]]; then
  echo "Customize (Start): NVIDIA GPU (CUDA)"
  dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
  dnf -y install cuda
  echo "Customize (End): NVIDIA GPU (CUDA)"
fi

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Core (GPU)"
