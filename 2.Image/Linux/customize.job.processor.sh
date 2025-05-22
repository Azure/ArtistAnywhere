#!/bin/bash -ex

source /tmp/functions.sh

echo "(AAA Start): Job Processor"

if [[ $jobProcessors == *PBRT* ]]; then
  echo "(AAA Start): PBRT"
  appVersion=$(echo $buildConfig | jq -r .appVersion.jobProcessorPBRT)
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
  fileSource=$fileType-$appVersion
  git clone --recursive https://github.com/mmp/$fileSource.git
  cmake -B $filePath -S ./$fileSource
  make -C $filePath
  binPaths="$binPaths:$filePath"
  echo "(AAA End): PBRT"
fi

if [[ $jobProcessors == *Blender* ]]; then
  echo "(AAA Start): Blender"
  appVersion=$(echo $buildConfig | jq -r .appVersion.jobProcessorBlender)
  hostType="linux-x64"
  fileType="blender"
  filePath="/usr/local/$fileType"
  fileName="$fileType-$appVersion-$hostType.tar.xz"
  fileLink="$blobStorageEndpointUrl/Blender/$appVersion/$fileName"
  download_file $fileName $fileLink true
  tar -xJf $fileName
  dnf -y install mesa-dri-drivers
  dnf -y install mesa-libGL
  dnf -y install libXxf86vm
  dnf -y install libXfixes
  dnf -y install libXi
  dnf -y install libSM
  mkdir -p $filePath
  mv $fileType-$appVersion-$hostType/* $filePath
  binPaths="$binPaths:$filePath"
  echo "(AAA End): Blender"
fi

if [ "$binPaths" != "" ]; then
  echo "(AAA Path): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "(AAA End): Job Processor"
