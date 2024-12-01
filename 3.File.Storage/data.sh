#!/bin/bash -ex

dnf -y install nfs-utils

mountPath="/mnt/storage1"
mkdir -p $mountPath
mount ${dataLoadTargets[0]} $mountPath
cd $mountPath

fileType="moana-island"

fileName="$fileType-1.tgz"
fileLink="https://wdas-datasets-disneyanimation-com.s3-us-west-2.amazonaws.com/moanaislandscene/island-basepackage-v1.1.tgz"
curl -o $fileName -L $fileLink
tar -xzf $fileName --overwrite &

fileName="$fileType-2.tgz"
fileLink="https://datasets.disneyanimation.com/moanaislandscene/island-pbrtV4-v2.0.tgz"
curl -o $fileName -L $fileLink
tar -xzf $fileName --overwrite &

mountPath="/mnt/storage2"
mkdir -p $mountPath
mount ${dataLoadTargets[1]} $mountPath

dataPath="$mountPath/4.3"
mkdir -p $dataPath
cd $dataPath

fileName="splash.blend"
fileLink="https://mirrors.iu13.net/blender/demo/splash/blender-4.3-splash.blend"
curl -o $fileName -L $fileLink
