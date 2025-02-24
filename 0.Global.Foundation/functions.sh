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

function download_file {
  local fileName=$1
  local fileLink=$2
  local tenantId=$3
  local clientId=$4
  local clientSecret=$5
  local storageVersion=$6
  if [ "$tenantId" == "" ]; then
    curl -o $fileName -L $fileLink
  else
    local authToken=$(curl -d "resource=https://storage.azure.com" -d "grant_type=client_credentials" -d "client_id=$clientId" -d "client_secret=$clientSecret" https://login.microsoftonline.com/$tenantId/oauth2/token)
    local accessToken=$(echo $authToken | jq -r .access_token)
    curl -H "Authorization: Bearer $accessToken" -H "x-ms-version: $storageVersion" -o $fileName -L $fileLink
  fi
}

function run_process {
  local exitStatus=-1
  local retryCount=0
  local command="$1"
  local logFile=$2
  while [[ $exitStatus -ne 0 && $retryCount -lt 3 ]]; do
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
}
