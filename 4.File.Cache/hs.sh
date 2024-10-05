#!/bin/bash -ex

ADMIN_PASSWORD=${adminPassword} /usr/bin/hs-init-admin-pw

if [ $(hostname) == ${adminHostName} ]; then

  for storageTarget in $(echo "${storageTargets}" | jq -c '.[]'); do
      enable=$(echo $storageTarget | jq -r .enable)
      if [ $enable == true ]; then
        nodeName=$(echo $storageTarget | jq -r .node.name)
        nodeType=$(echo $storageTarget | jq -r .node.type)
        nodeIP=$(echo $storageTarget | jq -r .node.ip)

        hscli node-add --name $nodeName --type $nodeType --ip $nodeIP

        volumeName=$(echo $storageTarget | jq -r .volume.name)
        volumeType=$(echo $storageTarget | jq -r .volume.type)
        volumeNode=$(echo $storageTarget | jq -r .volume.node)
        volumePath=$(echo $storageTarget | jq -r .volume.path)

        options=""
        assimilate=$(echo $storageTarget | jq -r .assimilate.enable)
        if [ $assimilate == true ]; then
          options="$options --assimilate"
        fi

        hscli volume-add$options --name $volumeName --access-type $volumeType --node-name $volumeNode --logical-volume-name $volumePath
      fi
  done

fi
