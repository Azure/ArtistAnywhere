#!/bin/bash -ex

source /tmp/functions.sh
source /etc/profile.d/aaa.sh

if [ ${terminateNotification.enable} == true ]; then
  cronFilePath="$binDirectory/crontab"
  echo "* * * * * /tmp/terminate.sh" > $cronFilePath
  crontab $cronFilePath
fi

SetFileSystem '${jsonencode(fileSystem)}' false
