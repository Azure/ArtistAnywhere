#!/bin/bash -x

echo "Customize (Start): Job Processor"

source /tmp/functions.sh

if [[ $jobProcessors == *PBRT* ]]; then
  echo "Customize (Start): PBRT"
  versionPath=$(echo $buildConfig | jq -r .versionPath.jobProcessorPBRT)
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

if [[ $jobProcessors == *Blender* ]]; then
  echo "Customize (Start): Blender"
  versionPath=$(echo $buildConfig | jq -r .versionPath.jobProcessorBlender)
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

echo "Customize (PATH): ${binPaths:1}"
echo 'PATH=$PATH'$binPaths >> $aaaProfile

echo "Customize (End): Job Processor"
