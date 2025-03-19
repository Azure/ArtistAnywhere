#!/bin/bash -ex

dnf -y install mdadm policycoreutils-python-utils cachefilesd

function set_cache_disks {
  diskPaths=$(lsblk -p -o name | grep nvme)
  if [ "$diskPaths" == "" ]; then
    diskPaths=$(lsblk -p -o name,type | grep disk)
    diskPaths=$(echo $${diskPaths//disk})
    diskPaths=$(echo "$diskPaths" | rev | cut -d" " -f1-${dataDiskCount} | rev)
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

function set_cache_mount {
  cachePath=$1
  mountPath=$2
  mountName=$3
  mkdir -p $mountPath
  mountFile=/usr/lib/systemd/system/$mountName
  echo "[Unit]" > $mountFile
  echo "Description=Local Cache Disks Mount" >> $mountFile
  echo "DefaultDependencies=no" >> $mountFile
  echo "" >> $mountFile
  echo "[Mount]" >> $mountFile
  echo "Type=ext4" >> $mountFile
  echo "What=$cachePath" >> $mountFile
  echo "Where=$mountPath" >> $mountFile
  echo "Options=defaults" >> $mountFile
  echo "" >> $mountFile
  echo "[Install]" >> $mountFile
  echo "WantedBy=multi-user.target" >> $mountFile
  systemctl --now enable $mountName
}

function set_storage_mounts {
  storageMounts="$(echo $1 | base64 -d)"
  for storageMount in $(echo "$storageMounts" | jq -r ".[] | @base64"); do
    mountConfig="$(echo "$storageMount" | base64 -d)"
    enabled=$(echo "$mountConfig" | jq -r .enable)
    if [ $enabled == true ]; then
      fsid=$(uuidgen -r)
      mountPath=$(echo "$mountConfig" | jq -r .path)
      echo "$mountPath *(ro,fsid=$fsid)" >> /etc/exports
    fi
  done
}

mountPath="/fscache"
mountName="fscache.mount"
cachePath=$(set_cache_disks)
set_cache_mount $cachePath $mountPath $mountName

sed -i "/^dir/c\dir $mountPath" /etc/cachefilesd.conf
cacheFile=/usr/lib/systemd/system/cachefilesd.service
sed -i "/^Description/a\After=$mountName" $cacheFile
sed -i "/^After/a\Requires=$mountName" $cacheFile
systemctl --now enable nfs-server cachefilesd

semanage fcontext -a -t cachefiles_var_t "$mountPath(/.*)?"
restorecon -R -v $mountPath
systemctl restart cachefilesd

storageMounts=${base64encode(jsonencode(storageMounts))}
set_storage_mounts $storageMounts
