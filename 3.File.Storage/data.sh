#!/bin/bash -ex

dnf -y install nfs-utils unzip

if [ ${managedLustre.enable} == true ]; then
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
fi

mountPath=${dataLoadMount.path}
mkdir -p $mountPath
mount -t ${dataLoadMount.type} -o ${dataLoadMount.options} ${dataLoadMount.target} $mountPath

dataPath="$mountPath/cpu"
mkdir -p $dataPath
cd $dataPath

dataType="moana-island"

fileName="$dataType-1.tgz"
fileLink="https://wdas-datasets-disneyanimation-com.s3-us-west-2.amazonaws.com/moanaislandscene/island-basepackage-v1.1.tgz"
curl -o $fileName -L $fileLink
tar -xzf $fileName --overwrite &

fileName="$dataType-2.tgz"
fileLink="https://datasets.disneyanimation.com/moanaislandscene/island-pbrtV4-v2.0.tgz"
curl -o $fileName -L $fileLink
tar -xzf $fileName --overwrite &

fileName="splash.blend"
mountPath="$mountPath/gpu"

dataType="4.1"

dataPath="$mountPath/$dataType"
mkdir -p $dataPath
cd $dataPath

fileLink="https://mirrors.iu13.net/blender/demo/splash/blender-$dataType-splash.blend"
curl -o $fileName -L $fileLink

dataType="4.2"

dataPath="$mountPath/$dataType"
mkdir -p $dataPath
cd $dataPath

dataFile="splash.zip"
fileLink="https://mirrors.iu13.net/blender/demo/splash/blender-$dataType-splash.zip"
curl -o $dataFile -L $fileLink
unzip -o $dataFile

dataType="4.3"

dataPath="$mountPath/$dataType"
mkdir -p $dataPath
cd $dataPath

fileLink="https://mirrors.iu13.net/blender/demo/splash/blender-$dataType-splash.blend"
curl -o $fileName -L $fileLink
