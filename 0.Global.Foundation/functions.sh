function RunProcess {
  retryCount=0
  command="$1"
  logFile=$2
  until [[ $($command 1> $logFile.out 2> $logFile.err) || ($retryCount -eq 3) ]]; do
    ((retryCount++))
    cat $logFile.err
    sleep 3s
  done
}

function GetEncodedValue {
  echo $1 | base64 -d | jq -r $2
}

function SetFileSystems {
  fileSystems="$1"
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
    echo "$mountSource $mountPath $mountType $mountOptions 0 0" >> /etc/fstab
  fi
}

function InitializeClient {
  binDirectory=$1
  enableWeka=$2
  RunProcess "deadlinecommand -ChangeRepository Direct /mnt/deadline" $binDirectory/deadline-repository
  if [ $enableWeka == true ]; then
    curl http://content.artist.studio:14000/dist/v1/install | sh
  fi
}
