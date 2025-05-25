#!/bin/bash -ex

source /tmp/functions.sh

if [ ${terminateNotification.enable} == true ]; then
  cronFilePath="$aaaRoot/crontab"
  echo "* * * * * /tmp/terminate.sh" > $cronFilePath
  crontab $cronFilePath
fi

set_file_system '${jsonencode(fileSystem)}'

source /etc/profile.d/aaa.sh
