#!/bin/bash -ex

localDirectory="/mnt/storage"
mkdir -p $localDirectory
mount ${dataLoadTarget} $localDirectory
cd $localDirectory

fileType="moana-island"

file1Name="$fileType-1.tgz"
file1Link="https://wdas-datasets-disneyanimation-com.s3-us-west-2.amazonaws.com/moanaislandscene/island-basepackage-v1.1.tgz"

file2Name="$fileType-2.tgz"
file2Link="https://datasets.disneyanimation.com/moanaislandscene/island-pbrtV4-v2.0.tgz"

curl -o $file1Name -L $file1Link
curl -o $file2Name -L $file2Link
tar -xzf $file1Name --overwrite &
tar -xzf $file2Name --overwrite &
