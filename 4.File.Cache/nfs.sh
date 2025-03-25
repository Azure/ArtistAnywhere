#!/bin/bash -ex

dnf -y install mdadm policycoreutils-python-utils cachefilesd

function set_local_cache_disks {
  diskPaths=$(lsblk -p -o name | grep nvme)
  if [ "$diskPaths" == "" ]; then
    diskPaths=$(lsblk -p -o name,type | grep disk)
    diskPaths=$(echo $${diskPaths//disk})
    diskPaths=$(echo "$diskPaths" | rev | cut -d " " -f 1-${dataDiskCount} | rev)
  fi
  diskCount=$(echo "$diskPaths" | wc -w)
  if (( $diskCount > 1 )); then
    cachePath="/dev/md/fscache"
    mdadm --create $cachePath --level=0 --raid-devices=$diskCount $diskPaths > /var/log/aaa-mdadm.log
  else
    cachePath="/dev/nvme0n1p1"
    echo ,,83 | sfdisk /dev/nvme0n1 > /var/log/aaa-sfdisk.log
  fi
  mkfs.ext4 $cachePath > /var/log/aaa-mkfs.log
  echo $cachePath
}

function set_mount_unit {
  mountJSON=$1
  mountName=$(echo "$mountJSON" | jq -r .name)
  if [ "$mountName" == null ]; then
    mountName=$(echo "$mountJSON" | jq -r .path)
    mountName=$${mountName//\//-}
    mountName=$${mountName:1}.mount
  fi
  mountType=$(echo "$mountJSON" | jq -r .type)
  mountPath=$(echo "$mountJSON" | jq -r .path)
  mountSource=$(echo "$mountJSON" | jq -r .source)
  mountOptions=$(echo "$mountJSON" | jq -r .options)
  mountDescription=$(echo "$mountJSON" | jq -r .description)
  mkdir -p $mountPath
  filePath=/usr/lib/systemd/system/$mountName
  echo "[Unit]" > $filePath
  echo "Description=$mountDescription" >> $filePath
  echo "DefaultDependencies=no" >> $filePath
  echo "" >> $filePath
  echo "[Mount]" >> $filePath
  echo "Type=$mountType" >> $filePath
  echo "What=$mountSource" >> $filePath
  echo "Where=$mountPath" >> $filePath
  echo "Options=$mountOptions" >> $filePath
  echo "" >> $filePath
  echo "[Install]" >> $filePath
  echo "WantedBy=multi-user.target" >> $filePath
  systemctl --now enable $mountName
  echo $mountName
}

function set_local_cache_mount {
  mountJSON='{"name":"'$1'","path":"'$2'","source":"'$3'","type":"ext4","options":"defaults","description":"Local Cache Disks Mount"}'
  set_mount_unit "$mountJSON"
}

function set_remote_storage_mounts {
  storageMounts="$(echo $1 | base64 -d)"
  for storageMount in $(echo "$storageMounts" | jq -r ".[] | @base64"); do
    mountJSON="$(echo "$storageMount" | base64 -d)"
    enabled=$(echo "$mountJSON" | jq -r .enable)
    if [ $enabled == true ]; then
      set_mount_unit "$mountJSON"
      mountPath=$(echo "$mountJSON" | jq -r .path)
      mountSource=$(echo "$mountJSON" | jq -r .source)
      mountSource=$(echo $mountSource | cut -d ":" -f 1)
      echo "$mountPath $mountSource(ro,no_root_squash,fsid=$(uuidgen -r))" >> /etc/exports
    fi
  done
  exportfs -r
}

mountName="fscache.mount"
mountPath="/fscache"
cachePath=$(set_local_cache_disks)
set_local_cache_mount $mountName $mountPath $cachePath

sed -i "/^dir/c\dir $mountPath" /etc/cachefilesd.conf
cacheFile=/usr/lib/systemd/system/cachefilesd.service
sed -i "/^Description/a\After=$mountName" $cacheFile
sed -i "/^After/a\Requires=$mountName" $cacheFile
systemctl --now enable nfs-server cachefilesd

semanage fcontext -a -t cachefiles_var_t "$mountPath(/.*)?"
restorecon -R -v $mountPath
systemctl restart cachefilesd

storageMounts=${base64encode(jsonencode(storageMounts))}
set_remote_storage_mounts $storageMounts
