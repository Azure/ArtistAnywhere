aaaPath=""
aaaRoot="/usr/local/aaa"
mkdir -p $aaaRoot
cd $aaaRoot

aaaProfile="/etc/profile.d/aaa.sh"
touch $aaaProfile

if [ "$imageBuildConfigEncoded" != "" ]; then
  echo "(AAA Start): Image Build Config"
  imageBuildConfig=$(echo $imageBuildConfigEncoded | base64 -d)
  blobStorage=$(echo $imageBuildConfig | jq -c .blobStorage)
  blobStorageEndpointUrl=$(echo $blobStorage | jq -r .endpointUrl)
  machineType=$(echo $imageBuildConfig | jq -r .machineType)
  gpuProvider=$(echo $imageBuildConfig | jq -r .gpuProvider)
  jobManagers=$(echo $imageBuildConfig | jq -c .jobManagers)
  jobProcessors=$(echo $imageBuildConfig | jq -c .jobProcessors)
  adminUsername=$(echo $imageBuildConfig | jq -r .authCredential.adminUsername)
  adminPassword=$(echo $imageBuildConfig | jq -r .authCredential.adminPassword)
  serviceUsername=$(echo $imageBuildConfig | jq -r .authCredential.serviceUsername)
  servicePassword=$(echo $imageBuildConfig | jq -r .authCredential.servicePassword)
  echo "(AAA End): Image Build Config"
fi

function download_file {
  local fileName=$1
  local fileLink=$2
  local authRequired=$3
  if [ $authRequired == true ]; then
    local apiVersion=$(echo $blobStorage | jq -r .apiVersion)
    local authTokenUrl=$(echo $blobStorage | jq -r .authTokenUrl)
    accessToken=$(curl -H "Metadata: true" $authTokenUrl | jq -r .access_token)
    curl -H "Authorization: Bearer $accessToken" -H "x-ms-version: $apiVersion" -o $fileName -L $fileLink
  else
    curl -o $fileName -L $fileLink
  fi
}

function run_process {
  local exitStatus=-1
  local retryCount=0
  local command="$1"
  local logFile=$2
  logFile="$aaaRoot/$logFile"
  while [[ $exitStatus -ne 0 && $retryCount -lt 3 ]]; do
    $command 1> $logFile.out 2> $logFile.err
    exitStatus=$?
    ((retryCount++))
    if [ $exitStatus ]; then
      cat $logFile.out
      cat $logFile.err
      sleep 10s
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
