#!/bin/bash -ex

source /tmp/functions.sh

serviceFile="aaaAutoScaler"
serviceName="AAA Auto Scaler"

dataFilePath="/var/lib/waagent/ovf-env.xml"
dataFileText=$(xmllint --xpath "//*[local-name()='Environment']/*[local-name()='ProvisioningSection']/*[local-name()='LinuxProvisioningConfigurationSet']/*[local-name()='CustomData']/text()" $dataFilePath)
codeFilePath="$binDirectory/$serviceFile.sh"
echo $dataFileText | base64 -d > $codeFilePath
chmod +x $codeFilePath

servicePath="/etc/systemd/system/$serviceFile.service"
echo "[Unit]" > $servicePath
echo "Description=$serviceName Service" >> $servicePath
echo "After=network-online.target" >> $servicePath
echo "" >> $servicePath
echo "[Service]" >> $servicePath
echo "Environment=PATH=$PATH" >> $servicePath
echo "Environment=resourceGroupName=${autoScale.resourceGroupName}" >> $servicePath
echo "Environment=computeJobManager=${autoScale.computeJobManager}" >> $servicePath
echo "Environment=computeClusterName=${autoScale.computeClusterName}" >> $servicePath
echo "Environment=computeClusterNodeLimit=${autoScale.computeClusterNodeLimit}" >> $servicePath
echo "Environment=workerIdleDeleteSeconds=${autoScale.workerIdleDeleteSeconds}" >> $servicePath
echo "Environment=jobWaitThresholdSeconds=${autoScale.jobWaitThresholdSeconds}" >> $servicePath
echo "ExecStart=/bin/bash $codeFilePath" >> $servicePath
echo "" >> $servicePath
echo "[Install]" >> $servicePath
echo "WantedBy=multi-user.target" >> $servicePath

servicePath="/etc/systemd/system/$serviceFile.timer"
echo "[Unit]" > $servicePath
echo "Description=$serviceName Timer" >> $servicePath
echo "" >> $servicePath
echo "[Timer]" >> $servicePath
echo "OnUnitActiveSec=${autoScale.detectionIntervalSeconds}" >> $servicePath
echo "AccuracySec=1us" >> $servicePath
echo "" >> $servicePath
echo "[Install]" >> $servicePath
echo "WantedBy=timers.target" >> $servicePath

systemctl daemon-reload
if [ ${autoScale.enable} == true ]; then
  systemctl --now enable $serviceFile.timer
  systemctl --now enable $serviceFile.service
fi

source /etc/profile.d/aaa.sh
