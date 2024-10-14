#!/bin/bash -ex

# az login --identity

# blobs='${jsonencode(dataLoadSource.blobs)}'
# while read blob; do
#   enable=$(echo $blob | jq -r .enable)
#   if [ $enable == true ]; then
#     name="$(echo $blob | jq -r .name)"
#     az storage copy --source-account-name ${dataLoadSource.accountName} --source-container ${dataLoadSource.containerName} --source-blob $name --destination ${dataLoadDestination} --recursive
#   fi
# done < <(echo $blobs | jq -c .[])

localDirectory="/mnt/storage"
mkdir -p $localDirectory
mount ${dataLoadDestination} $localDirectory

fileType="moana-island"

fileName="$fileType-1.tgz"
fileLink="https://wdas-datasets-disneyanimation-com.s3-us-west-2.amazonaws.com/moanaislandscene/island-basepackage-v1.1.tgz"
curl -o $fileName -L $fileLink
tar -xzf $fileName -C $localDirectory --overwrite

fileName="$fileType-2.tgz"
fileLink="https://datasets.disneyanimation.com/moanaislandscene/island-pbrtV4-v2.0.tgz"
curl -o $fileName -L $fileLink
tar -xzf $fileName -C $localDirectory --overwrite
