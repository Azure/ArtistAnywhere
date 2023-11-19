function GetEncodedValue {
  echo $1 | base64 -d | jq -r $2
}

function SetFileSystems {
  fileSystems="$1"
  curl -L https://github.com/Azure/AZNFS-mount/releases/download/1.0.10/aznfs_install.sh | bash
  for fileSystem in $(echo $fileSystems | jq -r '.[] | @base64'); do
    if [ $(GetEncodedValue $fileSystem .enable) == true ]; then
      SetFileSystemMount "$(GetEncodedValue $fileSystem .mount)"
    fi
  done
  systemctl daemon-reload
  mount -a
}

function SetFileSystemMount {
  fileSystemMount="$1"
  mountType=$(echo $fileSystemMount | jq -r .type)
  mountPath=$(echo $fileSystemMount | jq -r .path)
  mountSource=$(echo $fileSystemMount | jq -r .source)
  mountOptions=$(echo $fileSystemMount | jq -r .options)
  if [ $(grep -c $mountPath /etc/fstab) ]; then
    mkdir -p $mountPath
    echo "$mountSource /mnt/$mountPath $mountType $mountOptions 0 0" >> /etc/fstab
  fi
}
