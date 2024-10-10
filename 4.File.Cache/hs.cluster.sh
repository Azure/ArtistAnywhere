#!/bin/bash -x

while true; do
  hscli cluster-view
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 60s
done

shares='${jsonencode(shares)}'
while read share; do
  enable=$(echo $share | jq -r .enable)
  if [ $enable == true ]; then
    name="$(echo $share | jq -r .name)"
    path="$(echo $share | jq -r .path)"
    size="$(echo $share | jq -r .size)"
    export="$(echo $share | jq -r .export)"
    description="$(echo $share | jq -r .description)"
    hscli share-create --name "$name" --path "$path" --size "$size" --export-option "$export" --description "$description"
  fi
done < <(echo $shares | jq -c .[])

storageTargets='${jsonencode(storageTargets)}'
while read storageTarget; do
  enable=$(echo $storageTarget | jq -r .enable)
  if [ $enable == true ]; then
    nodeName="$(echo $storageTarget | jq -r .node.name)"
    nodeType="$(echo $storageTarget | jq -r .node.type)"
    nodeIP="$(echo $storageTarget | jq -r .node.ip)"
    hscli node-add --name "$nodeName" --type "$nodeType" --ip "$nodeIP"

    volumeName="$(echo $storageTarget | jq -r .volume.name)"
    volumeType="$(echo $storageTarget | jq -r .volume.type)"
    volumePath="$(echo $storageTarget | jq -r .volume.path)"
    shareName="$(echo $storageTarget | jq -r .volume.shareName)"
    hscli volume-add --name "$volumeName" --access-type "$volumeType" --logical-volume-name "$volumePath" --node-name "$nodeName" --share-name "$shareName" --assimilation
  fi
done < <(echo $storageTargets | jq -c .[])

volumeGroups='${jsonencode(volumeGroups)}'
while read volumeGroup; do
  enable=$(echo $volumeGroup | jq -r .enable)
  if [ $enable == true ]; then
    name="$(echo $volumeGroup | jq -r .name)"
    description="$(echo $volumeGroup | jq -r .description)"
    expressions=""
    while read volumeName; do
      if [ "$expressions" == "" ]; then
        expressions="volume:$volumeName"
      else
        expressions="$expressions,volume:$volumeName"
      fi
    done < <(echo $volumeGroup | jq -cr .volumeNames[])
    hscli volume-group-create --name "$name" --description "$description" --expressions "$expressions"
  fi
done < <(echo $volumeGroups | jq -c .[])
