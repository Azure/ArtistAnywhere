#!/bin/bash -x

ADMIN_PASSWORD=${adminPassword} /usr/bin/hs-init-admin-pw

if [ ${storageTargetsEnable} == true ]; then
  hscli login --username admin --password ${adminPassword}

  for storageTarget in $(echo "${storageTargetsNFS}" | jq -c '.[]'); do
      enable=$(echo $storageTarget | jq -r .enable)
      if [ $enable == true ]; then
        name=$(echo $storageTarget | jq -r .name)
        type=$(echo $storageTarget | jq -r .type)
        address=$(echo $storageTarget | jq -r .address)
        options=$(echo $storageTarget | jq -r .options)
        hscli storage add --name $name --type $type --address $address --options $options --protocol NFS
      fi
  done

  for storageTarget in $(echo "${storageTargetsNFSBlob}" | jq -c '.[]'); do
      enable=$(echo $storageTarget | jq -r .enable)
      if [ $enable == true ]; then
        name=$(echo $storageTarget | jq -r .name)
        accountName=$(echo $storageTarget | jq -r .accountName)
        accountKey=$(echo $storageTarget | jq -r .accountKey)
        containerName=$(echo $storageTarget | jq -r .containerName)
        mountPath=$(echo $storageTarget | jq -r .mountPath)
        hscli storage add --name $name --type AzureBlob --account-name $accountName --account-key $accountKey --container-name $containerName --mount-path $mountPath --protocol NFS
      fi
  done

fi
