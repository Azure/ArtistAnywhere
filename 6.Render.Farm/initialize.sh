#!/bin/bash -x

binDirectory="/usr/local/bin"
cd $binDirectory

source /tmp/functions.sh

if [ ${terminateNotification.enable} == true ]; then
  cronFilePath="$binDirectory/crontab"
  echo "* * * * * /tmp/terminate.sh" > $cronFilePath
  crontab $cronFilePath
fi

SetFileSystems '${jsonencode(fileSystems)}'

source /etc/profile.d/aaa.sh
