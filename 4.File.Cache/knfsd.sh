#!/bin/bash -ex

setenforce 0
dnf -y install jq nfs-utils cachefilesd

function get_encoded_value {
  echo $1 | base64 -d | jq -r $2
}

function set_file_system {
  local fileSystemConfig="$1"
  for fileSystem in $(echo $fileSystemConfig | jq -r '.[] | @base64'); do
    if [ $(get_encoded_value $fileSystem .enable) == true ]; then
      set_file_system_mount "$(get_encoded_value $fileSystem .mount)"
    fi
  done
  systemctl daemon-reload
  mount -a
}

function set_file_system_mount {
  local fileSystemMount="$1"
  local mountType=$(echo $fileSystemMount | jq -r .type)
  local mountPath=$(echo $fileSystemMount | jq -r .path)
  local mountTarget=$(echo $fileSystemMount | jq -r .target)
  local mountOptions=$(echo $fileSystemMount | jq -r .options)
  if [ $(grep -c $mountPath /etc/fstab) ]; then
    mkdir -p $mountPath
    echo "$mountTarget $mountPath $mountType $mountOptions 0 2" >> /etc/fstab
  fi
  if [ $(grep -c $mountPath /etc/exports) ]; then
    fsid=$(uuidgen -r)
    echo "$mountPath *(ro,fsid=$fsid)" >> /etc/exports
  fi
}

deviceIds=""
diskCount=$(lsblk | grep -c nvme)
for ((i=0; i<$diskCount; i++)); do
  if [ "$deviceIds" != "" ]; then
    deviceIds="$deviceIds "
  fi
  deviceIds="$deviceIds/dev/nvme$${i}n1"
done
cacheDevice=/dev/md/fscache
mdadm --create $cacheDevice --level=0 --raid-devices=$diskCount $deviceIds

mkfs.xfs $cacheDevice

cacheMount=/mnt/fscache
mkdir -p $cacheMount
echo "$cacheDevice $cacheMount xfs defaults 0 2" >> /etc/fstab

sed -i "/^dir/c\dir $cacheMount" /etc/cachefilesd.conf

systemctl --now enable nfs-server
systemctl --now enable cachefilesd

set_file_system '${jsonencode(fileSystem)}'

exportfs -r
