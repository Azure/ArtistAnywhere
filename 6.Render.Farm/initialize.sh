#!/bin/bash -x

binDirectory="/usr/local/bin"
cd $binDirectory

source /etc/profile.d/aaa.sh

source /tmp/functions.sh

if [ ${terminateNotification.enable} == true ]; then
  cronFilePath="$binDirectory/crontab"
  echo "* * * * * /tmp/terminate.sh" > $cronFilePath
  crontab $cronFilePath
fi

SetFileSystems '${jsonencode(fileSystems)}'

InitializeClient ${databaseUsername} ${databasePassword} null false
