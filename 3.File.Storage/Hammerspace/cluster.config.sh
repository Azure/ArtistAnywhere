#!/bin/bash -ex

storageAccounts='${jsonencode(storageAccounts)}'
while read storageAccount; do
  enable=$(echo $storageAccount | jq -r .enable)
  if [ $enable == true ]; then
    name="$(echo $storageAccount | jq -r .name)"
    accessKey="$(echo $storageAccount | jq -r .accessKey)"
    hscli object-storage-add --name "$name" --type AZURE --access-id "$name" --secret "$accessKey"
  fi
done < <(echo $storageAccounts | jq -c .[])

shares='${jsonencode(shares)}'
while read share; do
  enable=$(echo $share | jq -r .enable)
  if [ $enable == true ]; then
    name="$(echo $share | jq -r .name)"
    path="$(echo $share | jq -r .path)"
    size="$(echo $share | jq -r .size)"
    export="$(echo $share | jq -r .export)"
    hscli share-create --name "$name" --path "$path" --size "$size" --export-option "$export"
  fi
done < <(echo $shares | jq -c .[])

volumes='${jsonencode(volumes)}'
while read volume; do
  enable=$(echo $volume | jq -r .enable)
  if [ $enable == true ]; then
    nodeName="$(echo $volume | jq -r .node.name)"

    if ! hscli node-list | grep Name: | grep -q "$nodeName"; then
      nodeType="$(echo $volume | jq -r .node.type)"
      nodeAddress="$(echo $volume | jq -r .node.address)"
      hscli node-add --name "$nodeName" --type "$nodeType" --ip "$nodeAddress"
    fi

    volumeName="$(echo $volume | jq -r .name)"
    volumeType="$(echo $volume | jq -r .type)"
    volumePath="$(echo $volume | jq -r .path)"
    deleteData="$(echo $volume | jq -r .purge)"
    [ $deleteData == true ] && addForce="--force" || addForce=""
    hscli volume-add --name "$volumeName" --access-type "$volumeType" --logical-volume-name "$volumePath" --node-name "$nodeName" $addForce

    enable=$(echo $volume | jq -r .assimilation.enable)
    if [ $enable == true ]; then
      shareName="$(echo $volume | jq -r .assimilation.share.name)"
      sharePathSource="$(echo $volume | jq -r .assimilation.share.path.source)"
      sharePathDestination="$(echo $volume | jq -r .assimilation.share.path.destination)"
      hscli volume-assimilation --name "$volumeName" --share-name "$shareName" --source-path "$sharePathSource" --destination-path "$sharePathDestination" --async --log
    fi
  fi
done < <(echo $volumes | jq -c .[])

volumeGroups='${jsonencode(volumeGroups)}'
while read volumeGroup; do
  enable=$(echo $volumeGroup | jq -r .enable)
  if [ $enable == true ]; then
    name="$(echo $volumeGroup | jq -r .name)"
    expressions=""
    while read volumeName; do
      if [ "$expressions" == "" ]; then
        expressions="volume:$volumeName"
      else
        expressions="$expressions,volume:$volumeName"
      fi
    done < <(echo $volumeGroup | jq -cr .volumeNames[])
    hscli volume-group-create --name "$name" --expressions "$expressions"
  fi
done < <(echo $volumeGroups | jq -c .[])
