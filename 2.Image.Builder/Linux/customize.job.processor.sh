#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Job Processor"

if [[ $jobProcessors == *PBRT* ]]; then
  echo "Customize (Start): PBRT"
  version=$(echo $buildConfig | jq -r .version.job_processor_pbrt)
  fileType="pbrt"
  filePath="/usr/local/$fileType"
  mkdir -p $filePath
  dnf -y install mesa-libGL-devel
  dnf -y install libxkbcommon-devel
  dnf -y install libXrandr-devel
  dnf -y install libXinerama-devel
  dnf -y install libXcursor-devel
  dnf -y install libXi-devel
  dnf -y install wayland-devel
  fileSource=$fileType-$version
  git clone --recursive https://github.com/mmp/$fileSource.git
  cmake -B $filePath -S ./$fileSource
  make -C $filePath
  binPaths="$binPaths:$filePath"
  echo "Customize (End): PBRT"
fi

if [[ $jobProcessors == *Blender* ]]; then
  echo "Customize (Start): Blender"
  version=$(echo $buildConfig | jq -r .version.job_processor_blender)
  hostType="linux-x64"
  fileType="blender"
  filePath="/usr/local/$fileType"
  fileName="$fileType-$version-$hostType.tar.xz"
  fileLink="${blobStorage.endpointUrl}/Blender/$version/$fileName"
  download_file $fileName $fileLink
  tar -xJf $fileName
  dnf -y install mesa-dri-drivers
  dnf -y install mesa-libGL
  dnf -y install libXxf86vm
  dnf -y install libXfixes
  dnf -y install libXi
  dnf -y install libSM
  mkdir -p $filePath
  mv $fileType-$version-$hostType/* $filePath
  binPaths="$binPaths:$filePath"
  echo "Customize (End): Blender"
fi

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Job Processor"
