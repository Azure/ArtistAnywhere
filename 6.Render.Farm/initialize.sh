#!/bin/bash -x

source /tmp/functions.sh

if [ ${terminateNotification.enable} == true ]; then
  cronFilePath="$binDirectory/crontab"
  echo "* * * * * /tmp/terminate.sh" > $cronFilePath
  crontab $cronFilePath
fi

SetFileSystem '${jsonencode(fileSystem)}'

source /etc/profile.d/aaa.sh
