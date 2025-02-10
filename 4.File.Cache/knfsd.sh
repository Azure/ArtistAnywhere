#!/bin/bash -ex

dnf -y install jq nfs-utils cachefilesd

function set_cache_disks {
  devicePath=$1
  deviceList=""
  diskCount=$(lsblk | grep -c nvme)
  for ((i=0; i<$diskCount; i++)); do
    if [ "$deviceList" != "" ]; then
      deviceList="$deviceList "
    fi
    deviceList="$deviceList/dev/nvme$${i}n1"
  done
  mdadm --create $devicePath --level=0 --raid-devices=$diskCount $deviceList
  mkfs.xfs $devicePath
}

function get_mount_name {
  mountPath=$1
  mountName=$${mountPath//\//-}
  mountName=$${mountName:1}.mount
  echo $mountName
}

function set_mount_unit {
  storageMount="$1"
  mountDescription="$(echo $storageMount | jq -r .description)"
  mountType=$(echo $storageMount | jq -r .type)
  mountPath=$(echo $storageMount | jq -r .path)
  mountSource=$(echo $storageMount | jq -r .source)
  mountOptions=$(echo $storageMount | jq -r .options)
  mountName=$(get_mount_name $mountPath)
  mountFile=/usr/lib/systemd/system/$mountName
  echo "[Unit]" > $mountFile
  echo "Description=$mountDescription" >> $mountFile
  echo "DefaultDependencies=no" >> $mountFile
  echo "" >> $mountFile
  echo "[Mount]" >> $mountFile
  echo "Type=$mountType" >> $mountFile
  echo "Where=$mountPath" >> $mountFile
  echo "What=$mountSource" >> $mountFile
  echo "Options=$mountOptions" >> $mountFile
  echo "" >> $mountFile
  echo "[Install]" >> $mountFile
  echo "WantedBy=multi-user.target" >> $mountFile
  systemctl enable $mountName
}

function set_mount_units {
  storageMounts="$(echo $1 | base64 -d)"
  for storageMount in $(echo "$storageMounts" | jq -r ".[] | @base64"); do
    mountConfig="$(echo "$storageMount" | base64 -d)"
    enabled=$(echo "$mountConfig" | jq -r .enable)
    if [ $enabled == true ]; then
      set_mount_unit "$mountConfig"
      mountType=$(echo "$mountConfig" | jq -r .type)
      mountPath=$(echo "$mountConfig" | jq -r .path)
      if [ $mountType == xfs ]; then
        mountSource=$(echo "$mountConfig" | jq -r .source)
        set_cache_disks $mountSource
        sed -i "/^dir/c\dir $mountPath" /etc/cachefilesd.conf
        mountName=$(get_mount_name $mountPath)
        cacheFile=/usr/lib/systemd/system/cachefilesd.service
        sed -i "/^Description/a\After=$mountName" $cacheFile
        sed -i "/^After/a\Requires=$mountName" $cacheFile
        systemctl enable cachefilesd nfs-server
      else
        fsid=$(uuidgen -r)
        echo "$mountPath *(ro,no_root_squash,fsid=$fsid)" >> /etc/exports
      fi
    fi
  done
}

storageMounts=${base64encode(jsonencode(storageMounts))}
set_mount_units $storageMounts

sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
reboot
