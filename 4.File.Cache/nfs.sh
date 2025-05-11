#!/bin/bash -ex

dnf -y install epel-release python3-pip policycoreutils-python-utils cachefilesd mdadm
curl -s https://packagecloud.io/install/repositories/prometheus-rpm/release/script.rpm.sh | /bin/bash
dnf -y install prometheus node_exporter
pip install prometheus_client

metricsConfigFile="/etc/prometheus/prometheus.yml"
sed -i "s/15 seconds/${metricsIntervalSeconds} seconds/g" $metricsConfigFile
sed -i "s/: 15s/: ${metricsIntervalSeconds}s/g" $metricsConfigFile

cat >> $metricsConfigFile <<EOF
  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:${metricsNodeExportsPort}"]
  - job_name: "cache_stats"
    static_configs:
      - targets: ["localhost:${metricsCustomStatsPort}"]

remote_write:
  - url: "${metricsIngestionUrl}"
    azuread:
      cloud: "AzurePublic"
      managed_identity:
        client_id: "${userIdentityClientId}"
EOF

systemctl --now enable prometheus node_exporter

function set_cache_disks {
  nvmeDisks=true
  diskPaths=$(lsblk -p -o name | grep nvme)
  if [ "$diskPaths" == "" ]; then
    nvmeDisks=false
    diskPaths=$(lsblk -p -o name,type | grep disk)
    diskPaths=$(echo $${diskPaths//disk})
    diskPaths=$(echo "$diskPaths" | rev | cut -d " " -f 1-${dataDiskCount} | rev)
  fi
  logPath="/var/log/aaa"
  mkdir -p $logPath
  diskCount=$(echo "$diskPaths" | wc -w)
  if (( $diskCount > 1 )); then
    cachePath="/dev/md/fscache"
    mdadm --create $cachePath --level=0 --raid-devices=$diskCount $diskPaths > $logPath/mdadm.log
  else
    [ $nvmeDisks == true ] && cachePath="/dev/nvme0n1p1" || cachePath=$diskPaths
    sgdisk --new=1:0:0 --typecode=1:8300 $diskPaths > $logPath/sgdisk.log
  fi
  mkfs.ext4 $cachePath > $logPath/mkfs.log
  echo $cachePath
}

function set_systemd_file {
  unitJSON=$1
  forMount=$2
  unitName=$(echo "$unitJSON" | jq -r .name)
  unitPath=$(echo "$unitJSON" | jq -r .path)
  if [ "$unitName" == null ]; then
    unitName=$${unitPath//\//-}
    unitName=$${unitName:1}.mount
  fi
  unitDescription=$(echo "$unitJSON" | jq -r .description)
  filePath=/usr/lib/systemd/system/$unitName
  echo "[Unit]" > $filePath
  echo "Description=$unitDescription" >> $filePath
  if [ $forMount == true ]; then
    echo "DefaultDependencies=no" >> $filePath
  else
    echo "After=syslog.target network-online.target" >> $filePath
    echo "Wants=network.target" >> $filePath
  fi
  echo "" >> $filePath
  if [ $forMount == true ]; then
    mountType=$(echo "$unitJSON" | jq -r .type)
    mountSource=$(echo "$unitJSON" | jq -r .source)
    mountOptions=$(echo "$unitJSON" | jq -r .options)
    mkdir -p $mountPath
    echo "[Mount]" >> $filePath
    echo "Type=$mountType" >> $filePath
    echo "What=$mountSource" >> $filePath
    echo "Where=$unitPath" >> $filePath
    echo "Options=$mountOptions" >> $filePath
  else
    echo "[Service]" >> $filePath
    echo "Type=simple" >> $filePath
    echo "ExecStart=$unitPath" >> $filePath
    echo "Restart=on-failure" >> $filePath
    echo "RestartSec=10" >> $filePath
  fi
  echo "" >> $filePath
  echo "[Install]" >> $filePath
  echo "WantedBy=multi-user.target" >> $filePath
  systemctl --now enable $unitName
  permissionsEnable=$(echo "$unitJSON" | jq -r .permissions.enable)
  if [[ $forMount == true && $permissionsEnable == true ]]; then
    permissionsResursive=$(echo "$unitJSON" | jq -r .permissions.recursive)
    permissionsOctalValue=$(echo "$unitJSON" | jq -r .permissions.octalValue)
    if [ $permissionsResursive == true ]; then
      chmod -R $permissionsOctalValue $unitPath
    else
      chmod $permissionsOctalValue $unitPath
    fi
  fi
  echo $unitName
}

function set_storage_mounts {
  storageMounts="$(echo $1 | base64 -d)"
  for storageMount in $(echo "$storageMounts" | jq -r ".[] | @base64"); do
    unitJSON="$(echo "$storageMount" | base64 -d)"
    enable=$(echo "$unitJSON" | jq -r .enable)
    if [ $enable == true ]; then
      set_systemd_file "$unitJSON" true
      mountPath=$(echo "$unitJSON" | jq -r .path)
      echo "$mountPath ${exportAddressSpace}(rw,sync,no_root_squash,fsid=$(uuidgen -r))" >> /etc/exports
    fi
  done
  exportfs -a
}

dataFilePath="/var/lib/waagent/ovf-env.xml"
codeFilePath="/usr/local/bin/nfs.py"
dataFileText=$(xmllint --xpath "//*[local-name()='Environment']/*[local-name()='ProvisioningSection']/*[local-name()='LinuxProvisioningConfigurationSet']/*[local-name()='CustomData']/text()" $dataFilePath)
echo $dataFileText | base64 -d > $codeFilePath

unitName="cache_stats.service"
unitPath="/usr/bin/python3 $codeFilePath"
unitJSON='{"name":"'$unitName'","path":"'$unitPath'","description":"Local Prometheus Metrics Collection"}'
set_systemd_file "$unitJSON" false

mountName="fscache.mount"
mountPath="/fscache"
cachePath=$(set_cache_disks)
unitJSON='{"name":"'$mountName'","path":"'$mountPath'","source":"'$cachePath'","type":"ext4","options":"defaults","permissions":{"recursive":true,"octalValue":777},"description":"Local Cache Disks Mount"}'
set_systemd_file "$unitJSON" true

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
