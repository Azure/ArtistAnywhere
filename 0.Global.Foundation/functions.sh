binPaths=""
binDirectory="/usr/local/bin"
cd $binDirectory

if [ "$buildConfigEncoded" != "" ]; then
  aaaProfile="/etc/profile.d/aaa.sh"
  touch $aaaProfile

  echo "Customize (Start): Image Build Parameters"
  dnf -y install jq
  buildConfig=$(echo $buildConfigEncoded | base64 -d)
  machineType=$(echo $buildConfig | jq -r .machineType)
  gpuProvider=$(echo $buildConfig | jq -r .gpuProvider)
  binHostUrl=$(echo $buildConfig | jq -r .binHostUrl)
  jobProcessors=$(echo $buildConfig | jq -c .jobProcessors)
  tenantId=$(echo $buildConfig | jq -r .authClient.tenantId)
  clientId=$(echo $buildConfig | jq -r .authClient.clientId)
  clientSecret=$(echo $buildConfig | jq -r .authClient.clientSecret)
  storageVersion=$(echo $buildConfig | jq -r .authClient.storageVersion)
  adminUsername=$(echo $buildConfig | jq -r .authCredential.adminUsername)
  adminPassword=$(echo $buildConfig | jq -r .authCredential.adminPassword)
  serviceUsername=$(echo $buildConfig | jq -r .authCredential.serviceUsername)
  servicePassword=$(echo $buildConfig | jq -r .authCredential.servicePassword)
  echo "Customize (End): Image Build Parameters"
fi

function DownloadFile {
  fileName=$1
  fileLink=$2
  tenantId=$3
  clientId=$4
  clientSecret=$5
  storageVersion=$6
  if [ "$tenantId" == "" ]; then
    curl -o $fileName -L $fileLink
  else
    authToken=$(curl -d "resource=https://storage.azure.com" -d "grant_type=client_credentials" -d "client_id=$clientId" -d "client_secret=$clientSecret" https://login.microsoftonline.com/$tenantId/oauth2/token)
    accessToken=$(echo $authToken | jq -r .access_token)
    curl -H "Authorization: Bearer $accessToken" -H "x-ms-version: $storageVersion" -o $fileName -L $fileLink
  fi
}

function RunProcess {
  exitStatus=-1
  retryCount=0
  command="$1"
  logFile=$2
  while [[ $exitStatus && $retryCount -lt 3 ]]; do
    $command 1> $logFile.out 2> $logFile.err
    exitStatus=$?
    ((retryCount++))
    if [ $exitStatus ]; then
      cat $logFile.out
      cat $logFile.err
      sleep 5s
    fi
  done
}

function GetEncodedValue {
  echo $1 | base64 -d | jq -r $2
}

function SetFileSystem {
  fileSystemConfig="$1"
  firstMountOnly=$2
  continueMounts=true
  for fileSystem in $(echo $fileSystemConfig | jq -r '.[] | @base64'); do
    if [[ $(GetEncodedValue $fileSystem .enable) == true && $continueMounts == true ]]; then
      SetFileSystemMount "$(GetEncodedValue $fileSystem .mount)"
      if [ $firstMountOnly == true ]; then
        continueMounts=false
        break
      fi
    fi
  done
  sudo systemctl daemon-reload
  sudo mount -a
}

function SetFileSystemMount {
  fileSystemMount="$1"
  mountType=$(echo $fileSystemMount | jq -r .type)
  mountPath=$(echo $fileSystemMount | jq -r .path)
  mountSource=$(echo $fileSystemMount | jq -r .source)
  mountOptions=$(echo $fileSystemMount | jq -r .options)
  if [ $(grep -c $mountPath /etc/fstab) ]; then
    sudo mkdir -p $mountPath
    echo "$mountSource $mountPath $mountType $mountOptions 0 0" | sudo tee -a /etc/fstab
  fi
}
